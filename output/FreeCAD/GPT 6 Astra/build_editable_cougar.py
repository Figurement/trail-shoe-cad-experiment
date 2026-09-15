"""Build a standard-FreeCAD editing document, without external feature proxies."""
import math
import os
import runpy
import sys
import tempfile

import FreeCAD as App
import Part
import Sketcher
from refine_cougar import align_section, refine, write_manifest

sys.path.append(App.getResourceDir() + "Mod/Draft")
import Draft

ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ROOT, "cad")
V = App.Vector
os.environ["COUGAR_GEOMETRY_ONLY"] = "1"
with tempfile.TemporaryDirectory(prefix="cougar-reference-") as scratch:
    os.environ["COUGAR_OUTPUT_DIR"] = scratch
    source = runpy.run_path(os.path.join(ROOT, "build_cougar.py"))
os.environ.pop("COUGAR_OUTPUT_DIR")
os.environ.pop("COUGAR_GEOMETRY_ONLY")

recipe = source["edit_recipe"]
originals = {obj.Name: obj for obj in source["objects"]}
doc = App.newDocument("Cougar_Trail_Editable")
doc.Label = "Cougar Trail | editable design"
finished = {}
groups = {}
for key, label in [
        ("Upper", "01 | Upper and shared material boundary"),
        ("Lateral", "02 | Lateral panels - edit outline sketches"),
        ("Medial", "03 | Medial panels - edit outline sketches"),
        ("Sole", "04 | Sole - edit transverse section sketches"),
        ("Lacing", "05 | Facings, eyelets and laces"),
        ("Details", "06 | Collar, protection and remaining details"),
        ("Construction", "90 | FIXED reference surfaces and layer stocks")]:
    group = doc.addObject("App::DocumentObjectGroup", key)
    group.Label = label
    groups[key] = group

sheet = doc.addObject("Spreadsheet::Sheet", "Parameters")
sheet.Label = "00 | Driving dimensions - edit column B"
sheet.set("A1", "Parameter")
sheet.set("B1", "Value")
sheet.set("C1", "What changes")
for row, (alias, value, explanation) in enumerate([
        ("UpperWall", "1.25 mm", "Upper shell wall; panel stocks remain fixed"),
        ("BondMargin", "0.42 mm", "Exposed margin around projected side panels"),
        ("SeamHalfWidth", "1.05 mm", "Half-width of the shared quarter seam"),
        ("EyeletRadius", "2.1 mm", "Eyelet ring major radius"),
        ("EyeletWire", "0.55 mm", "Eyelet ring section radius"),
        ("EyeletBore", "2.2 mm", "Eyestay through-hole radius"),
        ("LaceHalfWidth", "1.8 mm", "Elliptical lace major radius"),
        ("LaceHalfHeight", "1.1 mm", "Elliptical lace minor radius"),
        ("LugHeight", "5.8 mm", "Traction lug height; top remains on carrier")
], 2):
    sheet.set("A%d" % row, alias)
    sheet.set("B%d" % row, value)
    sheet.setAlias("B%d" % row, alias)
    sheet.set("C%d" % row, explanation)
sheet.setColumnWidth("A", 155)
sheet.setColumnWidth("B", 95)
sheet.setColumnWidth("C", 430)


def instruction(obj, text):
    obj.addProperty("App::PropertyString", "EditInstructions", "Editing")
    obj.EditInstructions = text
    obj.setEditorMode("EditInstructions", 1)


def fixed(name, shape):
    obj = doc.addObject("Part::Feature", name)
    obj.Label = "FIXED | " + name.replace("_", " ")
    obj.Shape = shape.copy()
    instruction(obj, "Reference geometry, not sketch-driven. Replace the Shape or "
                "its consuming feature's Source to redesign this support surface.")
    groups["Construction"].addObject(obj)
    return obj


