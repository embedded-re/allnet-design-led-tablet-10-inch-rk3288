# 6. Porting Linux

With my own bootloader in place, getting Linux running was a normal board port: mainline Linux with
Alpine Linux as the operating system, installed on the eMMC.

## Kernel

I wrote a device tree for the board (the description of its hardware for Linux), based on the vendor
device tree from [step 2](02-android-recovery-adb-dump.md). On top of that, only a few small fixes were
needed ([`port/kernel/`](../port/kernel/)):

- **Leave the Trust OS hardware alone.** The same rule as in step 5. Linux also has to ask the firmware
  to start the other CPU cores instead of doing it itself; after that, all 4 cores run.
- **Screen:** the screen's start-up commands are generated from the vendor device tree. The screen
  flickered until I ran its data link at the same speed as the vendor firmware did.
- **Ethernet:** the network chip sometimes needed longer to reset than Linux waited, so it failed on some
  boots. A longer timeout fixed it.

## Storage

I wiped Android and repartitioned the eMMC. The vendor's start-up code stays exactly where the chip
expects it. After it come two copies of my U-Boot (so a bad update can't lock me out), a boot partition,
a partition reserved for a future custom OS, and Alpine. Layout and installer: [`port/emmc/`](../port/emmc/).

## Status

Working: screen, touch, Ethernet, WiFi/Bluetooth, USB, eMMC/SD card, audio, accelerometer, GPU,
thermal management, and a small desktop. Known issue: the clock loses the time when the tablet is off.

Extras (boot logo, audio, desktop, performance tuning, Doom): [`extras/`](../extras/).
