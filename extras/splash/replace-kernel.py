#!/usr/bin/env python3
"""replace-kernel.py BASE.img KERNEL OUT.img — swap the kernel section (our u-boot-dtb.bin) in an
Android boot image v0, keep header fields, ramdisk and second byte-for-byte. Re-sign afterwards."""
import sys, struct
img = open(sys.argv[1], 'rb').read(); k = open(sys.argv[2], 'rb').read()
ks, ka, rs, ra, ss, sa, ta, ps = struct.unpack('<8I', img[8:40])
al = lambda n: (n + ps - 1) // ps * ps
pad = lambda b: b + b'\0' * ((-len(b)) % ps)
hdr = bytearray(img[:ps]); struct.pack_into('<I', hdr, 8, len(k))
ram = img[ps + al(ks): ps + al(ks) + rs]; sec = img[ps + al(ks) + al(rs): ps + al(ks) + al(rs) + ss]
out = bytes(hdr) + pad(k) + pad(ram) + pad(sec)
open(sys.argv[3], 'wb').write(out)
print(f'kernel {ks} -> {len(k)}, ramdisk {rs}, second {ss}; {len(img)} -> {len(out)} bytes')
