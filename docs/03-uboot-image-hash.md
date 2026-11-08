# 3. Ghidra: what does the bootloader check before booting?

To run my own software I had to know what the bootloader would accept. My first attempt, the stock
recovery image repacked with the standard Android tool, **was refused**: the tablet never booted it.

So I loaded the bootloader from the eMMC copy into **Ghidra** (a disassembler) and searched for error
messages. One stood out: `"boot or recovery image sha mismatch!"`. The code around it showed exactly
what happens:

- every boot image carries a **checksum** (a SHA-1 hash) in its header
- the bootloader recalculates that checksum over the image and compares the two
- if they differ, it refuses to boot

Standard Android tools write a checksum too, but Rockchip calculates it over **more of the header**
than standard Android does. That's why my repacked image was refused.

The important part: **this checksum only detects damaged images, it does not prove who made them.**
No secret key is involved, so anyone who knows the recipe can compute a valid checksum for any image,
including their own. (Real signature checking exists in this bootloader, but it is switched off on this
device.)

I reimplemented the recipe and checked it against the original images: it matched byte for byte. The
tool is [`resign_bootimg.py`](../bootloader/resign_bootimg.py).

Now I could build images the bootloader would accept. I still needed a way to write them to the
eMMC → [step 4](04-loader-mode.md).
