#!/sbin/sh

busybox mount /system
busybox mount /data

if [ -f /system/bin/taimport.orig ]; 
  then
    rm -rf /system/bin/taimport
    cp /system/bin/taimport.orig /system/bin/taimport
  else
    cp /system/bin/taimport /system/bin/taimport.orig
fi
