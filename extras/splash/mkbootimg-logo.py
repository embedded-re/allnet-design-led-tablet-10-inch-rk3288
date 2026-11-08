#!/usr/bin/env python3
"""mkbootimg-logo.py BASE.img LOGO.bmp OUT.img — replace logo.bmp in the boot image's `second` RSCE
(keeps header/kernel/ramdisk and rk-kernel.dtb byte-for-byte). Re-sign afterwards with bootloader/resign_bootimg.py."""
import sys, struct
img = bytearray(open(sys.argv[1], 'rb').read()); logo = open(sys.argv[2], 'rb').read()
ks, ka, rs, ra, ss, sa, ta, ps = struct.unpack('<8I', img[8:40])
al = lambda n: (n + ps - 1) // ps * ps
so = ps + al(ks) + al(rs)
second = img[so:so + ss]; assert second[:4] == b'RSCE'
e = 2 * 512; assert second[e + 4:e + 12] == b'logo.bmp' and struct.unpack('<I', second[e + 260:e + 264])[0] == 128
new = bytearray(second[:128 * 512]) + logo; new += b'\0' * ((-len(new)) % 512)
struct.pack_into('<I', new, e + 264, len(logo))
out = bytearray(img[:so]) + new; out += b'\0' * ((-len(out)) % ps)
struct.pack_into('<I', out, 8 + 16, len(new))
open(sys.argv[3], 'wb').write(out)
print(f'second {ss} -> {len(new)}, kernel+ramdisk unchanged: {out[ps:so] == img[ps:so]}')