def finish(name, obj, group, text):
    old = originals[name]
    obj.Label = ("FIXED | " if obj.TypeId == "Part::Feature" else "") + old.Label
    for prop, kind in [("RenderMaterial", "App::PropertyString"),
                       ("BaseColor", "App::PropertyColor"),
                       ("Roughness", "App::PropertyFloat")]:
        obj.addProperty(kind, prop, "Rendering")
        setattr(obj, prop, getattr(old, prop))
    if "EditInstructions" not in obj.PropertiesList:
        instruction(obj, text)
    groups[group].addObject(obj)
    finished[name] = obj
    return obj


def sketch(name, face, placement=App.Placement()):
    local = face.copy()
    local.transformShape(placement.inverse().toMatrix())
    obj = doc.addObject("Sketcher::SketchObject", name)
    obj.Label = name.replace("_", " ")
    obj.Placement = placement
    geometries, constraints = [], []
    for wire in local.Wires:
        indices = []
        for edge in wire.OrderedEdges:
            curve = edge.toNurbs().Edges[0].Curve
            if isinstance(curve, Part.BezierCurve):
                curve = curve.toBSpline()
            curve.segment(edge.FirstParameter, edge.LastParameter)
            if edge.Orientation == "Reversed":
                curve.reverse()
            indices.append(len(geometries))
            geometries.append(curve)
        if len(indices) > 1:
            for a, b in zip(indices, indices[1:] + indices[:1]):
                constraints.append(Sketcher.Constraint("Coincident", a, 2, b, 1))
    obj.addGeometry(geometries, False)
    if constraints:
        obj.addConstraint(constraints)
    instruction(obj, "Double-click to edit. Joined spline endpoints are coincident. "
                "Use Sketcher Show internal geometry to expose spline control poles.")
    return obj


def extrude(name, base, direction, length):
    obj = doc.addObject("Part::Extrusion", name)
    obj.Base = base
    obj.DirMode = "Custom"
    obj.Dir = direction
    obj.LengthFwd = length
    obj.Solid = True
    return obj


def boolean(kind, name, base, tool):
    obj = doc.addObject("Part::" + kind, name)
    obj.Base, obj.Tool = base, tool
    return obj


def offset2d(name, base, value, expression=None):
    obj = doc.addObject("Part::Offset2D", name)
    obj.Source = base
    obj.Value = value
    obj.Mode = "Pipe"
    obj.Intersection = True
    if expression:
        obj.setExpression("Value", expression)
    return obj


def compound(name, links):
    obj = doc.addObject("Part::Compound", name)
    obj.Links = links
    return obj


stocks = {}


def stock(base, thickness):
    key = (base, thickness)
    if key not in stocks:
        stocks[key] = fixed("Layer_%s_%s" % key, source["panel_layer"](*key))
    return stocks[key]


XZ = App.Rotation(V(1, 0, 0), 90)
YZ = App.Rotation(V(1, 1, 1), 120)


def side_sketch(name, face, side):
    placed = face.copy()
    placed.translate(V(0, side * 90, 0))
    return sketch(name, placed, App.Placement(V(0, side * 90, 0), XZ))


def dorsal(name, face, base, thickness):
    placed = face.copy()
    placed.rotate(V(), V(1, 0, 0), -90)
    outline = sketch(name + "_Outline", placed)
    mask = extrude(name + "_Projection", outline, V(0, 0, 1), 185)
    return boolean("Common", name, stock(base, thickness), mask)


print("Converting upper, shared seam and side panels", flush=True)
upper_recipe = next(r for r in source["shape_recipes"].values()
                    if r["kind"] == "skin" and len(r["grid"]) == 97)
master = fixed("ReferenceLastSurface", source["surface"](
    upper_recipe["grid"], upper_recipe["parameters"]))
upper = doc.addObject("Part::Offset", "UpperWall")
upper.Source = master
upper.Value = 1.25
upper.Fill = True
upper.setExpression("Value", "Parameters.UpperWall")
opening = sketch("Collar_Opening_Outline",
                 Part.Face(Part.Wire(source["aperture_curve"].toShape())))
opening_tool = extrude("Collar_Opening_Cutter", opening, V(0, 0, 1), 170)
open_upper = boolean("Cut", "Upper_With_Opening", upper, opening_tool)
quarter = side_sketch("Shared_Quarter_Material_Boundary", source["quarter_boundary"], -1)
quarter_tool = extrude("Quarter_Region", quarter, V(0, 1, 0), 180)
finish("Heel_quarter_knit",
       boolean("Common", "Heel_quarter_knit", open_upper, quarter_tool), "Upper",
       "Edit Shared Quarter Material Boundary; both textile pieces and the seam update.")
