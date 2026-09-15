#!/usr/bin/env python3
"""Convert the per-part OpenSCAD meshes into one STEP with named solids, then
re-open the STEP and verify it.

Run with FreeCAD's interpreter (no GUI, own process):
  /Applications/FreeCAD.app/Contents/Resources/bin/freecadcmd stl_to_step.py

Note: OpenSCAD 2021.01 has no B-rep/STEP export, so the STEP produced here is a
faceted (triangulated) B-rep — the geometry is exact to the OpenSCAD meshes but
faces are planar, not NURBS. output/trail_shoe.scad remains the editable
master document.
"""
import os, json, sys, time

import FreeCAD as App
import Mesh, MeshPart, Part

HERE = os.path.dirname(os.path.abspath(__file__))
EXPORT = os.path.join(HERE, "export")
STEP = os.path.join(EXPORT, "trail_shoe.step")
REPORT = os.path.join(EXPORT, "trail_shoe.validation.json")

# part -> (material group, display colour)  — same placeholder colours as the .scad
PARTS = {
    "midsole":        ("Foam_Midsole",      (0.20, 0.55, 0.95)),
    "toe_cap":        ("Rubber_Outsole_Org",(1.00, 0.45, 0.25)),
    "lugs":           ("Rubber_Outsole",    (0.30, 0.34, 0.38)),
    "upper":          ("Mesh_Upper",        (0.10, 0.42, 0.52)),
    "tongue":         ("Mesh_Upper",        (0.10, 0.42, 0.52)),
    "collar":         ("Padded_Collar",     (0.12, 0.35, 0.45)),
    "lateral_cage":   ("TPU_Overlays",      (1.00, 0.42, 0.28)),
    "medial_chevron": ("TPU_Overlays",      (1.00, 0.42, 0.28)),
    "heel_strip":     ("TPU_Overlays",      (1.00, 0.42, 0.28)),
    "eyestay":        ("TPU_Overlays",      (1.00, 0.42, 0.28)),
    "laces":          ("Laces",             (0.15, 0.60, 0.60)),
    "logo":           ("Print_Logo",        (0.92, 0.94, 0.97)),
}


def mesh_to_solids(mesh, tol=0.05):
    """Mesh -> list of closed solids (one per connected component)."""
    solids = []
    for comp in mesh.getSeparateComponents():
        shape = Part.Shape()
        shape.makeShapeFromMesh(comp.Topology, tol)
        try:
            solid = Part.makeSolid(shape)
            if solid.Volume < 0:
                solid.reverse()
        except Exception:
            solid = shape
        solids.append(solid)
    return solids


def build():
    doc = App.newDocument("trail_shoe")
    groups = {}
    summary = {}
    for part, (group, colour) in PARTS.items():
        path = os.path.join(EXPORT, part + ".stl")
        if not os.path.exists(path):
            summary[part] = {"status": "missing mesh"}
            continue
        t0 = time.time()
        mesh = Mesh.Mesh(path)
        solids = mesh_to_solids(mesh)
        if group not in groups:
            groups[group] = doc.addObject("App::DocumentObjectGroup", group)
        # keep one object per part (compound if it has several bodies), named
        shape = Part.makeCompound(solids) if len(solids) > 1 else solids[0]
        obj = doc.addObject("Part::Feature", part)
        obj.Shape = shape
        groups[group].addObject(obj)
        summary[part] = {
            "status": "ok",
            "group": group,
            "solids": len(solids),
            "closed": all(s.isClosed() for s in solids),
            "valid": all(s.isValid() for s in solids),
            "volume_mm3": round(sum(s.Volume for s in solids), 1),
            "bbox": [round(v, 2) for v in (shape.BoundBox.XMin, shape.BoundBox.YMin, shape.BoundBox.ZMin,
                                            shape.BoundBox.XMax, shape.BoundBox.YMax, shape.BoundBox.ZMax)],
            "seconds": round(time.time() - t0, 1),
        }
        print(f"  {part:15s} solids={len(solids):3d} closed={summary[part]['closed']} vol={summary[part]['volume_mm3']}")
    doc.recompute()
    # Import.export (not Part.export) writes one named PRODUCT per object and
    # keeps the group hierarchy as assembly nodes
    import Import
    Import.export([groups[g] for g in groups], STEP)
    doc.saveAs(os.path.join(EXPORT, "trail_shoe.FCStd"))
    return summary


def verify(summary):
    """Re-open the STEP and compare names, solid counts and geometry."""
    shape = Part.Shape()
    shape.read(STEP)
    result = {"step_file": STEP, "solids_in_step": len(shape.Solids),
              "all_closed": all(s.isClosed() for s in shape.Solids),
              "parts": {}}
    # names are recovered through Part.Feature import of the STEP
    doc2 = App.newDocument("verify")
    import Import
    Import.insert(STEP, doc2.Name)
    names = {}
    for o in doc2.Objects:
        # compounds re-import as a parent plus one child per solid; count leaves only
        if hasattr(o, "Shape") and o.Shape.Solids and not o.OutList:
            names[o.Label] = o
    expected_solids = 0
    for part, info in summary.items():
        if info.get("status") != "ok":
            result["parts"][part] = info
            continue
        expected_solids += info["solids"]
        match = [n for n in names if n == part or n.startswith(part)]
        res = {"name_preserved": bool(match)}
        if match:
            # multi-body parts re-import as part, part001, ... -> aggregate
            shapes = [names[n].Shape for n in match]
            sols = [s for sh in shapes for s in sh.Solids]
            vol = sum(s.Volume for s in sols)
            res["solids"] = len(sols)
            res["closed"] = all(s.isClosed() for s in sols)
            res["volume_mm3"] = round(vol, 1)
            res["volume_match"] = abs(vol - info["volume_mm3"]) < 0.005 * max(info["volume_mm3"], 1)
        result["parts"][part] = res
    result["expected_solids"] = expected_solids
    result["solid_count_match"] = expected_solids == result["solids_in_step"]
    result["names_preserved"] = all(p.get("name_preserved", False) for p in result["parts"].values()
                                    if "name_preserved" in p)
    return result


def main():
    print("building STEP from meshes ...")
    summary = build()
    print("verifying", STEP)
    result = verify(summary)
    result["source_meshes"] = summary
    with open(REPORT, "w") as f:
        json.dump(result, f, indent=2)
    print(json.dumps({k: v for k, v in result.items() if k != "source_meshes" and k != "parts"}, indent=2))
    for p, r in result["parts"].items():
        print(f"  {p:15s} {r}")
    ok = (result["solid_count_match"] and result["names_preserved"] and result["all_closed"]
          and all(r.get("volume_match", False) for r in result["parts"].values() if "volume_match" in r))
    print("VERIFICATION", "PASSED" if ok else "FAILED")
    return ok


# freecadcmd exec()s scripts with __name__ != "__main__", so run unconditionally
_ok = main()
sys.exit(0 if _ok else 1)
