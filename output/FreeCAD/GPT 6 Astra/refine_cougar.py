"""Refine the existing native feature tree without rebuilding the shoe."""
import math
import os
import sys
import json

import FreeCAD as App
import Part
import Sketcher

V = App.Vector


def write_manifest(doc, filename):
    components = [obj for obj in doc.Objects if hasattr(obj, "RenderMaterial")]
    report = {
        "file": os.path.basename(filename),
        "components": len(components),
        "solid_count": sum(len(o.Shape.Solids) for o in components),
        "sketches": sum(o.TypeId == "Sketcher::SketchObject" for o in doc.Objects),
        "native_component_features": sum(o.TypeId != "Part::Feature" for o in components),
        "fixed_components": [o.Name for o in components if o.TypeId == "Part::Feature"],
        "limits": [
            "Reference last, support surfaces and conformal layer stocks remain fixed.",
            "Sole section edits do not automatically reshape the upper.",
            "Eyelets, bores and lace endpoints require coordinated adjustment.",
            "Bundled Draft supplies 3D paths; no external custom feature proxy is required."
        ]
    }
    with open(os.path.join(os.path.dirname(filename), "editable_manifest.json"), "w") as stream:
        json.dump(report, stream, indent=2)
    return report


def align_section(section, path):
    curve = path.Shape.Edges[0].Curve
    tangent = curve.tangent(curve.FirstParameter)[0]
    major = V(0, 0, 1).cross(tangent)
    if major.Length < .001:
        major = V(1, 0, 0)
    frame = section.Placement.Rotation.multiply(section.AttachmentOffset.Rotation.inverted())
    local = frame.inverted().multVec(major)
    section.AttachmentOffset = App.Placement(
        V(), App.Rotation(V(0, 0, 1), math.degrees(math.atan2(local.y, local.x))))


def component(doc, name, shape_object, reference, note):
    shape_object.Label = name.replace("_", " ")
    for prop, kind in [("RenderMaterial", "App::PropertyString"),
                       ("BaseColor", "App::PropertyColor"),
                       ("Roughness", "App::PropertyFloat")]:
        shape_object.addProperty(kind, prop, "Rendering")
        setattr(shape_object, prop, getattr(reference, prop))
    shape_object.addProperty("App::PropertyString", "EditInstructions", "Editing")
    shape_object.EditInstructions = note
    return shape_object


def projection(doc, name, base, direction, distance):
    obj = doc.addObject("Part::Extrusion", name)
    obj.Base, obj.DirMode, obj.Dir = base, "Custom", direction
    obj.LengthFwd, obj.Solid = distance, True
    return obj


def fit_laces(doc):
    support = Part.makeCompound([doc.Gusseted_padded_tongue.Shape,
                                 doc.Tongue_Lace_Keeper.Shape])
    sweeps = [o for o in doc.Objects
              if o.TypeId == "Part::Sweep" and o.Label.startswith("Lace cross")]
    layouts = {}
    for sweep in sweeps:
        path = sweep.Spine[0]
        path.Parameterization = 0
        a, b = path.Points[0], path.Points[-1]
        direction = V(b.x-a.x, b.y-a.y, 0)
        direction.normalize()
        major = V(0, 0, 1).cross(direction)
        section = sweep.Sections[0]
        points, supported = [], []
        for j in range(17):
            t = j/16
            point = a*(1-t)+b*t
            hits = support.section(
                Part.makeLine(V(point.x, point.y, 65), V(point.x, point.y, 160))).Vertexes
            if hits:
                hit = max(hits, key=lambda v: v.Point.z)
                face = min(support.Faces, key=lambda f: f.distToShape(hit)[0])
                u, v = face.Surface.parameter(hit.Point)
                normal = face.normalAt(u, v)
                if normal.z < 0:
                    normal = -normal
                if normal.z < .1:
                    raise ValueError("Lace support is too steep for a dorsal crossing")
                slope = -(normal.x*direction.x+normal.y*direction.y)/normal.z
                tangent = direction+V(0, 0, slope)
                tangent.normalize()
                minor = tangent.cross(major)
                radius = math.hypot(section.MajorRadius.Value*normal.dot(major),
                                    section.MinorRadius.Value*normal.dot(minor))
                edge_clearance = .45*(math.exp(-((t-.12)/.11)**2)
                                      +math.exp(-((t-.88)/.11)**2))
                point.z = hit.Point.z+(radius+.22)/normal.z+edge_clearance
                supported.append(j)
            elif .15 < t < .85:
                raise ValueError("Lace loses its tongue support: "+sweep.Label)
            points.append(point)
        # Rise before crossing the padded tongue edge, not through its sidewall.
        for j in range(1, supported[0]):
            points[j].z = points[supported[0]].z+.3
        for j in range(supported[-1]+1, 16):
            points[j].z = points[supported[-1]].z+.3
        points[0], points[-1] = V(a), V(b)
        first_lead, last_lead = a*.98+b*.02, a*.02+b*.98
        first_lead.z = max(points[1].z, points[2].z)+.8
        last_lead.z = max(points[-2].z, points[-3].z)+.8
        points = [points[0], first_lead]+points[1:-1]+[last_lead, points[-1]]
        fractions = [0, .02]+[j/16 for j in range(1, 16)]+[.98, 1]
        layouts[sweep.Name] = (points, [math.sin(math.pi*t)**2 for t in fractions])
        path.Points = [p+V(0, 0, 3*w if sweep.Label.endswith("over") else 0)
                       for p, w in zip(*layouts[sweep.Name])]
    doc.recompute()
    for sweep in sweeps:
        align_section(sweep.Sections[0], sweep.Spine[0])
    doc.recompute()
    for i in range(1, 5):
        over = next(s for s in sweeps if s.Label == "Lace cross %d over" % i)
        under = next(s for s in sweeps if s.Label == "Lace cross %d under" % i)
        low, high = 1.5, 4.5
        for iteration in range(9):
            lift = (low+high)/2
            over.Spine[0].Points = [p+V(0, 0, lift*w)
                                    for p, w in zip(*layouts[over.Name])]
            doc.recompute()
            align_section(over.Sections[0], over.Spine[0])
            doc.recompute()
            gap = over.Shape.distToShape(under.Shape)[0]
            if .08 <= gap <= .14:
                break
            if gap < .08:
                low = lift
            else:
                high = lift
        else:
            raise ValueError("Could not seat lace crossing %d without interference" % i)
    for sweep in sweeps:
        if sweep.Shape.common(doc.Gusseted_padded_tongue.Shape).Volume > .05:
            raise ValueError("Lace penetrates the padded tongue: "+sweep.Label)
    return sweeps


