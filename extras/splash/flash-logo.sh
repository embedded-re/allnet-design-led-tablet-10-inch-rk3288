#!/bin/sh
# flash-logo.sh W H — build wizard logo WxH, pack into uboot-a image, sign, flash, verify, reboot
set -e; cd "$(dirname "$0")/../.."
W=$1; H=$2; L=extras/splash
python3 -I $L/mklogo.py splash.jpg $W $H $L/logo-${W}x${H}.bmp
BASE=${BASE:-$L/uboot-a.novideo-520x430.img}   # no-video U-Boot (2026-11-08); old base: bootloader/recovery/rec_uboot_emmc.img
python3 -I $L/mkbootimg-logo.py $BASE $L/logo-${W}x${H}.bmp $L/uboot-a.logo-${W}x${H}.img
python3 -I bootloader/resign_bootimg.py $L/uboot-a.logo-${W}x${H}.img $L/uboot-a.logo-${W}x${H}.img >/dev/null
python3 -I bootloader/resign_bootimg.py $L/uboot-a.logo-${W}x${H}.img | grep -q "(match)"
N=$(stat -c %s $L/uboot-a.logo-${W}x${H}.img); M=$(md5sum < $L/uboot-a.logo-${W}x${H}.img | cut -d' ' -f1)
cat $L/uboot-a.logo-${W}x${H}.img | port/emmc/tsh "P=/dev/disk/by-partlabel/uboot-a; cat > /tmp/ua.img; dd if=/tmp/ua.img of=\$P bs=1M conv=fsync 2>/dev/null; echo 3 > /proc/sys/vm/drop_caches; R=\$(head -c $N \$P | md5sum | cut -d' ' -f1); rm /tmp/ua.img; [ \$R = $M ] && echo 'flash verified' || { echo 'READBACK MISMATCH'; exit 1; }; sync; reboot"