finish("Continuous_vamp_and_midfoot_mesh",
       boolean("Cut", "Continuous_vamp_and_midfoot_mesh", open_upper, quarter_tool), "Upper",
       "Shares its seam sketch and upper-wall offset with the heel quarter.")
seam_outer = offset2d("Quarter_Seam_Outer", quarter, 1.05, "Parameters.SeamHalfWidth")
seam_inner = offset2d("Quarter_Seam_Inner", quarter, -1.05, "-Parameters.SeamHalfWidth")
seam_tool = boolean("Cut", "Quarter_Seam_Region",
                    extrude("Quarter_Seam_Outer_Prism", seam_outer, V(0, 1, 0), 180),
                    extrude("Quarter_Seam_Inner_Prism", seam_inner, V(0, 1, 0), 180))
for side, prefix in [(-1, "Lateral"), (1, "Medial")]:
    clip = doc.addObject("Part::Box", prefix + "_Half_Space")
    clip.Length, clip.Width, clip.Height = 400, 90, 200
    clip.Placement.Base = V(-30, -90 if side < 0 else 0, 0)
    half = boolean("Common", prefix + "_Seam_Projection", seam_tool, clip)
    name = prefix + "_quarter_material_join"
    finish(name, boolean("Common", name, stock(-.08, .6), half), "Upper",
           "Driven by the shared quarter boundary and Parameters.SeamHalfWidth.")

for r in recipe["panels"]:
    name, side = r["name"], r["side"]
    outline = side_sketch(name + "_Outline", r["face"], side)
    mask = extrude(name + "_Projection", outline, V(0, -side, 0), 90)
    group = "Lateral" if side < 0 else "Medial"
    finish(name, boolean("Common", name, stock(r["base"], r["thickness"]), mask),
           group, "Edit the Outline sketch; it drives the panel and its bonding flange. "
           "The supporting layer stock is fixed.")
    if r["weld"]:
        offset = offset2d(name + "_Flange_Offset", outline, .42, "Parameters.BondMargin")
        tool = extrude(name + "_Flange_Projection", offset, V(0, -side, 0), 90)
        flange = name + "_bonding_flange"
        finish(flange, boolean("Common", flange, stock(-.08, r["base"] + .30), tool),
               group, "Follows the panel Outline sketch and Parameters.BondMargin.")

print("Converting sole sections and traction blocks", flush=True)
stations = [-8, -7.5, -4, 0, 6, 15, 30, 45, 60, 78, 96, 114, 132, 150,
            171, 189, 207, 225, 240, 252, 264, 276, 282, 285, 288, 290, 291, 291.5, 291.8, 292]
sole_lofts = {}
for key, r in recipe["soles"].items():
    profiles = []
    indices = sorted({min(range(len(r["xs"])), key=lambda i: abs(r["xs"][i] - x))
                      for x in stations})
    for number, i in enumerate(indices):
        edges = []
        for poles in r["sections"][i]:
            c = Part.BezierCurve()
            c.setPoles(poles)
            edges.append(c.toShape())
        x = r["xs"][i]
        profile = sketch("%s_Section_%02d" % (key, number),
                         Part.Face(Part.Wire(edges)), App.Placement(V(x, 0, 0), YZ))
        profile.Label = "%s section | X = %g mm" % (key, x)
        profiles.append(profile)
    loft = doc.addObject("Part::Loft", key + "_Section_Loft")
    loft.Sections, loft.Solid, loft.Ruled, loft.MaxDegree = profiles, True, False, 2
    sole_lofts[key] = loft
shoulders = []
for name in ["Orange_sidewall_traction_shoulders", "Charcoal_sidewall_traction_shoulders"]:
    obj = fixed(name, originals[name].Shape)
    finish(name, obj, "Sole", "")
    shoulders.append(obj)
