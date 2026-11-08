#!/bin/sh
# Run ON THE TABLET (from the TFTP initramfs): installs Alpine onto PARTLABEL=linux (p11).
set -e
R=/mnt/root
mkdir -p $R
mountpoint -q $R || mount /dev/disk/by-partlabel/linux $R 2>/dev/null || mount /dev/mmcblk0p11 $R
mkdir -p $R/etc/apk
cp -a /etc/apk/keys $R/etc/apk/
cp /etc/apk/repositories $R/etc/apk/
apk --root $R --initdb --no-cache -q add \
    alpine-base openrc busybox-openrc dropbear dropbear-openrc e2fsprogs e2fsprogs-extra \
    sfdisk blkid util-linux-misc ifupdown-ng chrony tzdata nano less htop i2c-tools evtest \
    kbd-bkeymaps

echo smarttab > $R/etc/hostname
printf '127.0.0.1\tlocalhost smarttab\n::1\t\tlocalhost\n' > $R/etc/hosts
mkdir -p $R/lib/modules
cat > $R/etc/fstab <<'F'
LABEL=smarttab-root /      ext4  rw,noatime  0 1
LABEL=boot   /boot  ext4  rw,noatime  0 2
F
mkdir -p $R/boot
cat > $R/etc/network/interfaces <<'F'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
	# fixed, locally administered MAC (U-Boot uses a random one) -> stable DHCP lease
	pre-up ip link set eth0 address 02:53:54:32:88:01
F
# gettys: panel console + UART2 (output only, but harmless)
sed -i -e 's/^tty[3-6]:/#&/' $R/etc/inittab
grep -q '^ttyS2::' $R/etc/inittab || echo 'ttyS2::respawn:/sbin/getty -L 115200 ttyS2 vt100' >> $R/etc/inittab
grep -q '^ttyS2$' $R/etc/securetty 2>/dev/null || echo ttyS2 >> $R/etc/securetty
# root: no password on the local consoles (as before), SSH key only remotely
sed -i 's|^root:[^:]*:|root::|' $R/etc/shadow
mkdir -p $R/root/.ssh && chmod 700 $R/root/.ssh
cp /root/.ssh/authorized_keys $R/root/.ssh/ && chmod 600 $R/root/.ssh/authorized_keys
echo 'DROPBEAR_OPTS="-s -R"' > $R/etc/conf.d/dropbear
# eth0 retry + serial marker used by port/emmc/tsh to find the (random-MAC) IP
cp /tmp/net-retry.start $R/etc/local.d/net-retry.start   # copy port/emmc/net-retry.start to /tmp first
chmod +x $R/etc/local.d/net-retry.start
# remote robustness: hardware watchdog (dw_wdt) fed by busybox, reboot on panic/oops
printf 'WATCHDOG_OPTS="-t 5 -T 20"\nWATCHDOG_DEV="/dev/watchdog"\n' > $R/etc/conf.d/watchdog
printf 'kernel.panic = 10\nkernel.panic_on_oops = 1\n' > $R/etc/sysctl.d/90-remote.conf
ln -sf /usr/share/zoneinfo/Europe/Bratislava $R/etc/localtime

for s in devfs dmesg mdev hwdrivers; do ln -sf /etc/init.d/$s $R/etc/runlevels/sysinit/$s; done
for s in modules sysctl hostname bootmisc syslog hwclock fsck root localmount swap; do
    [ -e $R/etc/init.d/$s ] && ln -sf /etc/init.d/$s $R/etc/runlevels/boot/$s; done
for s in networking dropbear chronyd local watchdog; do ln -sf /etc/init.d/$s $R/etc/runlevels/default/$s; done
for s in mount-ro killprocs savecache; do ln -sf /etc/init.d/$s $R/etc/runlevels/shutdown/$s; done
rm -f $R/etc/runlevels/boot/hwclock   # no RTC wired up yet; chrony sets the time
sync
du -sh $R; echo INSTALL-OK
