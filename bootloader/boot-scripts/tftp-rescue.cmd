echo ">>> SmartTab RESCUE: kernel + dtb + initramfs from ${serverip}"
tftp ${kernel_addr_r} zImage
tftp ${fdt_addr_r} rk3288-smarttab.dtb
tftp ${ramdisk_addr_r} initramfs.cpio.gz
setenv bootargs console=tty1 console=ttyS2,115200n8 earlycon=uart8250,mmio32,0xff690000 loglevel=7 panic=10 oops=panic
bootz ${kernel_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r}