foam = boolean("Cut", "Continuous_sculpted_EVA_midsole", sole_lofts["midsole"],
               compound("Rubber_Shoulder_Pocket_Tools", shoulders))
finish("Continuous_sculpted_EVA_midsole", foam, "Sole",
       "Expand midsole Section Loft and double-click a transverse section. "
       "Section sketch Placement.X controls station position. Matching rubber pockets are cut last.")
finish("Continuous_rockered_rubber_carrier", sole_lofts["carrier"], "Sole",
       "Edit carrier section sketches. Adjust the matching foam sections and nearby lugs together.")
lug_groups = {"09_Orange_rubber": [], "08_Charcoal_rubber": []}
for i, r in enumerate(recipe["lugs"]):
    sections = []
    rotation = App.Rotation(V(0, 0, 1), math.degrees(r["angle"]))
    for label, scale, height in [("Footprint", .82, r["z"]), ("Seat", 1, r["z"] + 5.8)]:
        p = [V(a * scale, b * scale, 0) for a, b in r["coords"]]
        face = Part.Face(Part.makePolygon(p + [p[0]]))
        placement = App.Placement(V(r["x"], r["y"], height), rotation)
        face.transformShape(placement.toMatrix())
        sk = sketch("Lug_%03d_%s" % (i, label), face, placement)
        if label == "Footprint":
            sk.setExpression("Placement.Base.z", "%g mm - Parameters.LugHeight" % (r["z"] + 5.8))
        sections.append(sk)
    lug = doc.addObject("Part::Loft", "Lug_%03d" % i)
    lug.Sections, lug.Solid, lug.Ruled = sections, True, True
    lug_groups[r["material"]].append(lug)
for material, links in lug_groups.items():
    name = "Orange_traction_lugs" if "Orange" in material else "Charcoal_traction_lugs"
    finish(name, compound(name, links), "Sole",
           "Each lug has footprint and seat sketches. Parameters.LugHeight moves the bottom only.")

print("Converting eyestays, facings, eyelets and lace sweeps", flush=True)
for r in recipe["eyestays"]:
    name = r["name"]
    panel = dorsal(name + "_Base", r["face"], .68, .95)
    outline = doc.getObject(name + "_Base_Outline")
    inset = offset2d(name + "_Inset", outline, -.85)
    inset_tool = extrude(name + "_Inset_Projection", inset, V(0, 0, 1), 185)
    relief = boolean("Common", name + "_Molded_Relief", stock(1.51, .25), inset_tool)
    bores = []
    for i in r["indices"]:
        x, y = source["rows"][i], r["side"] * (27 if i < 3 else 25)
        hole = doc.addObject("Part::Cylinder", name + "_Bore_%d" % i)
        hole.Radius, hole.Height, hole.Placement.Base = 2.2, 100, V(x, y, 55)
        hole.setExpression("Radius", "Parameters.EyeletBore")
        bores.append(hole)
    if r["spare"]:
        hole = doc.addObject("Part::Cylinder", name + "_Spare_Bore")
        hole.Radius, hole.Height, hole.Placement.Base = 1.55, 100, V(89, r["side"] * 27, 55)
        bores.append(hole)
    tool = compound(name + "_Bores", bores)
    fused = doc.addObject("Part::MultiFuse", name)
    fused.Shapes = [boolean("Cut", name + "_Bored_Base", panel, tool),
                    boolean("Cut", name + "_Bored_Relief", relief, tool)]
    finish(name, fused, "Lacing", "Edit the Base Outline sketch. Native offset and bores follow it; "
           "bore positions and eyelet placements can be adjusted in Data.")

for (side, i), center in source["eye_centers"].items():
    name = ("Lateral" if side < 0 else "Medial") + "_eyelet_%02d" % (i + 1)
    torus = doc.addObject("Part::Torus", name)
    torus.Radius1, torus.Radius2 = 2.1, .55
    torus.Placement.Base = center - V(0, 0, 1)
    torus.setExpression("Radius1", "Parameters.EyeletRadius")
    torus.setExpression("Radius2", "Parameters.EyeletWire")
    finish(name, torus, "Lacing", "Edit Placement and driving ring dimensions; move its eyestay bore too.")

