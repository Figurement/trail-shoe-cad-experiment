"""Reconstruct the Cougar concept in the installed FreeCAD/OCCT kernel.

Run with FreeCAD's Python, with Contents/Resources/lib on PYTHONPATH.
The companion FCMacro applies appearances and saves camera views; STEP is separate.
"""
import json
import math
import os
import struct

import FreeCAD as App
import Part
import MeshPart

ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("COUGAR_OUTPUT_DIR", os.path.join(ROOT, "cad"))
os.makedirs(OUT, exist_ok=True)
V = App.Vector
doc = App.newDocument("Cougar_Trail")
edit_recipe = {"panels": [], "soles": {}, "eyestays": [], "lugs": [], "features": {}}
shape_recipes = {}
materials = {
    "01_Engineered_mesh": ((0.025, 0.39, 0.48), 0.87),
    "02_Quarter_knit": ((0.015, 0.38, 0.58), 0.88),
    "03_Deep_teal_TPU": ((0.018, 0.24, 0.30), 0.48),
    "04_Coral_TPU": ((1.0, 0.245, 0.145), 0.43),
    "05_Obsidian_support": ((0.025, 0.055, 0.075), 0.39),
    "06_EVA_midsole": ((0.54, 0.64, 0.65), 0.76),
    "08_Charcoal_rubber": ((0.075, 0.115, 0.14), 0.86),
    "09_Orange_rubber": ((1.0, 0.19, 0.065), 0.78),
    "10_Collar_lining": ((0.012, 0.19, 0.25), 0.95),
    "11_Teal_laces": ((0.015, 0.48, 0.52), 0.85),
    "12_Lime_tracer": ((0.79, 0.94, 0.40), 0.77),
    "13_Silver_graphic": ((0.65, 0.82, 0.85), 0.4),
}
groups = {}
objects = []
for name in materials:
    g = doc.addObject("App::DocumentObjectGroup", name)
    g.Label = name.replace("_", " ")
    groups[name] = g

construction = doc.addObject("App::DocumentObjectGroup", "Construction")
construction.Label = "00 | Reference last and dimensions (hidden)"
params = doc.addObject("App::FeaturePython", "DesignParameters")
construction.addObject(params)
for name, value in [("NominalLength", 300), ("ForefootWidth", 120),
                    ("HeelStack", 45), ("ForefootStack", 29),
                    ("UpperThickness", 1.25), ("OverlayThickness", 0.85),
                    ("LaceDiameter", 3.0), ("LugDepth", 5.5)]:
    params.addProperty("App::PropertyLength", name, "Nominal dimensions")
    setattr(params, name, value)
params.addProperty("App::PropertyString", "DesignStatus")
params.DesignStatus = "Image-based visualization concept; inferred dimensions, not a fit-validated production last."
params.addProperty("App::PropertyString", "Axes")
params.Axes = "mm; X heel to toe, -Y lateral, +Y medial, Z up"


def log(text):
    print(text, flush=True)


def add(name, shape, mat, description="", explicit_nurbs=False):
    recipe = shape_recipes.get(id(shape))
    if recipe is not None and recipe["shape"] is shape:
        edit_recipe["features"][name] = recipe
    if explicit_nurbs:
        shape = shape.toNurbs()
    if shape.isNull() or not shape.isValid() or not shape.Solids:
        raise ValueError("Invalid shape: %s (valid=%s, solids=%s, faces=%s)" %
                         (name,shape.isValid(),len(shape.Solids),len(shape.Faces)))
    if any(s.Volume <= 0 for s in shape.Solids):
        raise ValueError("Non-positive solid volume: " + name)
    obj = doc.addObject("Part::Feature", name)
    obj.Label = name.replace("_", " ")
    obj.Shape = shape
    obj.addProperty("App::PropertyString", "RenderMaterial", "Rendering")
    obj.RenderMaterial = mat
    obj.addProperty("App::PropertyColor", "BaseColor", "Rendering")
    obj.BaseColor = materials[mat][0]
    obj.addProperty("App::PropertyFloat", "Roughness", "Rendering")
    obj.Roughness = materials[mat][1]
    obj.addProperty("App::PropertyString", "ConstructionNote", "Design")
    obj.ConstructionNote = description
    groups[mat].addObject(obj)
    objects.append(obj)
    return obj


def smooth(table, x):
    if x <= table[0][0]:
        return table[0][1]
    if x >= table[-1][0]:
        return table[-1][1]
    for i in range(len(table) - 1):
        a, b = table[i], table[i + 1]
        if a[0] <= x <= b[0]:
            p = table[max(0, i - 1)]
            n = table[min(len(table) - 1, i + 2)]
            t = (x - a[0]) / (b[0] - a[0])
            m0 = (b[1] - p[1]) / (b[0] - p[0])
            m1 = (n[1] - a[1]) / (n[0] - a[0])
            d = b[0] - a[0]
            return ((2*t**3-3*t*t+1)*a[1] + (t**3-2*t*t+t)*m0*d
                    + (-2*t**3+3*t*t)*b[1] + (t**3-t*t)*m1*d)


WIDTH = [(0, 1), (4, 17), (12, 29), (28, 36), (55, 39),
         (90, 38), (125, 42), (165, 50), (200, 53),
         (230, 50), (250, 43), (268, 36), (279, 28),
         (287, 20.5), (289, 14.7), (290, 10.5), (290.5, 7.46), (291, .6)]
BASE = [(0, 39), (30, 37), (80, 32), (150, 29), (205, 30),
        (245, 35), (270, 43), (283, 50), (291, 53.4)]
HEIGHT = [(0, 42), (8, 67), (25, 75), (48, 64), (72, 61),
          (98, 73), (120, 68), (145, 56), (175, 48),
          (205, 42), (235, 35), (260, 24), (279, 17), (287, 8), (291, 0.5)]
LAST_RISE = 1.18


def dome_power(x):
    return smooth([(0,.65),(75,.65),(100,.40),(180,.40),(220,.50),(291,.65)],x)


def upper(x, theta, offset=0):
    w = smooth(WIDTH, x)
    h = smooth(HEIGHT, x)*LAST_RISE
    return V(x, (w+offset)*math.cos(theta),
             smooth(BASE, x)+(h+offset)*max(0, math.sin(theta))**dome_power(x))


def top(x, y, offset=0):
    w = smooth(WIDTH, x)
    return V(x, y, smooth(BASE, x) + smooth(HEIGHT, x)*LAST_RISE
             * max(0.001, 1-(y/w)**2)**(dome_power(x)/2) + offset)


