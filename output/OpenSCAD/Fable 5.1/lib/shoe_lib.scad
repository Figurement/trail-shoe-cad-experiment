// shoe_lib.scad — generic construction helpers for the trail shoe model.
//
// Coordinate convention used by the whole project:
//   +X = heel -> toe (heel end of midsole at x = 0)
//   +Z = up (ground plane / lug tips at z = 0)
//   +Y = medial side, -Y = lateral side (this is a RIGHT shoe)
//
// Everything here is driven by "station tables": lists of rows whose first
// column is the X station and the remaining columns are driving dimensions.
// Tables are interpolated with a Catmull-Rom spline so that a sparse set of
// human-editable rows produces smooth lofts.

EPS = 0.01;

// ---------------------------------------------------------------- tables ---

// Index of the segment [i, i+1] that contains x (clamped to the table range).
function _seg(tbl, x, i = 0) =
    (i >= len(tbl) - 2 || x <= tbl[i + 1][0]) ? i : _seg(tbl, x, i + 1);

function _cr(p0, p1, p2, p3, t) =
    0.5 * ((2 * p1) + (-p0 + p2) * t
        + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
        + (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t);

// Smooth (Catmull-Rom) interpolation of column `c` of a station table at x.
// Values are clamped outside the table range.
function tval(tbl, x, c = 1) =
    let(n = len(tbl))
    x <= tbl[0][0] ? tbl[0][c] :
    x >= tbl[n - 1][0] ? tbl[n - 1][c] :
    let(i = _seg(tbl, x),
        p1 = tbl[i], p2 = tbl[i + 1],
        p0 = tbl[max(i - 1, 0)], p3 = tbl[min(i + 2, n - 1)],
        t = (x - p1[0]) / (p2[0] - p1[0]))
    _cr(p0[c], p1[c], p2[c], p3[c], t);

// Linear version (used for the outer x extents so ends stay exact).
function tlin(tbl, x, c = 1) =
    let(n = len(tbl))
    x <= tbl[0][0] ? tbl[0][c] :
    x >= tbl[n - 1][0] ? tbl[n - 1][c] :
    let(i = _seg(tbl, x), p1 = tbl[i], p2 = tbl[i + 1],
        t = (x - p1[0]) / (p2[0] - p1[0]))
    p1[c] + (p2[c] - p1[c]) * t;

// Numerical slope d(col)/dx of a table at x (degrees).
function tslope_deg(tbl, x, c = 1, h = 1) =
    atan((tval(tbl, x + h, c) - tval(tbl, x - h, c)) / (2 * h));

// Evenly spaced stations between the first and last x of a table.
// Station positions are blended 60 % uniform / 40 % cosine so the rounded
// heel and toe get ~half the spacing of the midfoot.
function stations(tbl, n) =
    let(x0 = tbl[0][0], x1 = tbl[len(tbl) - 1][0])
    [for (i = [0 : n]) let(t = i / n) x0 + (x1 - x0) * (0.6 * t + 0.4 * (1 - cos(180 * t)) / 2)];

// ------------------------------------------------------------- sections ---

// 2D cross-section = convex hull of a list of circles [[y, z, r], ...].
// Circles give the section smooth rounded corners; the hull keeps it convex
// so that consecutive sections can be lofted with hull().
module rsec(circles, grow = 0) {
    hull() for (c = circles)
        translate([c[0], c[1]]) circle(r = max(c[2] + grow, 0.05));
}

// Place a 2D section (drawn in Y/Z) as a thin slab at station x.
module slab(x) {
    translate([x, 0, 0]) rotate([90, 0, 90]) linear_extrude(EPS) children();
}

// Loft: union of hulls between consecutive slabs. `secs` is a list of
// [x, circles]. Concave-along-X shapes (recessed waist etc.) are fine because
// each hull only spans two neighbouring stations.
module loft(secs, grow = 0) {
    for (i = [0 : len(secs) - 2])
        hull() {
            slab(secs[i][0]) rsec(secs[i][1], grow);
            slab(secs[i + 1][0]) rsec(secs[i + 1][1], grow);
        }
}

// ---------------------------------------------------------- 2D strokes ---

// Stroke a 2D polyline with a round brush of (possibly per-point) width.
// pts = [[x, y], ...], w = number or list of widths (one per point).
module band2d(pts, w) {
    for (i = [0 : len(pts) - 2]) hull() {
        translate(pts[i]) circle(d = is_list(w) ? w[i] : w);
        translate(pts[i + 1]) circle(d = is_list(w) ? w[i + 1] : w);
    }
}

// Closed 2D outline with rounded corners.
module rpoly(pts, r) { offset(r = r) offset(delta = -r) polygon(pts); }

// ----------------------------------------------------------- 3D sweeps ---

// Sweep a sphere along a 3D polyline (round tube). r may be a list.
module tube(pts, r) {
    for (i = [0 : len(pts) - 2]) hull() {
        translate(pts[i]) sphere(r = is_list(r) ? r[i] : r);
        translate(pts[i + 1]) sphere(r = is_list(r) ? r[i + 1] : r);
    }
}

// Extrude a side-view (X/Z) 2D drawing along Y through the whole shoe.
module from_side(width = 400) {
    rotate([90, 0, 0]) linear_extrude(height = width, center = true) children();
}

// Extrude a rear-view (Y/Z) 2D drawing along X.
module from_rear(length = 400) {
    rotate([90, 0, 90]) linear_extrude(height = length, center = true) children();
}

// Extrude a top-view (X/Y) 2D drawing along Z.
module from_top(z0 = -50, z1 = 250) {
    translate([0, 0, z0]) linear_extrude(height = z1 - z0) children();
}

// Half spaces (side = -1 lateral, +1 medial).
module half_y(side) { translate([-500, side > 0 ? 0 : -1000, -500]) cube(1000); }
module half_x(min_x = -1000, max_x = 1000) {
    translate([min_x, -500, -500]) cube([max_x - min_x, 1000, 1000]);
}

// Mirror a symmetric top-view half outline [[x, hw], ...] into a polygon.
function mirror_outline(rows) =
    concat([for (r = rows) [r[0], r[1]]],
           [for (i = [len(rows) - 1 : -1 : 0]) [rows[i][0], -rows[i][1]]]);
