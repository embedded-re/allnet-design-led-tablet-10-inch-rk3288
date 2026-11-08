# /boot/boot.scr on PARTLABEL=boot (mmc 0:9): offline boot, everything from the eMMC.
# Rebuild: mkimage -A arm -T script -C none -n emmc -d boot.cmd boot.scr
echo ">>> SmartTab eMMC boot: kernel + dtb from mmc 0:9, root = PARTLABEL=linux"
load mmc 0:9 ${kernel_addr_r} zImage
load mmc 0:9 ${fdt_addr_r} rk3288-smarttab.dtb
# optional experiment args: a text file containing one line  extra=<kernel args>
setenv extra
if load mmc 0:9 ${ramdisk_addr_r} extra-args.txt; then env import -t ${ramdisk_addr_r} ${filesize}; fi
echo ">>> extra bootargs: [${extra}]"
setenv bootargs console=tty1 fbcon=rotate:3 console=ttyS2,115200n8 earlycon=uart8250,mmio32,0xff690000 loglevel=7 panic=10 oops=panic root=PARTLABEL=linux rootfstype=ext4 rootwait rw ${extra}
# stop the stock U-Boot's splash scan-out before Linux: VOP SYS_CTRL standby (bit 22) + REG_CFG_DONE.
# Without this the VOP is still active at kernel start and Linux's power-domain handshake can time out
# ("vop_crtc_atomic_enable: failed to get pm runtime: -110").
# (no setexpr in our U-Boot: stock SYS_CTRL is 0x00809000, + standby bit 22)
mw.l 0xff930008 0x00c09000
mw.l 0xff930000 1
sleep 0.05
bootz ${kernel_addr_r} - ${fdt_addr_r}
