# Appendix: trying to make the UART accept input

Once I could flash my own images ([steps 3](03-uboot-image-hash.md) and [4](04-loader-mode.md)), I made a
few modified recovery images to try again for a working serial console. Their device trees are in
[`bootloader/recovery/`](../bootloader/recovery/).

- The chip has five UARTs, but the firmware only powers one of them. Pointing the console at any other
  one froze the tablet straight away.
- By measuring the header pins while sending data, I confirmed which pin carries the output.
- The vendor's device tree had the input pin configured wrong. I fixed it, but still nothing arrived:
  the input pin on the header just isn't wired to the chip.

So the UART stayed output only. Input came another way: a USB keyboard in my U-Boot, and later SSH and
the on-screen console in Linux.
