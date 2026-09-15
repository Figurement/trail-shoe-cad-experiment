"""Export exchange copies without saving/recomputing the editable source document.

Run with FreeCAD's bundled Python (never FreeCADGui):

  PYTHONPATH=/Applications/FreeCAD.app/Contents/Resources/lib \
    /Applications/FreeCAD.app/Contents/Resources/bin/python \
    examples/cougar-shoes/export_cougar_step.py INPUT.FCStd OUTPUT.step

The destination and its .log/.validation.json sidecars must not already exist.
Only a fully validated STEP is published. STEP product names use native object
Names; original display Labels and volume diagnostics remain in the JSON report.
The worker is isolated so an OCCT fatal signal cannot kill the calling process.
"""

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import uuid


NURBS_COMPONENTS = ("bonding_flange", "quarter_material_join", "contoured_eyestay")
VOLUME_REL_TOL = 0.001


def checkpoint(stage, **details):
    print(json.dumps(dict(stage=stage, **details)), flush=True)


def fingerprint(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def check_shape(shape, name, check_pcurves=False):
    if shape.isNull() or not shape.isValid() or not shape.Solids:
        raise RuntimeError(f"{name}: missing or invalid solid shape")
    for index, solid in enumerate(shape.Solids):
        if not solid.isValid() or not solid.isClosed():
            raise RuntimeError(f"{name}: solid {index} invalid or open")
        if not math.isfinite(solid.Volume) or solid.Volume <= 0:
            raise RuntimeError(f"{name}: solid {index} has non-positive volume")
    pending = [shape]
    while pending:
        item = pending.pop()
        if item.ShapeType in ("Compound", "CompSolid"):
            pending.extend(item.childShapes())
        elif item.ShapeType != "Solid":
            raise RuntimeError(f"{name}: stray {item.ShapeType} outside solids")
    if check_pcurves:
        for index, face in enumerate(shape.Faces):
            if not face.Wires or not face.OuterWire.Edges:
                raise RuntimeError(f"{name}: face {index} has no outer wire")
            if not all(math.isfinite(value) for value in face.ParameterRange):
                raise RuntimeError(f"{name}: face {index} has invalid UV bounds")
            for edge in face.Edges:
                pcurve = face.curveOnSurface(edge)
                if not pcurve or pcurve[0] is None:
                    raise RuntimeError(f"{name}: face {index} has a missing pcurve")


def compare_volumes(source, restored, name):
    """Check every solid, exposing OCCT's non-adaptive Volume integration drift."""
    import MeshPart

    if len(source.Solids) != len(restored.Solids):
        raise RuntimeError(f"{name}: changed solid count")
    source_solids = sorted(source.Solids, key=lambda solid: solid.Volume)
    restored_solids = sorted(restored.Solids, key=lambda solid: solid.Volume)
    rows = []
    for index, (before, after) in enumerate(zip(source_solids, restored_solids)):
        relative = abs(before.Volume - after.Volume) / before.Volume
        row = dict(solid=index, source_volume=before.Volume,
                   step_volume=after.Volume, relative_difference=relative,
                   comparison="brep_volume")
        if relative > VOLUME_REL_TOL:
            # Offset/BSpline faces have representation-sensitive BRepGProp
            # quadrature. Compare independent tessellated volumes at two
            # resolutions instead of accepting a loose native-volume tolerance.
            row["comparison"] = "mesh_volume_at_two_resolutions"
            row["mesh_checks"] = []
            for deflection in (0.025, 0.00625):
                volumes = []
                for shape in (before, after):
                    # Mesh stores floats; center before triangulation to avoid
                    # cancellation in thin, far-from-origin solid volumes.
                    shape = shape.copy()
                    shape.translate(-shape.BoundBox.Center)
                    mesh = MeshPart.meshFromShape(
                        Shape=shape, LinearDeflection=deflection,
                        AngularDeflection=0.05, Relative=False)
                    if not mesh.isSolid() or not math.isfinite(mesh.Volume) or mesh.Volume <= 0:
                        raise RuntimeError(f"{name}: solid {index} invalid validation mesh")
                    volumes.append(mesh.Volume)
                mesh_relative = abs(volumes[0] - volumes[1]) / volumes[0]
                row["mesh_checks"].append(dict(
                    deflection_mm=deflection, source_volume=volumes[0],
                    step_volume=volumes[1], relative_difference=mesh_relative))
                if mesh_relative > VOLUME_REL_TOL:
                    raise RuntimeError(
                        f"{name}: solid {index} mesh volume changed by "
                        f"{mesh_relative:.6%} at {deflection} mm")
        rows.append(row)
    return rows


def worker(source_path, output_path, report_path):
    import FreeCAD as App
    import Part
    import Import

    sys.path.append(App.getResourceDir() + "Mod/Draft")
    import Draft  # noqa: F401 -- restores Draft BSpline proxy objects on open

    if App.GuiUp:
        raise RuntimeError("Run this exporter in headless bundled Python, not the GUI")
    before_hash = fingerprint(source_path)
    checkpoint("open_source", path=str(source_path), sha256=before_hash)
    source = App.openDocument(str(source_path))
    exchange = App.newDocument("CougarStepExchange")
    imported = None
    try:
        originals = [obj for obj in source.Objects if hasattr(obj, "RenderMaterial")]
        if not originals:
            raise RuntimeError("No RenderMaterial final components found")
        copies = []
        components = {}
        for obj in originals:
            checkpoint("preflight", component=obj.Name)
            if "Invalid" in obj.State or "Error" in obj.State:
                raise RuntimeError(f"{obj.Name}: native feature state {obj.State}")
            native = obj.Shape
            check_shape(native, obj.Name)
            convert = any(tag in obj.Name for tag in NURBS_COMPONENTS)
            shape = native.copy()
            if convert:
                shape = shape.toNurbs()
            check_shape(shape, obj.Name + ":exchange", check_pcurves=True)
            if len(shape.Solids) != len(native.Solids):
                raise RuntimeError(f"{obj.Name}: NURBS conversion changed solid count")
            copy = exchange.addObject("Part::Feature", obj.Name)
            copy.Label = obj.Name
            copy.Shape = shape
            copies.append(copy)
            components[obj.Name] = dict(
                label=obj.Label, material=obj.RenderMaterial,
                source_solids=len(native.Solids), source_volume=native.Volume,
                exchange_volume=shape.Volume, converted_to_nurbs=convert)
        exchange.recompute()
        expected_count = sum(row["source_solids"] for row in components.values())
        probe_path = output_path.with_suffix(".component.step")
        try:
            for copy in copies:
                checkpoint("export_component", component=copy.Name)
                Import.export([copy], str(probe_path))
                checkpoint("read_component", component=copy.Name)
                probe = Part.read(str(probe_path))
                check_shape(probe, copy.Name + ":individual_step")
                if len(probe.Solids) != len(copy.Shape.Solids):
                    raise RuntimeError(f"{copy.Name}: individual STEP lost solids")
        finally:
            probe_path.unlink(missing_ok=True)
        checkpoint("export_assembly", components=len(copies), solids=expected_count)
        Import.export(copies, str(output_path))
        checkpoint("read_aggregate")
        aggregate = Part.read(str(output_path))
        check_shape(aggregate, "STEP aggregate")
        if len(aggregate.Solids) != expected_count:
            raise RuntimeError(
                f"STEP lost solids: expected {expected_count}, got {len(aggregate.Solids)}")
        checkpoint("read_named_components")
        imported = App.newDocument("CougarStepRoundtrip")
        Import.insert(str(output_path), imported.Name)
        roots = [obj for obj in imported.Objects
                 if obj.TypeId == "App::Part"
                 and not any(parent.TypeId == "App::Part" for parent in obj.InList)]
        if len(roots) != 1:
            raise RuntimeError(f"Expected one STEP assembly, found {len(roots)}")
        roundtrip = {}
        for obj in roots[0].Group:
            # FreeCAD labels compound children with the same product name and
            # auto-suffixes their assembly Label; its internal Name stays intact.
            name = obj.Name if obj.TypeId == "App::Part" else obj.Label
            if name in roundtrip:
                raise RuntimeError(f"Duplicate STEP component name: {name}")
            roundtrip[name] = obj
        if set(roundtrip) != set(components):
            raise RuntimeError(
                f"STEP component name mismatch: missing={set(components) - set(roundtrip)}, "
                f"extra={set(roundtrip) - set(components)}")
        for obj in originals:
            checkpoint("validate_component", component=obj.Name)
            shape = roundtrip[obj.Name].Shape
            check_shape(shape, obj.Name + ":roundtrip")
            components[obj.Name]["roundtrip_solids"] = len(shape.Solids)
            components[obj.Name]["volume_comparison"] = compare_volumes(
                obj.Shape, shape, obj.Name)
        if fingerprint(source_path) != before_hash:
            raise RuntimeError("Source file changed during export; retry on a snapshot")
        report = dict(
            status="validated", source=str(source_path), source_sha256=before_hash,
            freecad_version=App.Version(), components_count=len(components),
            source_solids=expected_count, roundtrip_solids=len(aggregate.Solids),
            roundtrip_valid=True, positive_volumes=True,
            volume_relative_tolerance=VOLUME_REL_TOL, components=components)
        report_path.write_text(json.dumps(report, indent=2) + "\n")
        checkpoint("validated", solids=expected_count)
    finally:
        if imported is not None:
            App.closeDocument(imported.Name)
        App.closeDocument(exchange.Name)
        App.closeDocument(source.Name)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--worker-report", type=Path, help=argparse.SUPPRESS)
    args = parser.parse_args()
    source = args.source.resolve(strict=True)
    output = args.output.resolve()
    if source.suffix.lower() != ".fcstd" or output.suffix.lower() not in (".step", ".stp"):
        parser.error("Expected INPUT.FCStd OUTPUT.step (or .stp)")
    if args.worker_report:
        worker(source, output, args.worker_report)
        return
    log = output.with_suffix(".log")
    report = output.with_suffix(".validation.json")
    for path in (output, log, report):
        if path.exists():
            parser.error(f"Refusing to overwrite {path}")
    if not output.parent.is_dir():
        parser.error("Output directory must already exist")
    token = uuid.uuid4().hex
    pending = output.with_name(f".{output.stem}-{token}.pending.step")
    pending_report = output.with_name(f".{output.stem}-{token}.pending.json")
    try:
        with log.open("x") as stream:
            result = subprocess.run(
                [sys.executable, "-u", str(Path(__file__).resolve()),
                 str(source), str(pending), "--worker-report", str(pending_report)],
                stdout=stream, stderr=subprocess.STDOUT, check=False)
        if result.returncode:
            raise RuntimeError(
                f"STEP worker failed (exit {result.returncode}); see {log}. "
                "No STEP published; last checkpoint identifies the active operation.")
        # Exclusive atomic publication: never replace an existing user's model.
        os.link(pending_report, report)
        os.link(pending, output)
        print(f"Validated STEP: {output}\nReport: {report}\nLog: {log}")
    finally:
        pending.unlink(missing_ok=True)
        pending.with_suffix(".component.step").unlink(missing_ok=True)
        pending_report.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