def surface(grid, x_parameters=None):
    s = Part.BSplineSurface()
    if x_parameters is None:
        s.interpolate(grid)
    else:
        columns = []
        for j in range(len(grid[0])):
            c = Part.BSplineCurve()
            c.interpolate(Points=[row[j] for row in grid],
                          Parameters=[float(x) for x in x_parameters])
            columns.append(c)
        rows = []
        for i in range(len(columns[0].getPoles())):
            c = Part.BSplineCurve()
            c.interpolate(Points=[column.getPoles()[i] for column in columns],
                          Parameters=[float(j) for j in range(len(columns))])
            rows.append(c)
        s.buildFromPolesMultsKnots(
            [row.getPoles() for row in rows],
            columns[0].getMultiplicities(),rows[0].getMultiplicities(),
            columns[0].getKnots(),rows[0].getKnots(),
            False,False,columns[0].Degree,rows[0].Degree)
    return s.toShape()


def skin(grid, thickness, x_parameters=None):
    f = surface(grid, x_parameters)
    sh = f.makeOffsetShape(thickness, 0.001, fill=True)
    if not sh.isValid() or not sh.Solids:
        raise ValueError("Surface offset failed")
    shape_recipes[id(sh)] = {"kind": "skin", "shape": sh, "grid": grid,
                             "thickness": thickness, "parameters": x_parameters}
    return sh


def spline(points, periodic=False):
    c = Part.BSplineCurve()
    c.interpolate(points, PeriodicFlag=periodic)
    return c


def pipe(points, radius, minor_radius=None):
    closed = (points[0]-points[-1]).Length < .001
    curve = spline(points[:-1] if closed else points, closed)
    if closed:
        quarters = []
        arcs = []
        for k in range(4):
            arc = [curve.value(curve.FirstParameter
                   +(curve.LastParameter-curve.FirstParameter)*(k+i/12)/4)
                   for i in range(13)]
            quarters.append(pipe(arc, radius, minor_radius))
            arcs.append(arc)
        result = Part.makeCompound(quarters)
        shape_recipes[id(result)] = {"kind": "pipe", "shape": result,
                                     "paths": arcs, "radius": radius, "minor_radius": minor_radius}
        return result
    if len(points) > 20 and not closed:
        curve = Part.BSplineCurve()
        curve.approximate(Points=points, DegMin=3, DegMax=3, Tolerance=.20)
    path = Part.Wire(curve.toShape())
    tangent = curve.tangent(curve.FirstParameter)[0]
    start = curve.value(curve.FirstParameter)
    if minor_radius is None:
        profile = Part.makeCircle(radius,start,tangent)
    else:
        major = V(0,0,1).cross(tangent)
        if major.Length < .001:
            major = V(1,0,0)
        major.normalize()
        ellipse = Part.Ellipse()
        ellipse.Center = start
        ellipse.Axis = tangent
        ellipse.XAxis = major
        ellipse.MajorRadius = radius
        ellipse.MinorRadius = minor_radius
        profile = ellipse.toShape()
    circle = Part.Wire([profile])
    result = path.makePipeShell([circle], True, False)
    shape_recipes[id(result)] = {"kind": "pipe", "shape": result,
                                 "paths": [points], "radius": radius, "minor_radius": minor_radius}
    return result


def cylinder_between(a, b, r):
    d = b-a
    return Part.makeCylinder(r, d.Length, a, d)


def sample_path(points, n=60):
    c = spline([V(*p) if not isinstance(p, V) else p for p in points])
    return [c.value(c.FirstParameter+(c.LastParameter-c.FirstParameter)*i/(n-1))
            for i in range(n)]


def side_point(x, z, side=-1, lift=0.8):
    q = max(0.01, min(0.99, (z-smooth(BASE, x))/smooth(HEIGHT, x)))
    height = smooth(BASE,x)+(z-smooth(BASE,x))*LAST_RISE
    return V(x, side*(smooth(WIDTH, x)*math.sqrt(1-q**(2/dome_power(x)))+lift), height)


def ribbon(name, points, width, mat, side=-1, lift=0.9, thickness=0.7):
    center = sample_path([(x, 0, z) for x, z in points], max(20, len(points)*7))
    grid = []
    for i, p in enumerate(center):
        d = center[min(i+1, len(center)-1)]-center[max(0, i-1)]
        normal = V(-d.z, 0, d.x)
        normal.normalize()
        grid.append([side_point(p.x+normal.x*t, p.z+normal.z*t, side, lift)
                     for t in [-width/2, -width/6, width/6, width/2]])
    return add(name, skin(grid, thickness if side < 0 else -thickness), mat)


def outline_face(points):
    """A closed, tangent-continuous cutting outline in the XZ projection plane."""
    pts = [V(x,0,z) for x,z in points]
    tangents, incoming, outgoing, sharp = [], [], [], []
    for i,p in enumerate(pts):
        a = p-pts[i-1]
        b = pts[(i+1)%len(pts)]-p
        a.normalize()
        b.normalize()
        tangent = a+b
        tangent.normalize()
        tangents.append(tangent)
        incoming.append(a)
        outgoing.append(b)
        sharp.append(a.dot(b) < math.cos(math.radians(42)))
    starts,ends = [],[]
    for i,p in enumerate(pts):
        r = min(.65,(p-pts[i-1]).Length*.18,(pts[(i+1)%len(pts)]-p).Length*.18)
        starts.append(p-incoming[i]*r if sharp[i] else p)
        ends.append(p+outgoing[i]*r if sharp[i] else p)
    edges = []
    for i,p in enumerate(pts):
        j = (i+1)%len(pts)
        if sharp[i]:
            corner = Part.BSplineCurve()
            corner.buildFromPolesMultsKnots(
                [starts[i],starts[i]+(p-starts[i])*2/3,
                 ends[i]+(p-ends[i])*2/3,ends[i]],[4,4],[0.,1.],False,3)
            edges.append(corner.toShape())
        p = ends[i]
        q = starts[j]
        length = (q-p).Length
        before = (pts[i]-pts[i-1]).Length
        after = (pts[(j+1)%len(pts)]-pts[j]).Length
        start_tangent = outgoing[i] if sharp[i] else tangents[i]
        end_tangent = incoming[j] if sharp[j] else tangents[j]
        curve = Part.BSplineCurve()
        curve.buildFromPolesMultsKnots(
            [p,p+start_tangent*min(length,before)*.28,
             q-end_tangent*min(length,after)*.28,q],
            [4,4],[0.,1.],False,3)
        edges.append(curve.toShape())
    face = Part.Face(Part.Wire(edges))
    if not face.isValid():
        raise ValueError("Invalid projected panel outline")
    return face


def reference_outline(points):
    return [((x-410)*.232,(855-y)*.23-4) for x,y in points]


