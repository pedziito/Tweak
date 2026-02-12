#!/usr/bin/env python3
"""Generate ADAMV TWEAKS icon.ico from the AV logo design.
Requires Pillow: pip install Pillow
Run: python tools/generate_icon.py
Output: resources/icon.ico
"""
import os, sys

try:
    from PIL import Image, ImageDraw
except ImportError:
    print("Pillow not installed. Install with: pip install Pillow")
    sys.exit(1)

# AV logo coordinates (viewBox 0 0 175 160)
# A: outer triangle + counter + crossbar (odd-even fill)
A_OUTER = [(5,155), (55,5), (105,155)]
A_COUNTER = [(55,52), (27,155), (83,155)]
A_CROSSBAR = [(41,105), (69,105), (72,115), (38,115)]
# V: single thick V shape
V_SHAPE = [(65,5), (117,155), (169,5), (152,5), (117,130), (82,5)]

VB_W, VB_H = 175, 160

def lerp_color(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))

def get_gradient_color(x, w):
    """Horizontal gradient: dark navy -> blue -> teal -> bright cyan"""
    stops = [
        (0.0,  (0x1a, 0x3a, 0x6e)),
        (0.35, (0x19, 0x76, 0xd2)),
        (0.65, (0x08, 0x91, 0xb2)),
        (1.0,  (0x22, 0xd3, 0xee)),
    ]
    t = x / w if w > 0 else 0
    t = max(0.0, min(1.0, t))
    for i in range(len(stops) - 1):
        t0, c0 = stops[i]
        t1, c1 = stops[i + 1]
        if t <= t1:
            lt = (t - t0) / (t1 - t0) if t1 > t0 else 0
            return lerp_color(c0, c1, lt)
    return stops[-1][1]

def scale_poly(poly, scale, ox, oy):
    return [(int(x * scale + ox), int(y * scale + oy)) for x, y in poly]

def point_in_poly(x, y, poly):
    """Ray casting algorithm"""
    n = len(poly)
    inside = False
    j = n - 1
    for i in range(n):
        xi, yi = poly[i]
        xj, yj = poly[j]
        if ((yi > y) != (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi):
            inside = not inside
        j = i
    return inside

def render_icon(size):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))

    sx = size / VB_W
    sy = size / VB_H
    s = min(sx, sy)
    ox = (size - VB_W * s) / 2
    oy = (size - VB_H * s) / 2

    a_out = scale_poly(A_OUTER, s, ox, oy)
    a_cnt = scale_poly(A_COUNTER, s, ox, oy)
    a_bar = scale_poly(A_CROSSBAR, s, ox, oy)
    v_shp = scale_poly(V_SHAPE, s, ox, oy)

    for py in range(size):
        for px in range(size):
            # Odd-even fill for A
            in_a = False
            count = 0
            if point_in_poly(px, py, a_out): count += 1
            if point_in_poly(px, py, a_cnt): count += 1
            if point_in_poly(px, py, a_bar): count += 1
            if count % 2 == 1:
                in_a = True

            in_v = point_in_poly(px, py, v_shp)

            if in_a or in_v:
                # Map pixel x back to viewBox x for gradient
                vx = (px - ox) / s if s > 0 else 0
                color = get_gradient_color(vx, VB_W)
                img.putpixel((px, py), color + (255,))

    return img

def main():
    out_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'resources')
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, 'icon.ico')

    sizes = [16, 24, 32, 48, 64, 128, 256]
    images = []
    for sz in sizes:
        print(f"  Rendering {sz}x{sz}...")
        images.append(render_icon(sz))

    # Save as ICO (Pillow supports multi-size ICO)
    images[0].save(out_path, format='ICO', sizes=[(im.width, im.height) for im in images],
                   append_images=images[1:])
    print(f"Icon saved to {out_path}")

if __name__ == '__main__':
    main()
