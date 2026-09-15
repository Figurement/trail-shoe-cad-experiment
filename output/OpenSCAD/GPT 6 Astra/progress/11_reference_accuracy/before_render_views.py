"""Export this specific OpenSCAD document; never attach to the desktop GUI."""

import argparse
import hashlib
import json
import shutil
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parent
DOCUMENT = ROOT / "Trail_Shoe.scad"
VIEWS = {
    "lateral_reference": ((380, -840, 260, 147, 0, 67), (1200, 680)),
    "medial_reference": ((200, 840, 225, 147, 0, 67), (1200, 680)),
    "front_reference": ((860, -25, 310, 150, 0, 64), (720, 1040)),
    "heel_reference": ((-820, 0, 130, 100, 0, 66), (720, 1040)),
    "lateral": ((150, -850, 67, 150, 0, 67), (1200, 680)),
    "medial": ((150, 850, 67, 150, 0, 67), (1200, 680)),
    "front": ((850, 0, 67, 150, 0, 67), (720, 900)),
    "heel": ((-750, 0, 67, 100, 0, 67), (720, 900)),
    "top": ((150, 0, 950, 150, 0, 0), (1200, 680)),
    "outsole": ((150, 0, -950, 150, 0, 0), (1200, 680)),
    "panel_detail": ((156, -360, 125, 123, -14, 65), (1200, 800)),
    "toe_detail": ((480, -260, 135, 255, 0, 42), (1000, 800)),
    "heel_detail": ((-260, -190, 150, 22, 0, 55), (1000, 800)),
    "lace_detail": ((245, -235, 350, 146, 0, 110), (1200, 850)),
    "cougar_detail": ((265, -360, 205, 192, -25, 66), (1200, 850)),
}
REFERENCES = {
    "lateral_reference": ("left-view.jpg", (310, 190, 1685, 895)),
    "medial_reference": ("three-angles.jpg", (605, 375, 1435, 858)),
    "front_reference": ("three-angles.jpg", (116, 174, 578, 921)),
    "heel_reference": ("three-angles.jpg", (1480, 263, 1960, 915)),
}


def fitted(image, size):
    return ImageOps.pad(image.convert("RGB"), size, color="white", method=Image.Resampling.LANCZOS)


def object_crop(image):
    """Trim only the uniform CAD background; never stretch either image."""
    from PIL import ImageChops

    background = Image.new("RGB", image.size, image.convert("RGB").getpixel((0, 0)))
    difference = ImageChops.difference(image.convert("RGB"), background)
    bounds = difference.point(lambda value: 255 if value > 12 else 0).getbbox()
    return image.crop(bounds) if bounds else image


def comparisons(destination):
    sheet = Image.new("RGB", (1600, 1840), "white")
    draw = ImageDraw.Draw(sheet)
    for row, (name, (filename, bounds)) in enumerate(REFERENCES.items()):
        with Image.open(ROOT.parent / "input" / filename) as source:
            ratio = source.width / 2000
            ref = source.crop(tuple(round(value * ratio) for value in bounds))
        with Image.open(destination / f"{name}.png") as cad:
            model = object_crop(cad)
        sheet.paste(fitted(ref, (780, 410)), (10, row * 460 + 35))
        sheet.paste(fitted(model, (780, 410)), (810, row * 460 + 35))
        draw.text((15, row * 460 + 12), f"PHOTO / {name.replace('_', ' ')}", fill="black")
        draw.text((815, row * 460 + 12), "CAD / inferred scale / placeholder colors", fill="black")
    sheet.save(destination / "reference_comparison.png")


def inspection_sheet(destination):
    names = ("lateral", "medial", "front", "heel", "top", "outsole")
    if not all((destination / f"{name}.png").exists() for name in names):
        return
    sheet = Image.new("RGB", (1600, 1500), "white")
    draw = ImageDraw.Draw(sheet)
    for index, name in enumerate(names):
        x, y = (index % 2) * 800, (index // 2) * 500
        with Image.open(destination / f"{name}.png") as source:
            sheet.paste(fitted(object_crop(source), (770, 455)), (x + 15, y + 30))
        label = name.upper()
        if name == "outsole":
            label += " / HIDDEN LAYOUT INFERRED"
        draw.text((x + 15, y + 10), label, fill="black")
    sheet.save(destination / "inspection_sheet.png")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--stage", type=int, choices=(1, 2, 3), default=3)
    parser.add_argument("--folder", default="views")
    parser.add_argument("--views", nargs="+", choices=tuple(VIEWS), default=list(VIEWS))
    parser.add_argument("--quality", type=int, choices=(0, 1), default=1)
    parser.add_argument("--mesh-cache", action="store_true")
    args = parser.parse_args()
    executable = shutil.which("openscad")
    if not executable:
        raise SystemExit("OpenSCAD is required on PATH.")
    if args.mesh_cache:
        report = json.loads((ROOT / "meshes" / "geometry_report.json").read_text())
        if (report["settings"]["document_sha256"] != hashlib.sha256(DOCUMENT.read_bytes()).hexdigest()
                or report["settings"]["quality"] != args.quality or args.stage != 3
                or len(report["parts"]) != 13):
            raise RuntimeError("Mesh cache is incomplete or stale; run export_geometry.py first.")
    destination = ROOT / args.folder
    destination.mkdir(parents=True, exist_ok=True)
    for name in args.views:
        camera, size = VIEWS[name]
        eye, target = camera[:3], camera[3:]
        zoom = {
            "front_reference": 0.82, "heel_reference": 0.66,
            "front": 0.66, "heel": 0.66,
            "panel_detail": 0.8, "toe_detail": 0.8, "heel_detail": 0.8,
            "lace_detail": 0.8, "cougar_detail": 0.8,
        }.get(name, 0.60)
        framed_camera = tuple(t + (e - t) * zoom for e, t in zip(eye, target)) + target
        command = [
            executable, str(DOCUMENT), "-o", str(destination / f"{name}.png"),
            "--camera", ",".join(map(str, framed_camera)), "--imgsize", ",".join(map(str, size)),
            "--projection", "o", "--colorscheme", "Tomorrow",
            "--hardwarnings", "-D", f"stage={args.stage}", "-D", f"quality={args.quality}",
            "-D", f"use_exported_meshes={'true' if args.mesh_cache else 'false'}",
        ]
        result = subprocess.run(command, capture_output=True, text=True)
        (destination / f"{name}.log").write_text(result.stdout + result.stderr)
        if result.returncode or "ERROR:" in result.stderr or "WARNING:" in result.stderr:
            raise RuntimeError(f"{name}: {result.stdout}\n{result.stderr}")
        print(f"Exported {destination / (name + '.png')}", flush=True)
    if all((destination / f"{name}.png").exists() for name in REFERENCES):
        comparisons(destination)
    inspection_sheet(destination)


if __name__ == "__main__":
    main()