def medial_reference_outline(points):
    return [((1410-x)*.363,(807-y)*.32) for x,y in points]


panel_layers = {}


def panel_layer(base, thickness):
    key = (base,thickness)
    if key not in panel_layers:
        xs = [6+241*i/64 for i in range(65)]
        inner = surface([[upper(x,math.pi*j/32,base) for j in range(33)]
                         for x in xs],xs)
        outer = surface([[upper(x,math.pi*j/32,base+thickness) for j in range(33)]
                         for x in xs],xs)
        faces = [inner]
        # Matching explicit skins avoid approximate offset surfaces at trimmed joins.
        for a,b in zip(inner.Edges,outer.Edges):
            wall = Part.makeRuledSurface(a,b)
            u0,u1,v0,v1 = wall.ParameterRange
            normal = wall.normalAt((u0+u1)/2,(v0+v1)/2)
            if a.BoundBox.XLength < .00001:
                direction = -1 if a.CenterOfMass.x < 100 else 1
                if normal.x*direction < 0:
                    wall.reverse()
            elif normal.z > 0:
                wall.reverse()
            faces.append(wall)
        outer.reverse()
        faces.append(outer)
        layer = Part.makeSolid(Part.makeShell(faces))
        if not layer.isValid() or layer.Volume <= 0:
            raise ValueError("Invalid NURBS panel stock")
        panel_layers[key] = layer
    return panel_layers[key]


def panel_prism(face, side):
    face = face.copy()
    face.translate(V(0,side*90,0))
    return face.extrude(V(0,-side*90,0))


def projected_panel(name, points, mat, side=-1, base=.02, thickness=.65,
                    windows=(), weld=True, lobes=()):
    face = outline_face(points)
    for lobe in lobes:
        face = face.fuse(outline_face(lobe))
    for window in windows:
        face = face.cut(outline_face(window))
    if weld:
        offset_faces = [f.makeOffset2D(.42) for f in face.Faces]
        flange = offset_faces[0]
        for extra in offset_faces[1:]:
            flange = flange.fuse(extra)
        bond = panel_layer(-.08,base+.30).common(panel_prism(flange,side))
        add(name+"_bonding_flange",bond,"03_Deep_teal_TPU",
            "0.42 mm exposed bonded flange; embedded in the textile shell.",explicit_nurbs=True)
    shape = panel_layer(base,thickness).common(panel_prism(face,side))
    obj = add(name,shape,mat,"Projected closed boundary, not a constant-width surface ribbon.")
    obj.addProperty("App::PropertyLength","PanelThickness","Join detail")
    obj.PanelThickness = thickness
    obj.addProperty("App::PropertyString","JoinType","Join detail")
    obj.JoinType = "Bonded overlap with shared, projected boundary"
    edit_recipe["panels"].append({"name": name, "points": points, "windows": windows,
                                  "lobes": lobes, "face": face, "base": base,
                                  "thickness": thickness, "side": side, "weld": weld})
    return obj


def dorsal_patch(face, base, thickness):
    mask = face.copy()
    mask.rotate(V(0,0,0),V(1,0,0),-90)
    result = panel_layer(base,thickness).common(mask.extrude(V(0,0,185)))
    shape_recipes[id(result)] = {"kind": "dorsal", "shape": result, "face": face.copy(),
                                 "base": base, "thickness": thickness}
    return result


log("Building reconstructed last and upper shell")
last_xs = [0.5+290*i/64 for i in range(65)]
last_face = surface([[upper(x, math.pi*j/24) for j in range(25)]
                     for x in last_xs], last_xs)
master = doc.addObject("Part::Feature", "ReferenceLastSurface")
master.Label = "Reconstructed last | master NURBS upper surface"
master.Shape = last_face
construction.addObject(master)

# The aperture is a real cut through the shell, not a black patch.
aperture_curve = spline([V(49+38*math.cos(t), 25*math.sin(t), 0)
                         for t in [2*math.pi*i/80 for i in range(80)]], True)
aperture = Part.Face(Part.Wire(aperture_curve.toShape())).extrude(V(0, 0, 170))
xs = [.5+290*i/96 for i in range(97)]
upper_shell = skin([[upper(x,math.pi*j/32) for j in range(33)] for x in xs],1.25,xs)
upper_shell = upper_shell.cut(aperture)
quarter_boundary = outline_face([(-25,0),(28,0),(41,44),(63,75),(98,109),
                                  (127,147),(133,185),(-25,185)])
quarter_mask = quarter_boundary.copy()
quarter_mask.translate(V(0,-85,0))
quarter_mask = quarter_mask.extrude(V(0,170,0))
add("Heel_quarter_knit",upper_shell.common(quarter_mask),"02_Quarter_knit",
    "Curved diagonal material transition shared exactly with the adjacent textile panel.")
add("Continuous_vamp_and_midfoot_mesh",upper_shell.cut(quarter_mask),"01_Engineered_mesh",
    "Unperforated textile shell; no arbitrary transverse material seam.")
seam_mask = quarter_boundary.makeOffset2D(1.05).cut(quarter_boundary.makeOffset2D(-1.05))
for side,prefix in [(-1,"Lateral"),(1,"Medial")]:
    seam = panel_layer(-.08,.6).common(panel_prism(seam_mask,side))
    add(prefix+"_quarter_material_join",seam,"03_Deep_teal_TPU",
        "2.1 mm bonded seam tape following the exact shared textile boundary.",explicit_nurbs=True)

collar_sections, collar_quarters = [], []
def collar_point(t):
    return top(49+38*math.cos(t),25*math.sin(t),.6)
for quadrant in range(4):
    profiles = []
    frames = []
    for i in range(13):
        t = math.pi/2*(quadrant+i/12)
        center = collar_point(t)
        tangent = collar_point(t+.0001)-collar_point(t-.0001)
        tangent.normalize()
        radial = V(0,0,1).cross(tangent)
        radial.normalize()
        radius = 2.8+.9*(1-math.cos(t))
        circle = Part.Circle(center,tangent,radius)
        circle.XAxis = radial
        profiles.append(Part.Wire(circle.toShape()))
        frames.append((center,tangent,radial,radius))
    collar_quarters.append(Part.makeLoft(profiles,True,False,False,3))
    collar_sections.append(frames)
add("Padded_collar_binding",Part.makeCompound(collar_quarters),"01_Engineered_mesh",
    "Continuous padding is fuller at the heel and tapers toward the throat.")
edit_recipe["collar_sections"] = collar_sections
liner_panels = []
for quadrant in range(4):
    ts = [math.pi/2*(quadrant+i/16) for i in range(17)]
    grid = []
    for t in ts:
        p = top(49+37.8*math.cos(t),24.8*math.sin(t),-.8)
        grid.append([V(p.x,p.y,p.z-d) for d in [0,4,10,18]])
    liner_panels.append(skin(grid,1.0,ts))
