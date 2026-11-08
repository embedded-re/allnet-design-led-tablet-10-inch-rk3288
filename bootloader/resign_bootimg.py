#!/usr/bin/env python3
"""Re-sign an RK3288 Android boot/recovery image with the vendor hash this device's
U-Boot checks (routine FUN_0000c8f4 in bootloader/stock-uboot/uboot.bin).

The hash is a 20-byte SHA-1 stored at header offset 0x240 (followed by 12 zero bytes).
It is standard AOSP SHA-1 EXTENDED to also cover header bytes 0x20..0x240:

    SHA1( kernel || LE32(kernel_size)
        || ramdisk || LE32(ramdisk_size)
        || second || LE32(second_size)
        || header[0x20:0x24]   # tags_addr
        || header[0x24:0x28]   # page_size
        || header[0x28:0x30]   # header_version + os_version
        || header[0x30:0x40]   # name[16]
        || header[0x40:0x240]  # cmdline[512] )

Standard mkbootimg stops after the three sections+sizes, so its id differs and U-Boot
rejects the image (drops to rockusb, which looks like "stuck in maskrom").

Usage:
    bootloader/resign_bootimg.py IMG            # verify: print computed vs stored id, say if it matches
    bootloader/resign_bootimg.py IN OUT         # stamp computed id into header, write OUT (OUT may == IN)

Verified byte-for-byte against stock 08_recovery.img (db9faeee..) and 07_boot.img (da0d9ff9..).
"""
import struct
import sys


def vendor_id(b: bytes) -> bytes:
    if b[:8] != b"ANDROID!":
        raise SystemExit("not an Android boot image (bad magic)")
    g = lambda o: struct.unpack_from("<I", b, o)[0]
    ks, rs, ss, pg = g(8), g(16), g(24), g(36)
    al = lambda x: (x + pg - 1) // pg * pg
    o = pg
    secs = []
    for sz in (ks, rs, ss):
        secs.append(b[o:o + sz])
        o += al(sz)
    import hashlib
    h = hashlib.sha1()
    for data, sz in zip(secs, (ks, rs, ss)):
        h.update(data)
        h.update(struct.pack("<I", sz))
    for seg in (b[0x20:0x24], b[0x24:0x28], b[0x28:0x30], b[0x30:0x40], b[0x40:0x240]):
        h.update(seg)
    return h.digest()


def main(argv):
    if len(argv) not in (2, 3):
        raise SystemExit(__doc__)
    b = bytearray(open(argv[1], "rb").read())
    calc = vendor_id(b)
    stored = bytes(b[0x240:0x254])
    print(f"computed id: {calc.hex()}")
    print(f"stored id:   {stored.hex()}  ({'match' if calc == stored else 'MISMATCH'})")
    if len(argv) == 3:
        b[0x240:0x254] = calc
        b[0x254:0x260] = bytes(12)  # keep the rest of the 32-byte id field zero
        open(argv[2], "wb").write(b)
        print(f"wrote {argv[2]} with id {calc.hex()}")


if __name__ == "__main__":
    main(sys.argv)
