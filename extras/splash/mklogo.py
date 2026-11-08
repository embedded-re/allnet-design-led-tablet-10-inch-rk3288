#!/usr/bin/env python3
"""mklogo.py SRC W H OUT.bmp — rotate like the stock Android logo (head left), fit into WxH on black,
write a 24-bit BMP whose header mimics the stock logo.bmp (bfReserved1=8399, biSizeImage/DPI = 0)."""
import sys, struct
from PIL import Image
src, W, H, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
im = Image.open(src).convert('RGB').rotate(90, expand=True)
s = min(W / im.width, H / im.height)
im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
canvas = Image.new('RGB', (W, H), (0, 0, 0)); canvas.paste(im, ((W - im.width) // 2, (H - im.height) // 2))
row = (W * 3 + 3) // 4 * 4
pix = bytearray()
for y in range(H - 1, -1, -1):                      # bottom-up rows, BGR
    line = bytearray()
    for x in range(W):
        r, g, b = canvas.getpixel((x, y)); line += bytes((b, g, r))
    pix += line + b'\0' * (row - W * 3)
hdr = struct.pack('<2sIHHIIiiHHIIiiII', b'BM', 54 + len(pix), 8399, 0, 54, 40, W, H, 1, 24, 0, 0, 0, 0, 0, 0)
open(out, 'wb').write(hdr + pix)
print(out, W, H, 54 + len(pix), 'bytes')