add("Deep_padded_collar_lining",Part.makeCompound(liner_panels),"10_Collar_lining",
    "Four adjoining lining quadrants avoid a degenerate closed-surface seam.")
insole_curve = spline([V(49+35*math.cos(t), 22*math.sin(t), 67)
                       for t in [2*math.pi*i/64 for i in range(64)]], True)
add("Visible_internal_sockliner",
    Part.Face(Part.Wire(insole_curve.toShape())).extrude(V(0,0,2)), "10_Collar_lining")

log("Building sculpted foam tooling")
SOLE_W = [(-8,1),(-7.5,9.4),(-7,13.2),(-3,27.6),(0,32.9),(8,38),
          (30,47),(60,47),(95,44),(130,48),(170,57),(208,59),(240,54),
          (265,41),(282,24),(285,22.9),(288,19.2),(290,14.4),
          (291,10.46),(291.5,7.49),(291.8,4.78),(291.9,3.39),(291.96,2.14),(292,1)]
BOTTOM = [(-8,19),(0,12),(28,8),(65,7),(110,7.5),(180,8),
          (213,10),(245,18),(270,28),(285,38),(292,43)]
TOPSOLE = [(-8,46),(0,47),(30,46),(55,42),(90,36),(125,32),
           (155,31),(190,32),(222,35),(252,42),(278,50),(292,54)]


def sole_shape(rubber=False):
    wires, sections = [], []
    xs = [-8,-7.8,-7.5,-7,-6,-4,-2,0] + list(range(3,289,3)) + [
        289,290,291,291.5,291.8,291.9,291.96,292]
    for x in xs:
        w = smooth(SOLE_W, x)
        bottom = smooth(BOTTOM, x)
        height = smooth(TOPSOLE, x)-bottom
        flare = 1.01+.025*math.exp(-((x-35)/65)**2)
        wb = w*flare
        tip = min(1.,w/12)
        if rubber:
            bottom -= 2.2
            height = 2.2
            r = min(.65,w*.2)
            right = [
                [(wb-2*tip,bottom),(wb-.9*tip,bottom),(wb,bottom+.45*r),(wb,bottom+r)],
                [(wb,bottom+r),(wb,bottom+height),(wb-.9*tip,bottom+height),
                 (wb-2*tip,bottom+height)]]
            seat = bottom+height
            ws = wb-2*tip
            floor_w = wb-2*tip
        else:
            zt = smooth(TOPSOLE,x)
            fraction = smooth([(-8,.65),(0,.72),(50,.67),(100,.45),(145,.30),
                               (195,.49),(240,.60),(292,.36)],x)
            zc = bottom+height*fraction
            wl = .975*w
            depth = (1.2+3.1*math.exp(-((x-125)/75)**2))*tip
            wg = wl-depth
            ws = min(.82*w,wl-2.2*tip)
            seat = max(bottom+2.0,min(smooth(BASE,x)-.35,zt-1.0))
            toe_close = smooth([(0,0),(266,0),(283,.65),(292,1)],x)
            heel_close = smooth([(-8,1),(0,.8),(12,0),(292,0)],x)
            close = max(0,min(1,max(toe_close,heel_close)))
            seat = seat*(1-close)+(zt-.2)*close
            floor_w = wb-3.0*tip
            r = min(3.5,height*.14)
            rise = min(3.5,(zt-zc)*.44)
            right = [
                [(floor_w,bottom),(wb-1.0*tip,bottom),(wb,bottom+1.0),(wb,bottom+r)],
                [(wb,bottom+r),(wb+.45*tip,bottom+r+2.0),
                 (wg+2.0*tip,zc-2.2),(wg,zc-.4)],
                [(wg,zc-.4),(wg-.65*tip,zc+.2),
                 (wl-.9*tip,zc+rise-1.0),(wl,zc+rise)],
                [(wl,zc+rise),(wl+.6*tip,zc+rise+.667),
                 (wl+.2*tip,zt-1.0),(wl-1.5*tip,zt)],
                [(wl-1.5*tip,zt),(wl-2.18*tip,zt+.4),
                 (ws+1.0*tip,seat),(ws,seat)]]
        row = [[V(x,-floor_w,bottom),V(x,floor_w,bottom)]]
        row.extend([[V(x,y,z) for y,z in curve] for curve in right])
        row.append([V(x,ws,seat),V(x,-ws,seat)])
        row.extend([[V(x,-y,z) for y,z in reversed(curve)] for curve in reversed(right)])
        edges = []
        for poles in row:
            curve = Part.BezierCurve()
            curve.setPoles(poles)
            edges.append(curve.toShape())
        wires.append(Part.Wire(edges))
        sections.append(row)
    faces = []
    # Shared X parameters keep the sculpted profile coherent at the heel and toe.
    for span in range(len(sections[0])):
        curves = []
        for column in range(len(sections[0][span])):
            curve = Part.BSplineCurve()
            curve.interpolate(Points=[row[span][column] for row in sections],
                              Parameters=[float(x) for x in xs])
            curves.append(curve)
        curve_poles = [curve.getPoles() for curve in curves]
        poles = [[column[i] for column in curve_poles] for i in range(len(curve_poles[0]))]
        degree_v = len(sections[0][span])-1
        s = Part.BSplineSurface()
        s.buildFromPolesMultsKnots(
            poles, curves[0].getMultiplicities(), [degree_v+1,degree_v+1],
            curves[0].getKnots(), [0.,1.], False,False,curves[0].Degree,degree_v)
        face = s.toShape()
        face.reverse()
        faces.append(face)
    heel_cap = Part.Face(wires[0])
    heel_cap.reverse()
    faces.extend([heel_cap,Part.Face(wires[-1])])
    result = Part.makeSolid(Part.makeShell(faces))
    edit_recipe["soles"]["carrier" if rubber else "midsole"] = {
        "xs": xs, "sections": sections, "shape": result}
    return result


foam = sole_shape()
if not foam.isValid():
    raise ValueError("Invalid sculpted foam tooling")
foam_feature = add("Continuous_sculpted_EVA_midsole", foam, "06_EVA_midsole",
    "One continuous solid: flared heel, concave waist, rolled lasting lip and toe rocker.")

outsole = sole_shape(True)
add("Continuous_rockered_rubber_carrier", outsole, "08_Charcoal_rubber")

