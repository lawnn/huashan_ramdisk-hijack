#!/temp/sh

set +x
_PATH="$PATH"
export PATH="/temp:/system/xbin:/system/bin:/sbin"

LED_RED="/sys/class/leds/pwr-red/brightness"
LED_BLUE="/sys/class/leds/pwr-blue/brightness"
LED_GREEN="/sys/class/leds/pwr-green/brightness"


boot_recovery (){
    mount -o remount,rw /
    cd /
    export TZ="$(getprop persist.sys.timezone)"
    /system/bin/time_daemon
    sleep 5
    kill -9 $(ps | grep time_daemon | grep -v grep | awk -F' ' '{print $1}')

	for SVCRUNNING in $(getprop | grep -E '^\[init\.svc\..*\]: \[running\]' | grep -v ueventd)
	do
		SVCNAME=$(expr ${SVCRUNNING} : '\[init\.svc\.\(.*\)\]:.*')
		stop ${SVCNAME}
	done

	for RUNNINGPRC in $(ps | grep /system/bin | grep -v grep | grep -v chargemon | awk '{print $1}' ) 
	do
		kill -9 $RUNNINGPRC
	done

	for RUNNINGPRC in $(ps | grep /sbin/ | grep -v grep | awk '{print $1}' )
	do
		kill -9 $RUNNINGPRC
	done

    rm -r /sbin
    rm sdcard etc init* uevent* default*

    echo on init > /tz.conf
    echo export TZ "$(getprop persist.sys.timezone)" >> /tz.conf
    chmod 750 /tz.conf
    tar cf /zoneinfo.tar /system/usr/share/zoneinfo
}
boot_rom () {
	mount -o remount,rw rootfs /
	cd /

	# Stop services
	ps a > /temp/log/pre_ps.txt

	for SVCNAME in $(getprop | grep -E '^\[init\.svc\..*\]: \[running\]' | sed 's/\[init\.svc\.\(.*\)\]:.*/\1/g;')
	do
		stop $SVCNAME
	done

	for RUNNINGPRC in $(ps | grep /system/bin | grep -v grep | grep -v chargemon | awk '{print $1}' ) 
	do
		kill -9 $RUNNINGPRC
	done

	for RUNNINGPRC in $(ps | grep /sbin | grep -v grep | awk '{print $1}' )
	do
		kill -9 $RUNNINGPRC
	done

	sync

	kill -9 $(ps | grep suntrold | grep -v "grep" | awk -F' ' '{print $1}')

	kill -9 $(ps | grep iddd | grep -v "grep" | awk -F' ' '{print $1}')

	ps a > /temp/log/post_ps.txt

	# umount
	mount > /temp/log/pre_umount.txt

	## /boot/modem_fs1
	#umount -l /dev/block/mmcblk0p6
	umount -l /dev/block/platform/msm_sdcc.1/by-name/modemst1
	## /boot/modem_fs2
	#umount -l /dev/block/mmcblk0p7
	umount -l /dev/block/platform/msm_sdcc.1/by-name/modemst2
	## /system
	umount -l /dev/block/mmcblk0p13
	umount -l /dev/block/platform/msm_sdcc.1/by-name/System
	## /data
	umount -l /dev/block/mmcblk0p15
	umount -l /dev/block/platform/msm_sdcc.1/by-name/Userdata
	## /mnt/idd
	umount -l /dev/block/mmcblk0p10
	## /cache
	umount -l /dev/block/mmcblk0p14
	umount -l /dev/block/platform/msm_sdcc.1/by-name/Cache
	## /lta-label
	#umount -l /dev/block/mmcblk0p12
	## /sdcard (External)
	#umount -l /dev/block/mmcblk1p15
	umount -l /dev/block/platform/msm_sdcc.1/by-name/SDCard

	sync

	umount -l /mnt/idd
	umount -l /dev/block/platform/msm_sdcc.1/by-name/apps_log
	umount -l /data/idd
	umount -l /cache
	umount -l /lta-label
	umount -l /etc
	umount -l /data/tombstones
	umount -l /tombstones
	umount -l /vendor
	umount -l /system
	umount -l /data

	## SDcard
	# Internal SDcard mountpoint
	umount -l /sdcard
	umount -l /mnt/sdcard
	umount -l /mnt/int_storage
	umount -l /storage/sdcard0

	# External SDcard mountpoint
	umount -l /sdcard1
	umount -l /ext_card
	umount -l /storage/sdcard1
	umount -l /devices/platform/msm_sdcc.3/mmc_host

	# External USB mountpoint
	umount -l /mnt/usbdisk
	umount -l /usbdisk
	umount -l /storage/usbdisk
	umount -l /devices/platform/msm_hsusb_host

	# legacy folders
	umount -l /storage/emulated/legacy/Android/obb
	umount -l /storage/emulated/legacy
	umount -l /storage/emulated/0/Android/obb
	umount -l /storage/emulated/0
	umount -l /storage/emulated

	umount -l /storage/removable/sdcard1
	umount -l /storage/removable/usbdisk
	umount -l /storage/removable
	umount -l /storage

	umount -l /mnt/shell/emulated/0
	umount -l /mnt/shell/emulated
	umount -l /mnt/shell

	## misc
	umount -l /mnt/obb
	umount -l /mnt/asec
	umount -l /mnt/qcks
	umount -l /mnt/secure/staging
	umount -l /mnt/secure
	umount -l /mnt
	umount -l /acct
	umount -l /dev/cpuctl
	umount -l /dev/pts
	umount -l /dev/socket
	umount -l /tmp
	umount -l /dev
	umount -l /sys/fs/selinux
	umount -l /sys/kernel/debug
	umount -l /d
	umount -l /sys
	umount -l /proc

	sync

	mount > /temp/log/post_umount.txt

	# clean /
	cd /
	rm -r /sbin
	rm -r /storage
	rm -r /mnt
	rm -f sdcard sdcard1 ext_card init*

	ls -laR > /temp/log/post_clean_ls.txt
}

