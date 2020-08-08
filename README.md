XCSoar runs on Kobo Clara HD, but it is not among [officially supported](https://www.xcsoar.org/hardware/#kobo) 
Kobo eReaders, so this repo contains some "hacks" which I use to make my life easier.  

# USBnetwork
Wifi is not working in XCSoar mode, so in order to establish connection with the device
I use [usbnet-toggle.sh](kobo-clarahd/usbnet-toggle.sh) with disabled DHCP. Digging
mobileread.com on how to enable USB networking on Clara HD with running XCSoar brought
me to http://trac.ak-team.com/trac/browser/niluje/Configs/trunk/Kindle/Kobo_Hacks/KoboStuff/src/usr/local/stuff/bin/usbnet-toggle.sh,
so all credits go to contributor[s] from NiLuJe.

