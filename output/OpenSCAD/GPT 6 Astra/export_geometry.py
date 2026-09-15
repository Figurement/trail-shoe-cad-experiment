"""Export named rendering meshes from the native document, without opening a GUI."""

import argparse
import hashlib
import json
import shutil
import subprocess
import tempfile
from pathlib import Path

import numpy as np
import trimesh

ROOT = Path(__file__).resolve().parent
DOCUMENT = ROOT / "Trail_Shoe.scad"
PARTS = {
    "midsole": ("01_Continuous_midsole", [194, 199, 191, 255]),
    "outsole": ("02_Rubber_carrier_and_traction", [48, 59, 64, 255]),
    "upper": ("03_Continuous_textile_upper", [97, 125, 135, 255]),
    "tongue": ("04_Tongue_and_keeper", [97, 125, 135, 255]),
    "collar": ("05_Collar_padding", [66, 82, 89, 255]),
    "support_panels": ("06_Asymmetric_support_panels", [66, 82, 89, 255]),
    "overlay_panels": ("07_Variable_width_overlay_panels", [166, 148, 122, 255]),
    "toe_guard": ("08_Continuous_toe_reinforcement", [66, 82, 89, 255]),
    "eyelets": ("09_Eyestays_with_functional_bores", [166, 148, 122, 255]),
    "laces": ("10_Crossed_lace_sweeps", [209, 207, 191, 255]),
    "heel_webbing": ("11_Heel_webbing", [166, 148, 122, 255]),
    "toe_bumper": ("12_Rubber_toe_wrap", [48, 59, 64, 255]),
    "cougar_graphic": ("13_Cougar_outline_graphic", [212, 217, 212, 255]),
}


def inspect_mesh(path):
    mesh = trimesh.load_mesh(path, process=True)
    if not isinstance(mesh, trimesh.Trimesh) or mesh.is_empty:
        raise RuntimeError(f"{path.name}: not a nonempty mesh")
    solids = mesh.split(only_watertight=False)
    if not all(solid.is_watertight and solid.is_winding_consistent and solid.volume > 0
               for solid in solids):
        raise RuntimeError(f"{path.name}: open, inverted or inconsistently wound geometry")
    return mesh, {
        "file": path.name,
        "closed_solids": len(solids),
        "triangles": len(mesh.faces),
        "volume_mm3": float(mesh.volume),
        "bounds_mm": mesh.bounds.tolist(),
        "watertight": bool(mesh.is_watertight),
        "consistent_winding": bool(mesh.is_winding_consistent),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--parts", nargs="+", choices=tuple(PARTS), default=list(PARTS))
    parser.add_argument("--quality", type=int, choices=(0, 1), default=1)
    parser.add_argument("--reuse", action="store_true", help="Reuse components with unchanged compiled geometry.")
    args = parser.parse_args()
    executable = shutil.which("openscad")
    if not executable:
        raise SystemExit("OpenSCAD is required on PATH.")
    destination = ROOT / "meshes"
    destination.mkdir(exist_ok=True)
    settings = {
        "document_sha256": hashlib.sha256(DOCUMENT.read_bytes()).hexdigest(),
        "quality": args.quality,
        "stage": 3,
    }
    report = {}
    for part in args.parts:
        name, _ = PARTS[part]
        path = destination / f"{name}.stl"
        metadata = destination / f"{name}.json"
        arguments = [
            executable, str(DOCUMENT), "--hardwarnings", "-D", f'part="{part}"',
            "-D", "stage=3", "-D", f"quality={args.quality}",
        ]
        with tempfile.TemporaryDirectory(prefix="shoe-csg-") as temporary:
            compiled = Path(temporary) / f"{part}.csg"
            result = subprocess.run(arguments + ["-o", str(compiled)], capture_output=True, text=True)
            if result.returncode or "ERROR:" in result.stderr or "WARNING:" in result.stderr:
                raise RuntimeError(f"{part} compilation: {result.stdout}\n{result.stderr}")
            geometry_hash = hashlib.sha256(compiled.read_bytes()).hexdigest()
        previous = json.loads(metadata.read_text()) if metadata.exists() else {}
        current = path.exists() and (
            previous.get("settings") == settings
            or previous.get("geometry_sha256") == geometry_hash
        )
        if not (args.reuse and current):
            result = subprocess.run(
                arguments + ["-o", str(path), "--export-format", "binstl"],
                capture_output=True, text=True,
            )
            (destination / f"{name}.log").write_text(result.stdout + result.stderr)
            if result.returncode or "ERROR:" in result.stderr or "WARNING:" in result.stderr:
                raise RuntimeError(f"{part}: {result.stdout}\n{result.stderr}")
        _, report[part] = inspect_mesh(path)
        metadata.write_text(json.dumps({
            "settings": settings, "geometry_sha256": geometry_hash, **report[part]
        }, indent=2) + "\n")
        print(f"{name}: {report[part]['closed_solids']} closed solid(s)", flush=True)
    (destination / "geometry_report.json").write_text(
        json.dumps({"settings": settings, "parts": report}, indent=2) + "\n"
    )
    if set(args.parts) != set(PARTS):
        return
    scene = trimesh.Scene()
    for part, (name, color) in PARTS.items():
        mesh, _ = inspect_mesh(destination / f"{name}.stl")
        mesh.visual.vertex_colors = color
        if part == "laces":
            mesh.visual = trimesh.visual.TextureVisuals(
                material=trimesh.visual.material.PBRMaterial(
                    name="Finely_woven_lace_placeholder", baseColorFactor=color,
                    metallicFactor=0, roughnessFactor=0.95,
                )
            )
        # glTF uses metres. Source SCAD and the STL meshes remain in millimetres.
        mesh.apply_scale(0.001)
        scene.add_geometry(mesh, node_name=name, geom_name=name)
    bundle = ROOT / "Trail_Shoe.glb"
    bundle.write_bytes(scene.export(file_type="glb"))
    reopened = trimesh.load_scene(bundle)
    if set(reopened.geometry) != {value[0] for value in PARTS.values()}:
        raise RuntimeError("GLB component names did not survive reopening")
    if not np.allclose(reopened.bounds, scene.bounds, atol=1e-6):
        raise RuntimeError("GLB geometry bounds changed during export")
    for name, mesh in reopened.geometry.items():
        source = scene.geometry[name]
        if len(mesh.faces) != len(source.faces) or not np.allclose(
            mesh.vertices, source.vertices, atol=1e-6
        ):
            raise RuntimeError(f"GLB geometry changed for {name}")
    print(f"Exported {bundle} with {len(reopened.geometry)} named components", flush=True)


if __name__ == "__main__":
    main()
