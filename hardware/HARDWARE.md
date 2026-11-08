# RK3288 tablet: hardware found in the backup

## SoC / boot
- Rockchip RK3288 (4x Cortex-A17), Android 8.1.0 userdebug, patch 2018-12
- Kernel 4.4.132, built 2020-04-08 (lxr@ubuntu, Linaro GCC 6.3)
- eMMC: D9D16G (16 GB)
- Boot cmdline: console=ttyFIQ0, selinux=permissive, hardware=rk30board

## I2C devices (from the DTB)
| bus (address)    | addr | chip      | function            |
|------------------|------|-----------|---------------------|
| i2c@ff650000     | 0x40 | SYR827    | CPU power regulator |
| i2c@ff650000     | 0x41 | SYR828    | GPU power regulator |
| i2c@ff650000     | 0x51 | HYM8563   | real-time clock     |
| i2c@ff650000     | 0x5a | ACT8846   | main PMIC           |
| i2c@ff140000     | 0x18 | BMA2xx    | accelerometer       |
| i2c@ff140000     | 0x27 | MIR3DA    | accelerometer (alt) |
| i2c@ff160000     | 0x40 | GSL3673   | touchscreen         |
| i2c@ff160000     | 0x5d | GT9xx     | touchscreen (alt)   |
| i2c@ff660000     | 0x10 | ES8316    | audio codec         |
| i2c@ff660000     | 0x76 | BCM2079x  | NFC                 |
"(alt)" = the vendor's DTB lists several options; only one is fitted.

## Display
- MIPI-DSI, 4 lanes, 800x1280 (portrait), pixel clock 68 MHz
- H: front 20 / sync 20 / back 20; V: front 30 / sync 4 / back 8

## Wireless
- WiFi/BT: AP6212 module (Broadcom BCM43438); firmware in ./firmware/

## Files
- boot/board.dts: full device tree (text)
- boot/kernel.config: exact kernel build config
- boot/ramdisk/: init scripts, fstab
