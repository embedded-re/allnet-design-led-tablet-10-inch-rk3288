# 1. Opening the tablet: a serial console that only talks

I opened the tablet before ever turning it on. Right on the board was a small unpopulated header that
looked like a **UART**: the serial port developers use to see what a device prints while it boots.
I soldered wires to it and connected it to my PC.

When I powered the tablet on, the whole boot scrolled by: the chip's first-stage loader, the bootloader
(**U-Boot**, the program that starts the operating system) and then the Android kernel. That log already
told me two important things:

- the chip is a **Rockchip RK3288**. That turned out to be lucky, see [step 4](04-loader-mode.md).
- the bootloader checks a button at power-on and prints which way it decided to boot.

The catch: **the console was output only.** I could read everything, but anything I typed was ignored.
The receive line simply isn't connected to the chip on this board (details in the
[appendix](appendix-uart-input.md)).

So I needed another way to get a shell with full privileges on the device → [step 2](02-android-recovery-adb-dump.md).