log("Building multidirectional outsole lugs")
lug_sets = {"08_Charcoal_rubber": [], "09_Orange_rubber": []}
for row, x in enumerate(range(6, 282, 17)):
    w = smooth(SOLE_W, x)
    for col, frac in enumerate([-.86, -.44, 0, .44, .86]):
        y = frac*w
        z = smooth(BOTTOM, x)-7.8
        # Chevron blocks have tapered walls and a cut flex notch.
        length, breadth = (12.0, 12.0 if abs(frac)<.8 else 11.0)
        coords = [(-length/2,-breadth/2), (length/2-2,-breadth/2),
                  (length/2,0), (length/2-2,breadth/2),
                  (-length/2,breadth/2), (-length/2+2,0)]
        ang = (-.27 if col%2 else .27)*(1 if row<9 else -1)
        def lugwire(scale, zz):
            pts = [V(x+scale*(a*math.cos(ang)-b*math.sin(ang)),
                     y+scale*(a*math.sin(ang)+b*math.cos(ang)), zz) for a,b in coords]
            return Part.makePolygon(pts+[pts[0]])
        lug = Part.makeLoft([lugwire(.82,z), lugwire(1,z+5.8)], True, True)
        mat = "09_Orange_rubber" if (row+col)%4 == 0 or (row>11 and col%2 == 1) else "08_Charcoal_rubber"
        lug_sets[mat].append(lug)
        edit_recipe["lugs"].append({"x": x, "y": y, "z": z, "angle": ang,
                                    "coords": coords, "material": mat})
for mat, shapes in lug_sets.items():
    add("Orange_traction_lugs" if "Orange" in mat else "Charcoal_traction_lugs",
        Part.makeCompound(shapes), mat, "5.8 mm chevron traction blocks; tapered sidewalls.")
shoulder_sets = {"08_Charcoal_rubber":[],"09_Orange_rubber":[]}
for row,x in enumerate([12,36,62,89,117,146,176,206,234,260,276]):
    for side in [-1,1]:
        width = smooth(SOLE_W,x)*(1.01+.025*math.exp(-((x-35)/65)**2))
        def shoulder_width(xx):
            return smooth(SOLE_W,xx)*(1.01+.025*math.exp(-((xx-35)/65)**2))
        dw = (shoulder_width(x+.01)-shoulder_width(x-.01))/.02
        dz = (smooth(BOTTOM,x+.01)-smooth(BOTTOM,x-.01))/.02
        contour = [(-7,-3.5),(7,-3.5),(7,1),(2,5),(-3,6),(-7,2)]
        polygon = [V(x+dx,side*(width-1.4+dw*dx),smooth(BOTTOM,x)+dz*dx+h)
                   for dx,h in contour]
        face = Part.Face(Part.makePolygon(polygon+[polygon[0]]))
        normal = V(-dw,side,0)
        normal.normalize()
        shoulder = face.extrude(normal*3)
        shoulder = shoulder.makeFillet(.35,shoulder.Edges)
        mat = "09_Orange_rubber" if (row+(side>0))%3 == 0 else "08_Charcoal_rubber"
        shoulder_sets[mat].append(shoulder)
for mat,shapes in shoulder_sets.items():
    add("Orange_sidewall_traction_shoulders" if "Orange" in mat else "Charcoal_sidewall_traction_shoulders",
        Part.makeCompound(shapes),mat,"Wraparound rubber inserts rising into matching EVA pockets.")
foam_feature.Shape = foam_feature.Shape.cut(
    Part.makeCompound([s for shapes in shoulder_sets.values() for s in shapes]))
if not foam_feature.Shape.isValid() or len(foam_feature.Shape.Solids) != 1:
    raise ValueError("Invalid EVA/rubber shoulder interface")

log("Building bonded overlays and asymmetric support cage")
frame_outline = reference_outline([
    (460,407),(549,432),(663,454),(702,447),(817,385),(854,369),
    (890,379),(973,398),(1058,437),(1152,473),(1236,490),(1253,511),
    (1156,545),(1081,589),(1020,645),(982,681),(888,665),(819,641),
    (751,619),(675,594),(607,569),(529,546),(474,513)])
frame_windows = [reference_outline(p) for p in [
    [(746,457),(804,423),(866,404),(936,408),(946,423),(901,449),(837,479),(793,482)],
    [(900,476),(958,446),(1017,450),(1112,475),(1133,491),(1094,515),(1048,538),(1005,526)],
    [(1057,552),(1112,522),(1190,509),(1211,516),(1163,551),(1118,579)],
    [(760,531),(825,542),(893,573),(934,612),(945,645),(871,623),(808,590)]]]
projected_panel("Lateral_windowed_TPU_quarter_frame",frame_outline,"03_Deep_teal_TPU",
                windows=frame_windows)
projected_panel("Medial_windowed_TPU_quarter_frame",
                medial_reference_outline([
                    (813,582),(854,565),(888,547),(927,532),(981,514),
                    (1027,498),(1080,487),(1104,507),(1061,522),
                    (1130,559),(1199,577),(1235,577),(1290,558),(1347,531),
                    (1340,575),(1306,621),(1265,651),(1291,664),
                    (1351,672),(1358,681),(1268,687),(1152,700),
                    (1054,711),(982,721),(936,724),(928,708),
                    (944,682),(972,647),(976,630),(941,610),(900,591),(849,602)]),
                "03_Deep_teal_TPU",side=1,windows=[
                    medial_reference_outline([
                        (886,568),(929,550),(1041,588),(1051,602),
                        (1011,657),(975,697),(963,697),(999,639),(951,612)]),
                    medial_reference_outline([
                        (1007,529),(1055,545),(1127,582),(1174,612),(1167,629),
                        (1099,665),(1027,695),(985,709),(1057,633),(1073,609)])])

black_arch = reference_outline([
    (494,432),(677,478),(836,504),(931,533),(1004,576),(1069,691),
    (1005,680),(975,621),(940,581),(893,550),(815,525),(689,497),(588,470),(502,451)])
projected_panel("Lateral_tapered_structural_arch",black_arch,"05_Obsidian_support",
                base=.50,thickness=.90)
wing = reference_outline([
    (460,411),(531,428),(610,446),(690,457),(790,474),(900,491),
    (1010,518),(1060,546),(1100,584),(1140,641),(1181,699),
    (1158,700),(1123,646),(1080,588),(1040,554),(989,532),(895,510),
    (786,492),(680,475),(575,457),(480,451)])
projected_panel("Lateral_swept_coral_perimeter",wing,"04_Coral_TPU",
                base=1.12,thickness=.80)
heel_inlay = reference_outline([
    (489,506),(521,516),(597,548),(674,601),(714,636),(622,625),
    (498,625),(456,625),(501,604),(532,579),(513,548)])
projected_panel("Lateral_rear_structural_inlay",heel_inlay,"05_Obsidian_support",
                base=.20,thickness=.90)
