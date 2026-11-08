# 5. Running my own bootloader

The stock bootloader loads a boot image, verifies its checksum, and jumps to the program inside, which
is normally the Linux kernel. **It doesn't check that this program actually is a kernel.**

So instead of replacing the vendor bootloader, I let it start mine. I built a current, mainline
**U-Boot**, packed it into a boot image where the kernel would normally go, gave it a valid checksum and
flashed it:

```
power on → vendor bootloader (untouched)
         → checks the image → starts my U-Boot
         → my U-Boot starts mainline Linux
```

That kept the vendor's start-up code intact and left loader mode working as a safety net.

Two things needed care:

- **Some hardware is reserved for the vendor's security firmware** (the "Trust OS"). If my U-Boot, or
  later Linux, touches it, the board freezes without any error. Everything I build stays away from it.
- **There's still no keyboard input over the UART**, so I set up U-Boot to use a USB keyboard instead.

With my own bootloader running, I could boot anything I wanted. From here it was a standard Linux
port → [step 6](06-mainline-linux.md).

Files: U-Boot config in [`bootloader/u-boot/`](../bootloader/u-boot/), boot scripts in
[`bootloader/boot-scripts/`](../bootloader/boot-scripts/) and [`port/emmc/boot-emmc.cmd`](../port/emmc/boot-emmc.cmd).
