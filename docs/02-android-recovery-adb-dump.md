# 2. Android recovery: a root shell and a full copy of the storage

Most Android devices have a **recovery mode**, a small separate system used for factory resets and
updates. On this tablet you get there by holding the recovery button while powering on (the UART log
confirms it).

Normally that should be a dead end: the bootloader was **locked**, so I couldn't flash anything from the
PC. But this firmware was a developer (`userdebug`) build, and its recovery was poorly secured:

- I could mount the Android system partition, which gave me the usual command-line tools
- I could start **adb** (Android's USB debug shell) **as root**

That meant a root shell with direct access to the internal storage (the **eMMC**). Before changing
anything, I copied the entire eMMC to my PC with `dd`, partition by partition, and checked every copy
against a checksum taken on the device.

That copy is the foundation for everything that follows:

- it contains the **bootloader program itself**, so I could study how it decides what to boot → [step 3](03-uboot-image-hash.md)
- it contains the **vendor device tree**, the description of every pin, regulator and the screen, which
  I later used to write the Linux port ([`hardware/`](../hardware/))
- if anything went wrong, I could always put the original back

The copy is not in this repo: it holds proprietary code and data specific to my device.