return_outline = reference_outline([
    (482,484),(515,492),(615,522),(723,540),(806,573),(853,600),
    (862,621),(835,654),(814,649),(770,621),(722,588),(683,563),
    (660,546),(655,538),(612,526),(565,511),(514,495)])
return_window = reference_outline([
    (691,543),(730,549),(785,574),(818,598),(816,611),
    (801,629),(785,625),(744,598),(702,572),(684,556)])
hook = reference_outline([
    (479,486),(500,497),(542,549),(551,571),(541,590),(501,615),
    (481,627),(454,626),(475,611),(525,578),(529,570),(514,548),(485,514)])
projected_panel("Lateral_sculpted_coral_return",return_outline,"04_Coral_TPU",
                base=.95,thickness=.80,windows=[return_window],lobes=[hook])
projected_panel("Medial_heel_chevron_border",
                medial_reference_outline([
                    (1133,674),(1235,611),(1299,577),(1325,572),
                    (1327,581),(1281,633),(1288,642),(1345,671)]),
                "04_Coral_TPU",side=1,base=.60,thickness=.80)
projected_panel("Medial_heel_counter_inlay",
                medial_reference_outline([
                    (1155,669),(1239,619),(1302,585),(1316,580),
                    (1274,630),(1275,642),(1324,665)]),
                "05_Obsidian_support",side=1,base=.95,thickness=.55,weld=False)
for side, prefix in [(-1,"Lateral"),(1,"Medial")]:
    ribbon(prefix+"_lime_heel_reflector", [(6,57),(12,63),(16,74)],
           1.6, "12_Lime_tracer", side, 2.1, .35)

toe_grid, toe_bond_grid, toe_angles = [], [], []
for i in range(49):
    theta = .06+(math.pi-.12)*i/48
    toe_angles.append(theta)
    xa = (234+29*math.sin(theta)
          -32*math.exp(-((theta-2.50)/.28)**2)
          -25*math.exp(-((theta-.64)/.28)**2))
    toe_grid.append([upper(xa+(290.2-xa)*j/12,theta,.35) for j in range(13)])
    toe_bond_grid.append([upper(xa-1.0+(290.45-xa+1.0)*j/12,theta,-.03) for j in range(13)])
add("Toe_guard_bonding_land",skin(toe_bond_grid,.55,toe_angles),"03_Deep_teal_TPU",
    "Exposed 1 mm bonded edge follows both asymmetric toe-guard wings.")
toe_guard_feature = add("Wrapped_TPU_toe_guard",skin(toe_grid,.9,toe_angles),"03_Deep_teal_TPU",
    "Scalloped wings follow the vamp/guard boundary; no straight transverse cap seam.")
front_support = Part.makeCompound([foam_feature.Shape,outsole,upper_shell,toe_guard_feature.Shape])


def front_surface_x(y,z):
    ray = Part.makeLine(V(215,y,z),V(310,y,z))
    intersections = front_support.section(ray).Vertexes
    if not intersections:
        raise ValueError("Front bumper has no supporting surface at y=%g, z=%g" % (y,z))
    return max(v.Point.x for v in intersections)


bumper_zs = [28,32,36,40,44,48,52,56,60,64,67]
bumper_grid = []
for z in bumper_zs:
    width = smooth([(28,18),(36,21),(44,18),(53,14),(61,10),(67,6)],z)
    row = []
    for t in [-1,-.75,-.5,-.25,0,.25,.5,.75,1]:
        y = width*t
        row.append(V(front_surface_x(y,z)-.12,y,z))
    bumper_grid.append(row)
bumper_inner = surface(bumper_grid,bumper_zs)
bumper_outer = bumper_inner.copy()
bumper_outer.translate(V(1.4,0,0))
bumper_faces = [bumper_inner]
for a,b in zip(bumper_inner.Edges,bumper_outer.Edges):
    wall = Part.makeRuledSurface(a,b)
    u0,u1,v0,v1 = wall.ParameterRange
    normal = wall.normalAt((u0+u1)/2,(v0+v1)/2)
    if a.BoundBox.ZLength < .00001:
        direction = -1 if a.CenterOfMass.z < 40 else 1
        if normal.z*direction < 0:
            wall.reverse()
    elif normal.y*a.CenterOfMass.y < 0:
        wall.reverse()
    bumper_faces.append(wall)
bumper_outer.reverse()
bumper_faces.append(bumper_outer)
toe_bumper = Part.makeSolid(Part.makeShell(bumper_faces))
add("Orange_toe_climbing_bumper", toe_bumper, "09_Orange_rubber")
for side in [-1,1]:
    for z,y in [(36,11),(47,8)]:
        x = front_surface_x(side*y,z)+.65
        block = Part.makeBox(2.8,3.6,3.6,V(x,side*y-1.8,z-1.8))
        block = block.makeFillet(.45,block.Edges)
        add("Toe_bumper_grip_%s_%s"%(side,z),block,"09_Orange_rubber")

def rear_point(z, y, lift=0):
    height = 39+(z-39)*LAST_RISE
    lo,hi = .5,28.0
    for _ in range(32):
        x = (lo+hi)/2
        crown = top(x,y).z if smooth(WIDTH,x) > abs(y) else smooth(BASE,x)
        if crown < height:
            lo = x
        else:
            hi = x
    return V(hi-1.0-lift, y, height)


for name, width, mat, lift in [
        ("Sculpted_rear_heel_counter", 22, "03_Deep_teal_TPU", 0),
        ("Coral_rear_pull_spine", 7.5, "04_Coral_TPU", .65)]:
    zs = [54,60,68,76,84,92,98] if name=="Coral_rear_pull_spine" else [40,48,60,72,84,96,104,108]
    grid = [[rear_point(z-4*(z-40)/68*t*t,
                       width*t*(1-.18*((z-40)/68)**4),lift)
             for t in [-1,-.7,-.3,0,.3,.7,1]]
            for z in zs]
    add(name, skin(grid,.8),mat)
rear_stitches = []
for y in [-6,6]:
    for z in range(56,96,3):
        rear_stitches.append(cylinder_between(rear_point(z,y,1.35),
                                             rear_point(z+1.6,y,1.35),.20))
add("Heel_spine_edge_stitching",Part.makeCompound(rear_stitches),"12_Lime_tracer")
pad_zs = [103,105,108,111,114,117,120,123,125]
pad_grid = [[rear_point(39+(z-39)/LAST_RISE,y,.9)
             for y in [-20,-15,-10,-5,0,5,10,15,20]] for z in pad_zs]