def refine(doc):
    if doc.getObject("Toe_Bumper_Section_00") is not None:
        raise ValueError("This document already has the refinement features.")
    updated = {}
    support = Part.makeCompound([
        doc.Continuous_sculpted_EVA_midsole.Shape,
        doc.carrier_Section_Loft.Shape,
        doc.Continuous_vamp_and_midfoot_mesh.Shape,
        doc.Wrapped_TPU_toe_guard.Shape])

    def front_x(y, z):
        hits = support.section(Part.makeLine(V(215, y, z), V(310, y, z))).Vertexes
        if not hits:
            raise ValueError("No front support at y=%g z=%g" % (y, z))
        return max(v.Point.x for v in hits)

    print("Fitting a broader, sketch-driven front rubber wrap", flush=True)
    old = doc.Orange_toe_climbing_bumper
    profiles = []
    stations = [(28, 34), (32, 34), (36, 32), (40, 27), (44, 22),
                (48, 18), (52, 15), (56, 12.5), (60, 10.5), (64, 9), (67, 8)]
    for i, (z, width) in enumerate(stations):
        points = [V(front_x(width * t, z)-.12, width * t, 0)
                  for t in [-1, -.75, -.5, -.25, 0, .25, .5, .75, 1]]
        inner = Part.BSplineCurve()
        inner.interpolate(Points=points, Parameters=[float(j) for j in range(len(points))])
        outer = inner.copy()
        outer.translate(V(3.0, 0, 0))
        outer.reverse()
        sk = doc.addObject("Sketcher::SketchObject", "Toe_Bumper_Section_%02d" % i)
        sk.Label = "Toe bumper section | Z = %g mm" % z
        sk.Placement.Base = V(0, 0, z)
        sk.addGeometry([inner, Part.LineSegment(points[-1], points[-1]+V(3.0, 0, 0)),
                        outer, Part.LineSegment(points[0]+V(3.0, 0, 0), points[0])], False)
        sk.addConstraint([Sketcher.Constraint("Coincident", j, 2, (j+1) % 4, 1)
                          for j in range(4)])
        profiles.append(sk)
    bumper = doc.addObject("Part::Loft", "Refined_Toe_Bumper")
    bumper.Sections, bumper.Solid, bumper.MaxDegree = profiles, True, 2
    component(doc, "Orange_toe_climbing_bumper", bumper, old,
              "Edit the horizontal section sketches. Keep paired inner/outer boundaries "
              "coherent and adjust neighboring sections together. Grips follow the outer face.")
    doc.Details.addObject(bumper)
    doc.removeObject(old.Name)
    updated["Orange_toe_climbing_bumper"] = bumper
    doc.recompute()
    if not bumper.Shape.isValid() or len(bumper.Shape.Solids) != 1:
        raise ValueError("The refined toe bumper did not form one valid solid")
    vertices = bumper.Shape.tessellate(.15)[0]
    if any(p.x > 296 or p.x < 260 or p.z < 27.5 or p.z > 67.5 for p in vertices):
        raise ValueError("The refined toe bumper escaped its fitted envelope")

    outer_faces = []
    for i, face in enumerate(bumper.Shape.Faces):
        u0, u1, v0, v1 = face.ParameterRange
        if face.normalAt((u0+u1)/2, (v0+v1)/2).x > .25 and face.Area > 100:
            outer_faces.append(i+1)
    if len(outer_faces) != 1:
        raise ValueError("Cannot uniquely identify the bumper's outer relief face")
    binder = doc.addObject("PartDesign::SubShapeBinder", "Toe_Grip_Support_Face")
    binder.Support = [(bumper, ["Face%d" % outer_faces[0]])]
    relief = projection(doc, "Toe_Grip_Relief_Stock", binder, V(1, 0, 0), 2.0)
    relief.LengthRev = .3
    doc.recompute()
    if not relief.Shape.isValid() or not relief.Shape.Solids:
        raise ValueError("Curved toe-grip relief stock failed")
    for side in [-1, 1]:
        for z, y in [(36, 24), (47, 11)]:
            name = "Toe_bumper_grip_%s_%s" % (str(side).replace("-", "_"), z)
            old = doc.getObject(name)
            mask = doc.addObject("Part::Box", name+"_Projection")
            mask.Length, mask.Width, mask.Height = 100, 5.2, 5.2
            rotation = App.Rotation(V(1, 0, 0), side*35)
            mask.Placement = App.Placement(
                V(215, side*y, z)-rotation.multVec(V(0, 2.6, 2.6)), rotation)
            grip = doc.addObject("Part::Common", name+"_Fitted")
            grip.Base, grip.Tool = relief, mask
            component(doc, name, grip, old,
                      "The rotated projection block trims relief extruded from the bumper's "
                      "outer face. Move the block to reposition this fitted traction pad.")
            doc.Details.addObject(grip)
            doc.removeObject(old.Name)
            updated[name] = grip

    print("Adding the tongue keeper and seating the lace crossings", flush=True)
    tongue = doc.Gusseted_padded_tongue
    keeper_sketch = doc.addObject("Sketcher::SketchObject", "Tongue_Keeper_Outline")
    corners = [V(110, -3, 0), V(136, -3, 0), V(136, 3, 0), V(110, 3, 0)]
    keeper_sketch.addGeometry([Part.LineSegment(a, b)
                              for a, b in zip(corners, corners[1:]+corners[:1])], False)
    keeper_sketch.addConstraint([Sketcher.Constraint("Coincident", i, 2, (i+1) % 4, 1)
                                for i in range(4)])
    keeper_stock = doc.addObject("Part::Offset", "Tongue_Keeper_Surface_Layer")
    keeper_stock.Source, keeper_stock.Value, keeper_stock.Fill = tongue.Source, .45, True
    keeper_mask = projection(doc, "Tongue_Keeper_Projection", keeper_sketch, V(0, 0, 1), 180)
    keeper = doc.addObject("Part::Common", "Tongue_Lace_Keeper")
    keeper.Base, keeper.Tool = keeper_stock, keeper_mask
    component(doc, "Tongue_lace_keeper", keeper, tongue,
              "Edit the XY outline sketch; the keeper follows the tongue support surface.")
    doc.Lacing.addObject(keeper)
    updated["Tongue_lace_keeper"] = keeper
    doc.recompute()
    fit_laces(doc)
    for obj in doc.Objects:
        if hasattr(obj, "RenderMaterial"):
            if (not obj.Shape.isValid() or not obj.Shape.Solids
                    or any(s.Volume <= 0 for s in obj.Shape.Solids)):
                raise ValueError("Refinement produced invalid geometry: "+obj.Name)
        if "Invalid" in obj.State:
            raise ValueError("Refinement feature error: "+obj.Name)
    for obj in updated.values():
        if "grip" in obj.Label:
            if obj.Shape.common(bumper.Shape).Volume <= .01:
                raise ValueError("Toe grip is not embedded in its bumper: "+obj.Label)
    return updated


if __name__ == "__main__":
    sys.path.append(App.getResourceDir()+"Mod/Draft")
    import Draft
    filename = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                            "cad", "Cougar_Trail_Editable.FCStd")
    doc = App.openDocument(filename)
    refine(doc)
    doc.recompute()
    doc.save()
    write_manifest(doc, filename)
    print("REFINED:", filename, flush=True)
