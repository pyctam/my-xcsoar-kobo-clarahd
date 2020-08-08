#!/bin/sh -e
#
# Quick'n dirty USBnetwork toggle
#
# $Id$
#
##

##
# Siphon a key variable from udev's env in case it's not already in our env...
if [ -z "${PLATFORM}" ] ; then
	# shellcheck disable=SC2046
	export $(grep -s -e '^PLATFORM=' "/proc/$(pidof -s udevd)/environ")
fi
# And if that's still not enough, compute it ourselves...
if [ -z "${PLATFORM}" ] ; then
	PLATFORM="freescale"
	if dd if="/dev/mmcblk0" bs=512 skip=1024 count=1 2>/dev/null | grep -q "HW CONFIG" ; then
		CPU="$(ntx_hwconfig -s -p /dev/mmcblk0 CPU 2>/dev/null)"
		PLATFORM="${CPU}-ntx"
	fi

	if [ "${PLATFORM}" != "freescale" ] && [ ! -e "/etc/u-boot/${PLATFORM}/u-boot.mmc" ] ; then
		PLATFORM="ntx508"
	fi
	export PLATFORM
fi

##
# Build a fancy NIC based on the device code & S/N
build_nic() {
	devNIC=""

	# Start with the device code
	eval "$(fbink -e | tr ';' '\n' | grep -e deviceId | tr '\n' ';')"
	# Zero pad it to 4 digits
	deviceId="$(printf "%04d" "${deviceId}")"

	# We'll use that...
	devHash="${deviceId}"

	# Then append the end of the S/N
	# NOTE: See also cut -f1 -d',' /mnt/onboard/.kobo/version
	deviceSN="$(dd if=/dev/mmcblk0 skip=$((0x00000200)) count=64 bs=1 2>/dev/null)"
	# We want six characters in total, so slice however many we need...
	if [ ${#deviceId} -lt 6 ] ; then
		# S/N format is SN-<S/N>_<MFG DATE>
		# NOTE: The third section (MFGD) is optional (seen on a Mk.5, but not on a Mk.7).
		snSlice="$(echo "${deviceSN}" | tr -d '\0' | cut -f1 -d'_' | cut -f2 -d'-' | tr -d '\n' | tail -c$((6 - ${#deviceId})))"
		# Use that as a string, converted to hex juuuuust to be sure.
		snSlice="$(printf "%X" "'${snSlice}'")"

		# And we'll use that...
		devHash="${devHash}${snSlice}"
	fi


	# Finally, loop over it to split it into six bytes
	i=0
	while [ ${i} -lt 6 ] ; do
		devNIC="${devNIC}${devHash:${i}:1}"

		i=$(( i + 1))

		# Add the colon every two bytes
		if [ $(( i & 1 )) -eq 0 ] ; then
			# Except the last
			if [ ${i} -lt 6 ] ; then
				devNIC="${devNIC}:"
			fi
		fi
	done

	echo "${devNIC}"
}

##
# Small wrapper around rmmod...
rmmod() {
	# Sleep a bit first, because everything is terrible
	usleep 250000
	# And then unload the requested module...
	/sbin/rmmod "${@}"
}

# Small wrapper around insmod...
insmod() {
	# Load the requested module...
	/sbin/insmod "${@}"
	# And then sleep a bit, because everything is terrible
	usleep 250000
}

# Net -> MS
usbnet_to_usbms() {
	echo "* Switching from USBNet to USBMS . . ."
	fbink -q -y -12 -p -m "Switching from USBNet to USBMS . . ."

	ifconfig usb0 down

	if [ "${PLATFORM}" = "mx6sll-ntx" ] || [ "${PLATFORM}" = "mx6ull-ntx" ] ; then
		rmmod g_ether

		# NOTE: c.f., https://www.mobileread.com/forums/showpost.php?p=3707011&postcount=348 for the full depgraph
		rmmod usb_f_rndis
		rmmod usb_f_ecm_subset
		rmmod usb_f_eem
		rmmod usb_f_ecm
		rmmod u_ether
		rmmod libcomposite
		rmmod configfs
	else
		rmmod g_ether

		# NOTE: arcotg_udc is builtin on Mk. 6, but old FW may have been shipping a broken module!
		if [ "${PLATFORM}" != "mx6sl-ntx" ] ; then
			rmmod arcotg_udc
		fi
	fi

	echo "* USBNet -> USBMS: Done :)"
	fbink -q -y -11 -p -m "USBNet -> USBMS: Done :)"
}

# MS -> Net
usbms_to_usbnet() {
	echo "* Switching from USBMS to USBNet . . ."
	fbink -q -y -12 -p -m "Switching from USBMS to USBNet . . ."

	## NOTE: will probably fail on non iMX devices (FW doesn't ship with those modules)
	modules_path="/drivers/${PLATFORM}/usb/gadget"

	# Instead of 00:00:00, we'll use a fancier NIC, to make it easier to connect multiple devices to the same computer...
	myNIC="$(build_nic)"
	# Sanity check...
	if [ "${myNIC}" != "$(echo "${myNIC}" | sed -nre '/^[[:xdigit:]]{2}:[[:xdigit:]]{2}:[[:xdigit:]]{2}$/p')" ] ; then
		myNIC="00:00:00"
	fi

	if [ "${PLATFORM}" = "mx6sll-ntx" ] || [ "${PLATFORM}" = "mx6ull-ntx" ] ; then
		insmod "${modules_path}/configfs.ko"
		insmod "${modules_path}/libcomposite.ko"
		insmod "${modules_path}/u_ether.ko"
		insmod "${modules_path}/usb_f_ecm.ko"
		insmod "${modules_path}/usb_f_eem.ko"
		insmod "${modules_path}/usb_f_ecm_subset.ko"
		insmod "${modules_path}/usb_f_rndis.ko"

		## NOTE: vlasovsoft & KSM use 46:0d:9e:67:69:eb & 46:0d:9e:67:69:ec
		## NOTE: We make sure to explicitly disable EEM mode because it doesn't support RNDIS,
		##       which might be problematic for non-Linux clients ;).
		insmod "${modules_path}/g_ether.ko" use_eem=0 host_addr="ee:49:00:${myNIC}" dev_addr="ee:19:00:${myNIC}"
	else
		## NOTE: arcotg_udc is builtin on Mk. 6, but old FW may have been shipping a broken module!
		if [ "${PLATFORM}" != "mx6sl-ntx" ] ; then
			insmod "${modules_path}/arcotg_udc.ko"
		fi

		## NOTE: vlasovsoft & KSM use 46:0d:9e:67:69:eb & 46:0d:9e:67:69:ec
		insmod "${modules_path}/g_ether.ko" host_addr="ee:49:00:${myNIC}" dev_addr="ee:19:00:${myNIC}"
	fi

	## NOTE: vlasovsoft & KSM use 192.168.2.101
	ifconfig usb0 192.168.2.2

	# On recent FW versions using dhcpcd in master mode, tell it to stop bothering about usb0 to avoid spamming the syslog...
	# NOTE: This is only a temporary relief, since dhcpcd can be restarted on demand by Nickel...
	#if pkill -0 dhcpcd-dbus ; then
	#	dhcpcd -k usb0
	#fi

	echo "* USBMS -> USBNet: Done :)"
	fbink -q -y -11 -p -m "USBMS -> USBNet: Done :)"
}

##
# And toggle :)
if lsmod | grep -q g_ether ; then
	usbnet_to_usbms
else
	usbms_to_usbnet
fi