pad_stock = skin(pad_grid,1.5,pad_zs)
pad_mask_curve = spline([V(-10,17*math.cos(t),113+9*math.sin(t))
                         for t in [2*math.pi*i/32 for i in range(32)]],True)
pad_mask = Part.Face(Part.Wire(pad_mask_curve.toShape())).extrude(V(55,0,0))
add("Rear_padded_heel_patch",pad_stock.common(pad_mask),"02_Quarter_knit",
    "The upper rear fabric patch overlaps the shortened vertical spine.")

log("Building tongue, eyelets and woven laces")
def tongue_point(x, y, lift=0):
    extra = smooth([(76,24),(90,8),(115,2.5),(150,1.5),(184,1),(196,1)], x)
    return top(x, y, extra+lift)

tongue_grid = []
for i in range(33):
    u = i/32
    row = []
    for t in [-1,-.75,-.4,0,.4,.75,1]:
        x = 77+119*u+(5-10*u)*t*t
        row.append(tongue_point(x,(21+3*math.sin(math.pi*(x-77)/118))*t))
    tongue_grid.append(row)
add("Gusseted_padded_tongue", skin(tongue_grid, -2.5), "03_Deep_teal_TPU")
for side in [-1,1]:
    pts = [tongue_point(x, side*(21+3*math.sin(math.pi*(x-77)/118)), .5)
           for x in [82+109*i/48 for i in range(49)]]
    add(("Left" if side<0 else "Right")+"_tongue_piping",pipe(pts,.8),"01_Engineered_mesh")
label_grid = [[tongue_point(x,y,1.0) for y in [-4,0,4]] for x in [80,85,90,96]]
add("Coral_tongue_label", skin(label_grid,.5), "04_Coral_TPU")
rows = [103,122,141,160,180]
eye_centers = {}
toe_facing = outline_face([(182,-27),(190,-27),(200,-19),(202,0),(200,19),
                           (190,27),(182,27),(184,22),(193,18),(195,0),(193,-18),(184,-22)])
add("Rounded_throat_to_vamp_facing",dorsal_patch(toe_facing,.04,.65),"03_Deep_teal_TPU",
    "U-shaped facing closes the throat onto the vamp; tongue end overlaps its inner edge.")
for side in [-1,1]:
    prefix = "Lateral" if side<0 else "Medial"
    bed_points = [(86,25),(95,32),(114,33),(137,32),(161,30),(183,29),
                  (198,19),(194,15),(182,21),(159,23),(136,25),(112,24),(90,21)]
    bed_face = outline_face([(x,side*y) for x,y in bed_points])
    add(prefix+"_continuous_lacing_facing",dorsal_patch(bed_face,.04,.65),
        "03_Deep_teal_TPU","Continuous curved facing with a tucked tongue/gusset overlap.")
    panels = [([(83,25),(90,31),(100,32),(111,30),(119,33),(129,31),
                (132,25),(125,22),(114,23),(105,21),(94,22)],[0,1])]
    for i,x in enumerate(rows[2:],2):
        r = 27 if i<3 else 25
        panels.append(([(x-7,r-4),(x+4,r-4),(x+8,r),(x+6,r+5),
                         (x-4,r+5),(x-7,r+2)],[i]))
    for number,(outline,indices) in enumerate(panels,1):
        face = outline_face([(x,side*y) for x,y in outline])
        sh = dorsal_patch(face,.68,.95)
        emboss = dorsal_patch(face.makeOffset2D(-.85),1.51,.25)
        for i in indices:
            x = rows[i]
            y = side*(27 if i<3 else 25)
            hole = Part.makeCylinder(2.2,100,V(x,y,55),V(0,0,1))
            sh = sh.cut(hole)
            emboss = emboss.cut(hole)
        if number == 1:
            spare = Part.makeCylinder(1.55,100,V(89,side*27,55),V(0,0,1))
            sh = sh.cut(spare)
            emboss = emboss.cut(spare)
        sh = sh.fuse(emboss).removeSplitter()
        add(prefix+"_contoured_eyestay_%02d"%number,sh,"04_Coral_TPU",
            "Lobed first eyestay spans two eyelets; inset molding relief and real hardware bores.",
            explicit_nurbs=True)
        edit_recipe["eyestays"].append({"name": prefix+"_contoured_eyestay_%02d"%number,
                                        "face": face.copy(), "indices": indices,
                                        "side": side, "spare": number == 1})
    for i,x in enumerate(rows):
        y = side*(27 if i<3 else 25)
        p = top(x,y,2.0)
        ring = Part.makeTorus(2.1,.55,p,V(0,0,1))
        add(prefix+"_eyelet_%02d"%(i+1),
            ring,"05_Obsidian_support")
        eye_centers[side,i] = p+V(0,0,1.0)

lace_paths = []
for i in range(4):
    for side in [-1,1]:
        a, b = eye_centers[side,i], eye_centers[-side,i+1]
        pts = []
        for j in range(9):
            t = j/8
            p = a*(1-t)+b*t
            p.z = max(p.z, tongue_point(p.x,p.y).z)+2.0+1.2*math.sin(math.pi*t)
            if side == 1:
                p.z += 1.5*math.sin(math.pi*t)
            if j == 0:
                p = a
            elif j == 8:
                p = b
            pts.append(p)
        lace_paths.append(pts)
        add("Lace_cross_%d_%s"%(i+1,"over" if side<0 else "under"),
            pipe(pts,1.8,1.1),"11_Teal_laces")
a,b = eye_centers[-1,4],eye_centers[1,4]
pts = [a, tongue_point(182,-13,3),tongue_point(183,0,3),tongue_point(182,13,3),b]
lace_paths.append(pts)
add("Lace_bottom_bridge",pipe(pts,1.8,1.1),"11_Teal_laces")
a,b = eye_centers[-1,0],eye_centers[1,0]
pts = [a,tongue_point(100,-14,2.8),tongue_point(99,0,2.8),tongue_point(100,14,2.8),b]
add("Lace_top_bridge",pipe(pts,1.8,1.1),"11_Teal_laces",
    "The reference shows an upper lace bridge, not exposed bow loops or trailing aglets.")
log("Building emblem and structural seam stitching")
# Angular running-cat outline, projected onto the lateral vamp.
graphic_paths = [
    [(104,443),(402,310),(708,202),(937,129),(991,138),(987,102),
     (1067,123),(1193,153),(1207,181),(1241,205),(1203,242),
     (1160,233),(1129,237),(1106,251),(1085,280),(1111,289),
     (1154,291),(1127,331),(1026,331),(985,323),(954,303),(941,308),(859,410)],
    [(1026,331),(980,242)],[(1207,181),(1162,174)]]