for EVENTDEV in $(ls /dev/input/event*)
do
	SUFFIX="$(expr ${EVENTDEV} : '/dev/input/event\(.*\)')"
	cat ${EVENTDEV} > /temp/keyevent${SUFFIX} &
done

sleep 3

for CATPROC in $(ps | grep cat | grep -v grep | awk '{print $2;}')
do
	kill -9 ${CATPROC}
done

sleep 1

hexdump /temp/keyevent* | grep -e '^.* 0001 0073 .... ....$' > /temp/keycheck_up
hexdump /temp/keyevent* | grep -e '^.* 0001 0072 .... ....$' > /temp/keycheck_down

# vol-, boot recovery
if [ -s /temp/keycheck_down -o -e /cache/recovery/boot ]
then

	# Show red led
	echo '0' > $LED_BLUE
	echo '0' > $LED_GREEN
	echo '255' > $LED_RED

	sleep 1

	# turn off leds
	echo '0' > $LED_BLUE
	echo '0' > $LED_GREEN
	echo '0' > $LED_RED
    echo "======= Hijack: boot recovery =======" > /dev/kmsg
	# Return path variable to default
	export PATH="${_PATH}"
	sleep 1
	exec /system/bin/chargemon
elif [ -e /temp/hijacked ]
then
	rm /temp/hijacked
	# Return path variable to default
	export PATH="${_PATH}"
	sleep 1
	exec /system/bin/wipedata.orig
else
    echo "======= Hijack: boot ramdisk =======" > /dev/kmsg
	touch /temp/hijacked
	boot_rom
	cd /
	cpio -idu < /temp/ramdisk.cpio
	sync
	sleep 2
	cp /temp/ramdisk/* /
	cp /temp/ramdisk/sbin/* /sbin
	#dmesg > /temp/log/post_hijack_dmesg.txt
	ls -laR > /temp/log/post_hijack_ls.txt
	chroot / /init
	sleep 3
fi
	
