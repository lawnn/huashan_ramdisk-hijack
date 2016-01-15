#!/sbin/sh

busybox mount /system
busybox mount /data

if [ -f /system/bin/wipedata.orig ]; 
  then
    rm -rf /system/bin/wipedata
    cp /system/bin/wipedata.orig /system/bin/wipedata
  else
    cp /system/bin/wipedata /system/bin/wipedata.orig
fi