emblem_mask = None
for graphic in graphic_paths:
    points = reference_outline([(865+x/3,485+y/3) for x,y in graphic])
    vectors = [V(x,0,z) for x,z in points]
    if len(vectors) == 2:
        a,b = vectors
        normal = (b-a).cross(V(0,1,0))
        normal.normalize()
        normal *= .62
        corners = [a+normal,b+normal,b-normal,a-normal]
        stroke = Part.Face(Part.makePolygon(corners+[corners[0]]))
        for end in vectors:
            stroke = stroke.fuse(Part.Face(Part.Wire(Part.makeCircle(.62,end,V(0,1,0)))))
    else:
        path = Part.makePolygon(vectors)
        stroke = path.makeOffset2D(.62,join=0,fill=True)
    emblem_mask = stroke if emblem_mask is None else emblem_mask.fuse(stroke)
emblem = panel_layer(.02,.16).common(panel_prism(emblem_mask,-1))
add("Reflective_cougar_transfer",emblem,"13_Silver_graphic",
    "0.16 mm reflective transfer beneath the bonded cage, not a raised wire crossing the overlays.")


doc.recompute()
log("Saving native construction")
doc.saveAs(os.path.join(OUT, "Cougar_Trail.FCStd"))


def export_glb():
    """Named geometry with simple placeholder materials for the visualization team."""
    binary = bytearray()
    views, accessors, meshes, nodes = [], [], [], []
    gl_materials = []
    for mat, (color, roughness) in materials.items():
        gl_materials.append({"name":mat,"pbrMetallicRoughness":{
            "baseColorFactor":[*color,1],"metallicFactor":0,
            "roughnessFactor":roughness},"doubleSided":True})
    mat_ids = {m:i for i,m in enumerate(materials)}
    def accessor(data, fmt, typ, component, target, bounds=False):
        while len(binary)%4:
            binary.append(0)
        start = len(binary)
        flat = [v for row in data for v in row] if typ != "SCALAR" else data
        binary.extend(struct.pack("<"+str(len(flat))+fmt,*flat))
        vi = len(views)
        views.append({"buffer":0,"byteOffset":start,"byteLength":len(binary)-start,"target":target})
        acc = {"bufferView":vi,"componentType":component,"count":len(data),"type":typ}
        if bounds:
            acc["min"] = [min(row[k] for row in data) for k in range(3)]
            acc["max"] = [max(row[k] for row in data) for k in range(3)]
        accessors.append(acc)
        return len(accessors)-1
    for obj in objects:
        mesh = MeshPart.meshFromShape(Shape=obj.Shape, LinearDeflection=.10,
                                     AngularDeflection=.20, Relative=False)
        vertices, triangles = mesh.Topology
        if not vertices or not triangles:
            raise ValueError("Empty rendering mesh: "+obj.Name)
        if obj.Name in ["Continuous_sculpted_EVA_midsole", "Continuous_rockered_rubber_carrier"]:
            minimum_z = 6.0 if "EVA" in obj.Name else 3.8
            if any(p.z < minimum_z or p.z > 55.0 or p.x < -8.01 or p.x > 292.01
                   for p in vertices):
                raise ValueError("Sole loft exceeds its reference envelope: "+obj.Name)
        if obj.Name == "Orange_toe_climbing_bumper":
            if any(p.x > 294 or p.x < 265 or p.z < 27.99 or p.z > 67.01
                   for p in vertices):
                raise ValueError("Toe bumper exceeds its supported design envelope")
        # CAD is Z-up, millimetres; glTF is Y-up, metres.
        positions = [(p.x*.001,p.z*.001,-p.y*.001) for p in vertices]
        normals = [V(0,0,0) for _ in vertices]
        for a,b,c in triangles:
            normal = (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a])
            for i in [a,b,c]:
                normals[i] += normal
        for n in normals:
            if n.Length:
                n.normalize()
        normal_data = [(n.x,n.z,-n.y) for n in normals]
        attrs = {"POSITION":accessor(positions,"f","VEC3",5126,34962,True),
                 "NORMAL":accessor(normal_data,"f","VEC3",5126,34962)}
        material_id = mat_ids[obj.RenderMaterial]
        indices = accessor([i for tri in triangles for i in tri],"I","SCALAR",5125,34963)
        meshes.append({"name":obj.Label,"primitives":[{"attributes":attrs,
                        "indices":indices,"material":material_id}]})
        nodes.append({"name":obj.Label,"mesh":len(meshes)-1,
                      "extras":{"CADMaterial":obj.RenderMaterial}})
    model = {"asset":{"version":"2.0","generator":"FreeCAD 1.1 / Cougar reference reconstruction"},
             "scene":0,"scenes":[{"nodes":list(range(len(nodes)))}],
             "nodes":nodes,"meshes":meshes,"materials":gl_materials,
             "buffers":[{"byteLength":len(binary)}],"bufferViews":views,"accessors":accessors}
    data = json.dumps(model,separators=(",",":")).encode()
    data += b" "*((-len(data))%4)
    binary.extend(b"\x00"*((-len(binary))%4))
    total = 12+8+len(data)+8+len(binary)
    with open(os.path.join(OUT,"Cougar_Trail.glb"),"wb") as f:
        f.write(struct.pack("<4sII",b"glTF",2,total))
        f.write(struct.pack("<I4s",len(data),b"JSON")); f.write(data)
        f.write(struct.pack("<I4s",len(binary),b"BIN\x00")); f.write(binary)


if os.environ.get("COUGAR_GEOMETRY_ONLY") != "1":
    log("Exporting material-separated GLB")
    export_glb()
report = {"application":"FreeCAD "+ ".".join(App.Version()[:3]),
          "units":"mm","component_count":len(objects),
          "valid_components":sum(o.Shape.isValid() for o in objects),
          "solid_count":sum(len(o.Shape.Solids) for o in objects),
          "reference_images":["Gemini_Generated_Image_8vkt9v8vkt9v8vkt.jpg",
                              "Gemini_Generated_Image_t8v95jt8v95jt8v9.jpg"],
          "limitations":["Dimensions and hidden geometry inferred from perspective concept images.",
                         "Reconstructed last is not scan-based or fit validated.",
                         "No mold split, shrink compensation, or manufacturing certification.",
                         "Colors are placeholders; gradients and fabric textures are left to visualization.",
                         "Fabric panels are smooth shells without knit relief or simulated perforations."],
          "components":[{"name":o.Name,"material":o.RenderMaterial,
                         "solids":len(o.Shape.Solids),"valid":o.Shape.isValid()}
                        for o in objects]}
with open(os.path.join(OUT,"model_manifest.json"),"w") as f:
    json.dump(report,f,indent=2)
log("COMPLETE: %d valid CAD components" % len(objects))
