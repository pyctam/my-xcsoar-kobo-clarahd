XCSoar runs on Kobo Clara HD, but it is not among [officially supported](https://www.xcsoar.org/hardware/#kobo) 
Kobo eReaders, so this repo contains some "hacks" which I use to make my life easier.  


# USBnetwork
Wifi is not working in XCSoar mode, so in order to establish connection with the device
I use [usbnet-toggle.sh](kobo-clarahd/usbnet-toggle.sh) inside of [init.sh](kobo-clarahd/init.sh).
When XCSoar starts on the Kobo, it checks for a script called XCSoarData/kobo/init.sh and executes it.
Digging [mobileread.com](https://www.mobileread.com/forums/showthread.php?p=3728532) on how 
to enable USB networking on Clara HD with running XCSoar brought me to 
http://trac.ak-team.com/trac/browser/niluje/Configs/trunk/Kindle/Kobo_Hacks/KoboStuff/src/usr/local/stuff/bin/usbnet-toggle.sh,
so all credits go to the contributor[s]/author[s] from NiLuJe.

In mean time, after I added [usbnet-toggle.sh](kobo-clarahd/usbnet-toggle.sh), I'm able to use `telnet` and `ftp`
to connect or transer files to Kobo. But more important, on the Clara HD I don't have blank screen any more when
Kobo is booted.


# BlueFlyVario
I use BlueFlyVario_TTL_GPS_v12_r1 which I bought in 2018 and initial version
[required firmware update](http://blueflyvario.blogspot.com/2018/12/blueflyvariottlgpsv12-firmware-update.html).
I didn't want to disassemble my setup and I wanted to give a try for a methid offered on 
[blueflyvario-hex2sh](https://github.com/twhitehead/blueflyvario-hex2sh) and mentioned on the firmware update page. 
Initial build didn't work for me because baud rate in [hex2sh.hs](https://github.com/twhitehead/blueflyvario-hex2sh/blob/master/hex2sh.hs#L322)
was setup as 57600 while my BlueFlyVario_TTL_GPS_v12_r1 uses 115200. Fixing baud rate, allowed me to
update firmvare on my BlueFlyVario_TTL_GPS_v12. It took some time to get Haskell running on my machine,
so if you want to save some time you can use [update-BlueFlyVario_TTL_GPS_12.225.sh](blueflyvario/update-BlueFlyVario_TTL_GPS_12.225.sh).

Here is how firmware update output should look in terminal:

```
/mnt/onboard/XCSoarData/kobo # ./update-BlueFlyVario_TTL_GPS_12.225.sh 
Establishing communication with ds30loader...
Reattempting communication establishment (attempt 2 of 60)...
Reattempting communication establishment (attempt 3 of 60)...

PIC Device = 37
ds30loader = 4.0.3

Programming row 0x000000...
Programming row 0x000040...
Programming row 0x000080...
....lot of similar rows....
Programming row 0x004540...
Programming row 0x004580...
Programming row 0x0045c0...
Programming row 0xf80000...
Row verification failure reported by ds30loader...
```

Row verification error can be ignored according the instructions created by
[blueflyvario-hex2sh](https://github.com/twhitehead/blueflyvario-hex2sh)

I followed [firmware update for v11 models](http://blueflyvario.blogspot.com/2016/08/firmware-update-for-v11-models.html)
instructions to enter into the bootloader mode.