for name, r in recipe["features"].items():
    if name in finished:
        continue
    if r["kind"] == "dorsal":
        finish(name, dorsal(name, r["face"], r["base"], r["thickness"]), "Lacing",
               "Edit the Outline sketch. The curved supporting layer remains fixed.")
    elif r["kind"] == "skin":
        support = fixed(name + "_Support", source["surface"](r["grid"], r["parameters"]))
        feature = doc.addObject("Part::Offset", name)
        feature.Source, feature.Value, feature.Fill = support, r["thickness"], True
        finish(name, feature, "Details", "Value controls signed wall thickness. "
               "The support surface is explicitly fixed reference geometry.")
    elif r["kind"] == "pipe":
        sweeps = []
        for i, points in enumerate(r["paths"]):
            path = Draft.make_bspline(points, closed=False)
            path.Label = name.replace("_", " ") + " | edit 3D path"
            instruction(path, "Use Draft Edit to move 3D interpolation points, or edit Points in Data. "
                        "The attached section and sweep follow this path.")
            section = doc.addObject("Part::Ellipse" if r["minor_radius"] else "Part::Circle",
                                    name + "_Section_%d" % i)
            if r["minor_radius"]:
                section.MajorRadius, section.MinorRadius = r["radius"], r["minor_radius"]
                section.setExpression("MajorRadius", "Parameters.LaceHalfWidth")
                section.setExpression("MinorRadius", "Parameters.LaceHalfHeight")
            else:
                section.Radius = r["radius"]
            section.AttachmentSupport = (path, ["Edge1"])
            section.MapMode, section.MapPathParameter = "FrenetNB", 0
            doc.recompute()
            align_section(section, path)
            sweep = doc.addObject("Part::Sweep", name + "_Sweep_%d" % i)
            sweep.Sections, sweep.Spine, sweep.Solid = [section], (path, ["Edge1"]), True
            sweep.Frenet = False
            sweeps.append(sweep)
        result = sweeps[0] if len(sweeps) == 1 else compound(name, sweeps)
        finish(name, result, "Lacing", "Edit the bundled Draft 3D path and its attached section; "
               "the native Sweep recomputes without the build script.")

for name, old in originals.items():
    if name not in finished:
        obj = fixed(name, old.Shape)
        finish(name, obj, "Details", "")

finished.update(refine(doc))
doc.recompute()
errors = []
for name, obj in finished.items():
    shape = obj.Shape
    if shape.isNull() or not shape.isValid() or not shape.Solids or any(s.Volume <= 0 for s in shape.Solids):
        errors.append(name + ": invalid or non-positive solid")
for obj in doc.Objects:
    if "Invalid" in obj.State:
        errors.append(obj.Name + ": " + str(obj.State))
for key, loft in sole_lofts.items():
    vertices = loft.Shape.tessellate(.25)[0]
    if len(loft.Shape.Solids) != 1 or any(
            p.x < -8.5 or p.x > 292.5 or p.z < 3.5 or p.z > 55.5 for p in vertices):
        bounds = [(min(getattr(p, axis) for p in vertices),
                   max(getattr(p, axis) for p in vertices)) for axis in ["x", "y", "z"]]
        errors.append(key + ": loft escaped its intended reference envelope " + str(bounds))
if errors:
    if os.environ.get("COUGAR_DEBUG_FILE"):
        doc.saveAs(os.environ["COUGAR_DEBUG_FILE"])
    raise RuntimeError("\n".join(errors))

path = os.path.join(OUT, "Cougar_Trail_Editable.FCStd")
doc.recompute()
doc.saveAs(path)
App.closeDocument(doc.Name)
doc = App.openDocument(path)
for obj in doc.Objects:
    if obj.TypeId == "Part::Sweep":
        support = obj.Sections[0].AttachmentSupport
        if not support or support[0][0] != obj.Spine[0]:
            raise RuntimeError("Sweep attachment did not survive reopening: " + obj.Name)
report = write_manifest(doc, path)
print("EDITABLE COMPLETE:", path, report, flush=True)
