#!/usr/bin/env python3
"""Side-by-side reference vs CAD comparison sheets.

usage: compare_views.py <tag>      (uses output/progress/<tag>_<view>.png)
writes output/compare/<tag>_<view>.png  (reference left, CAD right, same height,
aspect ratios preserved — nothing is stretched).
"""
import sys, os
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
INPUT = os.path.join(HERE, "..", "input")
SCALE = 2816 / 2000  # crops below were measured on a 2000 px wide copy

# view -> (reference file, crop box in 2000-px coordinates)
REFS = {
    "lateral": ("left-view.jpg", (300, 180, 1750, 900)),
    "medial":  ("three-angles.jpg", (580, 380, 1470, 850)),
    "front":   ("three-angles.jpg", (50, 150, 650, 950)),
    "heel":    ("three-angles.jpg", (1420, 250, 2000, 900)),
    "hero":    ("left-view.jpg", (300, 180, 1750, 900)),
}


def autocrop(im, bg=None, pad=30):
    """Crop a CAD render to its content (background = corner colour)."""
    im = im.convert("RGB")
    bg = bg or im.getpixel((0, 0))
    diff = Image.eval(im, lambda v: v)  # copy
    px = im.load()
    w, h = im.size
    xs, ys = [], []
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            p = px[x, y]
            if abs(p[0] - bg[0]) + abs(p[1] - bg[1]) + abs(p[2] - bg[2]) > 40:
                xs.append(x); ys.append(y)
    if not xs:
        return im
    return im.crop((max(min(xs) - pad, 0), max(min(ys) - pad, 0), min(max(xs) + pad, w), min(max(ys) + pad, h)))


def main(tag):
    outdir = os.path.join(HERE, "compare")
    os.makedirs(outdir, exist_ok=True)
    for view, (ref, box) in REFS.items():
        cad_path = os.path.join(HERE, "progress", f"{tag}_{view}.png")
        if not os.path.exists(cad_path):
            continue
        r = Image.open(os.path.join(INPUT, ref)).crop(tuple(int(v * SCALE) for v in box))
        c = autocrop(Image.open(cad_path))
        H = 700
        r = r.resize((int(r.width * H / r.height), H), Image.LANCZOS)
        c = c.resize((int(c.width * H / c.height), H), Image.LANCZOS)
        sheet = Image.new("RGB", (r.width + c.width + 30, H + 40), (255, 255, 255))
        sheet.paste(r, (10, 30)); sheet.paste(c, (r.width + 20, 30))
        d = ImageDraw.Draw(sheet)
        d.text((12, 8), f"reference: {ref} [{view}]", fill=(0, 0, 0))
        d.text((r.width + 22, 8), f"CAD: {tag}_{view}.png", fill=(0, 0, 0))
        out = os.path.join(outdir, f"{tag}_{view}.png")
        sheet.save(out)
        print("wrote", out)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "latest")
