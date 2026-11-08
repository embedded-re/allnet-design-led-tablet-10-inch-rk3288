# 4. Rockchip loader mode: writing to the eMMC over USB

The UART log in [step 1](01-uart.md) had shown the chip is a Rockchip. Rockchip chips have a
**loader mode**: a USB mode for flashing the internal storage, with freely available tools for the PC.

It turned out to use the same recovery button as [step 2](02-android-recovery-adb-dump.md), just held
for a **shorter time**. The UART prints `rockusb key pressed.` when it works, so it's easy to see
whether you got the timing right.

In loader mode the PC can read and write any part of the eMMC, and **it asks for no password or key.**

Together with step 3, that was everything I needed: **build an image with a valid checksum, flash it in
loader mode, and the bootloader will start it.**

It also made experimenting safe. Loader mode belongs to the vendor's bootloader, which I never
modified, so it kept working whatever I flashed. If an experiment failed, I went back into loader mode
and restored the original image.

The first thing I flashed this way was my own bootloader → [step 5](05-chainload-uboot.md).
