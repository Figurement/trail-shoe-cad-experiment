// trail_shoe.scad — reference-based trail running shoe (RIGHT shoe).
//
// File layout
//   1. Global driving dimensions
//   2. Sole   : midsole loft (single continuous body) + outsole lugs + toe cap
//   3. Upper  : lasted shell loft, collar/throat opening, collar padding, tongue
//   4. Panels : overlays conforming to the upper (lateral cage, medial chevron,
//               heel strip, eyestay plates, lace loops)
//   5. Hardware: laces
//   6. Assembly / part selection for scripted export
//
// Coordinates: +X heel->toe (midsole heel end at x=0), +Z up (ground z=0),
// -Y lateral (outside), +Y medial. All dimensions in mm.
//
// OBSERVED vs INFERRED
//   * Silhouette, stack heights, rocker, panel outlines, loop count/positions
//     were traced from input/left-view.jpg and input/three-angles.jpg
//     (reference scaled to a 300 mm outsole length; ±3 mm reading accuracy).
//   * Widths (Y) are INFERRED from the perspective front/heel views and typical
//     running-shoe proportions; they were not measured.
//   * Wall thicknesses, overlap depths, lug heights and the interior are
//     INFERRED construction, not manufacturing data.
//   * Nothing here is manufacturing-validated.
//
// Fixed (non-parametric) references: the traced 2D panel outlines in section 4
// are literal side-view coordinates; they do not move automatically when the
// upper station table changes and must be re-traced after big silhouette edits.

include <lib/shoe_lib.scad>

// --------------------------------------------------------------------------
// 1. GLOBAL DRIVING DIMENSIONS
// --------------------------------------------------------------------------
part      = "all";      // -D part="midsole" | "lugs" | "upper" | ... for export
$fn       = 36;

LENGTH        = 300;    // midsole heel end to toe tip (reference scaled to this)
UPPER_T       = 3.0;    // upper shell thickness (inferred)
UPPER_SINK    = 3.0;    // how far the upper is sunk into the midsole top edge
PANEL_T       = 1.6;    // thickness of overlay panels standing off the upper

// placeholder colours (visualisation team assigns real materials)
C_MIDSOLE = [0.20, 0.55, 0.95];
C_LUG_GRY = [0.30, 0.34, 0.38];
C_LUG_ORG = [1.00, 0.45, 0.25];
C_MESH    = [0.10, 0.42, 0.52];
C_ORANGE  = [1.00, 0.42, 0.28];
C_BLACK   = [0.08, 0.08, 0.10];
C_NEON    = [0.75, 1.00, 0.10];
C_COLLAR  = [0.12, 0.35, 0.45];
C_LACE    = [0.15, 0.60, 0.60];
C_LOGO    = [0.92, 0.94, 0.97];   // white/silver print

// --------------------------------------------------------------------------
// 2. SOLE
// --------------------------------------------------------------------------
// Midsole station table (observed from side views):
//   x, z_bottom, z_top(upper join line), hw_lat, hw_med (max half-widths)
MS = [
//   x    zb    zt   hwL   hwM   (z in the traced frame: reference ground is z = REF_GROUND)
    // heel: half-widths follow a 25 x 42 mm plan ellipse (rounded heel)
    [  0,   30,   49,    6,    6],
    [  2,   24,   58,   17,   16],
    [  5,   21,   66,   25,   23],
    [  9,   20,   72,   32,   30],
    [ 14, 19.5,   76,   37,   34],
    [ 20, 19.5,   73,   41,   38],
    [ 30,   19,   64,   44,   40],
    [ 40, 18.5,   61,   45,   41],
    [ 55, 17.5,   60,   44,   40],
    [ 70, 16.5,   59,   44,   39],
    [ 85,   16,   55,   43,   38],
    [100, 15.5,   52,   42,   37],
    [130, 15.5,   46,   43,   38],
    [160, 15.5,   41,   47,   42],
    [190,   16, 39.5,   52,   48],
    [200,   17,   41,   53,   50],
    [215, 18.5, 45.5,   55,   53],
    [230, 20.5,   51,   54,   54],
    [240,   23,   55,   54,   55],
    [250,   27,   59,   52,   55],
    [262,   32,   63,   50,   55],
    [272,   38,   65,   47,   52],
    // toe: elliptical nose, lateral side tapers earlier so the apex sits
    // slightly medial of the centreline (observed in the front view)
    [280,   44,   66,   44,   50],
    [285, 48.5,   67,   41,   48],
    [290,   53,   68,   35,   42],
    [294, 55.5,   68,   28,   35],
    [297,   58, 67.5,   20,   25],
    [299,   60, 66.5,   12,   16],
    [300,   61,   66,    4,    7],
];
// How far the midsole top edge tucks in from the max sidewall width
// (heel flare is strongest at the back — observed in the heel view).
// All traced z values are in the reference-image frame; the reference ground
// line (lug tips) sits at z = REF_GROUND in that frame. The assembly is shifted
// down by this amount so lug tips rest on z = 0.
REF_GROUND = 8;
MS_TUCK = [[0, 11], [40, 11], [100, 8], [190, 6.5], [262, 6], [288, 8], [300, 12]];  // nose top narrows to a ridge
MS_R_BOTTOM  = 5;      // bottom edge radius
MS_R_BULGE   = 9;      // sidewall bulge radius
MS_BULGE_AT  = 0.36;   // bulge height as a fraction of the stack
MS_R_TOP     = 3;
MS_STATIONS  = 40;

function ms_zb(x)  = tval(MS, x, 1);
function ms_zt(x)  = tval(MS, x, 2);
function ms_hw(x, side) = tval(MS, x, side < 0 ? 3 : 4);   // side: -1 lat, +1 med
function ms_tuck(x) = tval(MS_TUCK, x, 1);
function ms_hw_top(x, side) = ms_hw(x, side) - ms_tuck(x);  // half-width of the upper join line

// One convex midsole cross-section at station x.
function ms_section(x) =
    let(zb = ms_zb(x), zt = ms_zt(x), h = zt - zb,
        hl = ms_hw(x, -1), hm = ms_hw(x, +1),
        zm = zb + MS_BULGE_AT * h,
        rb = min(MS_R_BOTTOM, h / 2.2), rm = min(MS_R_BULGE, h / 2.2),
        rt = min(MS_R_TOP, h / 2.5))
    [
        [-(hl - 2 - rb), zb + rb, rb], [ (hm - 2 - rb), zb + rb, rb],   // bottom
        [-(hl - rm),     zm,      rm], [ (hm - rm),     zm,      rm],   // bulge
        [-(ms_hw_top(x, -1) - rt), zt - rt, rt], [(ms_hw_top(x, +1) - rt), zt - rt, rt],
    ];

function ms_sections(grow = 0) = [for (x = stations(MS, MS_STATIONS)) [x, ms_section(x)]];

module midsole_body() { loft(ms_sections()); }

// Sidewall sculpt groove observed in both side views: a shallow channel that
// runs along the sidewall roughly 45 % up the stack. Subtracted so the midsole
// remains ONE continuous body.
GROOVE_R = 2.8;
GROOVE_AT = 0.47;
module sidewall_groove(side) {
    pts = [for (x = [14 : 8 : 292])
        let(zb = ms_zb(x), zt = ms_zt(x), z = zb + GROOVE_AT * (zt - zb),
            hw = ms_hw(x, side) - 0.6)
        [x, side * hw, z]];
    tube(pts, GROOVE_R);
}

module midsole() {
    color(C_MIDSOLE) difference() {
        midsole_body();
        sidewall_groove(-1);
        sidewall_groove(+1);
    }
}

// ---- outsole lugs -------------------------------------------------------
// Rows across the footprint: x, lug count, colour group ("org" | "gry").
// Observed: orange lugs at heel and toe, grey lugs in the midfoot/forefoot.
LUG_ROWS = [
    [ 16, 3, "org"], [ 36, 4, "org"], [ 56, 4, "org"],
    [ 78, 4, "gry"], [100, 4, "gry"], [122, 4, "gry"], [144, 4, "gry"],
    [166, 4, "gry"], [188, 4, "gry"],
    [210, 4, "org"], [232, 4, "org"], [254, 4, "org"], [274, 3, "org"],
];
LUG_MARGIN = 10;    // inset of the outer lugs from the footprint edge
LUG_H      = 8;     // overrides the global placeholder above (observed chunky lugs)

module lug_shape() {   // chevron lug, drawn in X/Y, 17 x 13 mm
    rpoly([[-8.5, -6.5], [0, -3], [8.5, -6.5], [8.5, 2], [0, 6.5], [-8.5, 2]], 1.5);
}

module lugs() {
    for (row = LUG_ROWS) {
        x = row[0]; n = row[1];
        yl = -(ms_hw(x, -1) - LUG_MARGIN); ym = (ms_hw(x, +1) - LUG_MARGIN);
        for (i = [0 : n - 1]) {
            y = yl + (ym - yl) * (n == 1 ? 0.5 : i / (n - 1));
            color(row[2] == "org" ? C_LUG_ORG : C_LUG_GRY)
            translate([x, y, ms_zb(x) + 1])
                rotate([0, tslope_deg(MS, x, 1), 0])
                mirror([0, 0, 1]) linear_extrude(LUG_H + 1, scale = 0.8) lug_shape();
        }
    }
}

// Orange rubber toe cap wrapping the front of the midsole (observed).
TOE_CAP_HW = 24;    // half-width of the cap across the nose (inferred from front view)
module toe_cap() {
    color(C_LUG_ORG) intersection() {
        difference() { loft(ms_sections(), grow = 1.4); midsole_body(); }
        // cap boundary: low at the nose, wrapping slightly higher at the tip
        from_side() polygon([[286, 0], [285, 46], [289, 72], [320, 72], [320, 0]]);
        // tapering plan-view clip so the cap wraps the nose, not the sides
        translate([300 + TOE_CAP_HW * 0.5, 0, -10]) cylinder(r = TOE_CAP_HW * 1.25, h = 100);
    }
}

module sole() { midsole(); lugs(); toe_cap(); }

// --------------------------------------------------------------------------
// 3. UPPER
// --------------------------------------------------------------------------
// Upper (last) station table — observed rim/top line from the side views;
// widths inferred.   x, z_top, hw_base, hw_top, r_top
UP = [
//   x   ztop hwT  rT  bulge
    [  5,  71,  3,  2,  0],   // heel counter back edge (rounded in plan by heel_tuck)
    [  7,  77,  5,  4,  0],
    [ 10,  82,  8,  6,  0],
    [ 14,  90, 11,  9,  0.5],
    [ 20,  97, 14, 12,  1.5],
    [ 26, 119, 17, 14,  2],
    [ 32, 132, 19, 14,  2],
    [ 40, 134, 21, 14,  2],
    [ 50, 128, 23, 14,  2],
    [ 60, 114, 25, 13,  1.5],
    [ 70, 112, 26, 12,  1],
    [ 80, 117, 26, 12,  1],
    [ 92, 121, 25, 11,  0.5],
    [108, 128, 24, 11,  0],
    [125, 121, 25, 12,  0.5],
    [150, 111, 28, 14,  1],
    [172, 101, 31, 16,  1.5],
    [194,  92, 33, 18,  2],
    [217,  86, 33, 20,  2],
    [240,  84, 30, 20,  2],
    [262,  80, 23, 18,  1.5],
    [278,  75,  9,  8,  1],   // toe box domes down to the bumper
    [291,  70,  3,  3,  0],
];
UP_R_BASE   = 9;
UP_STATIONS = 40;

function up_zt(x)   = tval(UP, x, 1);
function up_zb(x)   = ms_zt(x) - UPPER_SINK;
function up_hwt(x)  = tval(UP, x, 2);
function up_rt(x)   = tval(UP, x, 3);
function up_bulge(x)= tval(UP, x, 4);
// Base half-width is LINKED to the midsole join line (sits 0.8 mm inside it),
// minus a heel tuck that rounds the counter in plan behind x = HEEL_TUCK[1]
// (observed in the heel view: the counter is narrower than the midsole cup).
HEEL_TUCK = [5, 30];    // [mm tucked at x = 0, x where the tuck fades out]
function heel_tuck(x) = x < HEEL_TUCK[1] ? HEEL_TUCK[0] * (1 - x / HEEL_TUCK[1]) : 0;
function up_hwb(x, side) = ms_hw_top(x, side) - 0.8 - heel_tuck(x);

function up_section(x) =
    let(zb = up_zb(x), zt = up_zt(x), h = zt - zb,
        hl = up_hwb(x, -1), hm = up_hwb(x, +1), ht = up_hwt(x), bu = up_bulge(x),
        rb = min(UP_R_BASE, h / 2.2), rt = min(up_rt(x), h / 2.2, ht),
        zm = zb + 0.42 * h, rm = min(10, h / 2.2))
    [
        [-(hl - rb), zb + rb, rb],      [(hm - rb), zb + rb, rb],       // base
        [-(hl + bu - rm), zm, rm],      [(hm + bu - rm), zm, rm],       // side wall bulge
        [-(ht - rt), zt - rt, rt],      [(ht - rt), zt - rt, rt],       // rounded top
    ];

function up_sections() = [for (x = stations(UP, UP_STATIONS)) [x, up_section(x)]];

module upper_outer(grow = 0, x0 = -1, x1 = 999) {
    loft([for (s = up_sections()) if (s[0] >= x0 - 8 && s[0] <= x1 + 8) s], grow);
}

// Collar + throat opening, top view half outline [x, half_width] (inferred
// from the visible collar rim and tongue width).
OPENING = [
    [24, 3], [30, 10], [40, 16], [52, 19], [70, 20], [90, 20], [110, 19],
    [130, 18], [150, 17], [170, 15], [188, 11], [198, 4], [203, 0.5],
];
OPENING_FLOOR = 68;     // opening cut starts above this height

function open_hw(x) = tval(OPENING, x, 1);

module opening_cut() {
    from_top(OPENING_FLOOR, 250) rpoly(mirror_outline(OPENING), 2);
}

module upper_shell() {
    color(C_MESH) difference() {
        upper_outer();
        upper_outer(-UPPER_T);
        opening_cut();
    }
}

// Collar padding: round tube swept along the rim from heel tab to eyestay top.
COLLAR_R = 4.5;
module collar() {
    pts = [for (x = [27 : 4 : 99]) [x, -open_hw(x) - 1, up_zt(x) - 2.5]];
    color(C_COLLAR) {
        tube(pts, COLLAR_R);
        mirror([0, 1, 0]) tube(pts, COLLAR_R);
        // padded heel tab closing the loop at the back
        tube([[27, -open_hw(27) - 1, up_zt(27) - 2.5], [25, 0, up_zt(25) - 2.5], [27, open_hw(27) + 1, up_zt(27) - 2.5]], COLLAR_R);
    }
}

// Tongue: x, rise of the tongue's top surface above the eyestay rim (LINKED to
// up_zt), half_width, thickness — lofted padded slab. The rise is positive only
// where the tongue stands out of the throat at the back (observed ~10 mm).
TONGUE = [
//   x   rise  hw   t
    [100,  4,  8,  4], [104, 10, 13,  7], [110, 15, 18, 10], [118, 13, 23, 12], [130, 11, 25, 11],
    [150, 11, 25, 10], [170,  9, 23, 9], [190,  4, 19, 8], [206,  2, 10, 6],
];
TONGUE_SAG = 5;
function tongue_t(x)  = tval(TONGUE, x, 3);
function tongue_zc(x) = up_zt(x) + tval(TONGUE, x, 1) - tongue_t(x) / 2;
function tongue_section(x) =
    let(z = tongue_zc(x), hw = tval(TONGUE, x, 2), r = tongue_t(x) / 2)
    [[0, z, r], [-(hw - r), z - TONGUE_SAG, r], [(hw - r), z - TONGUE_SAG, r]];

module tongue() {
    color(C_MESH) loft([for (x = stations(TONGUE, 14)) [x, tongue_section(x)]]);
    // orange top tab (observed in front view)
    color(C_ORANGE) hull() for (x = [109, 119])
        translate([x, 0, tongue_zc(x) + tongue_t(x) / 2 - 0.5])
            cube([1, 16, 1.6], center = true);
}

module upper() { upper_shell(); collar(); tongue(); }

// --------------------------------------------------------------------------
// 4. PANELS (overlays that conform to the upper surface)
// --------------------------------------------------------------------------
// A panel = thin layer on the outside of the upper, trimmed by a 2D outline
// projected from the side (X/Z), from the rear (Y/Z) or from the top.
// Only the stations spanning [x0, x1] are lofted so preview/CSG cost stays
// small per panel.
module shell_layer(t = PANEL_T, lift = 0, x0 = 0, x1 = 300) {
    difference() {
        upper_outer(t + lift, x0, x1);
        upper_outer(lift - 0.05, x0, x1);
    }
}

// Side projection is only meaningful where the upper faces sideways; behind
// WRAP_X the counter turns to face backwards, so side panels stop there and
// the wrap is drawn with rear-projected bands (heel_wrap) up to REAR_X.
WRAP_X = 21; REAR_X = 26;
module side_panel(side, t = PANEL_T, lift = 0, x0 = 0, x1 = 300) {
    intersection() { shell_layer(t, lift, x0, x1); half_y(side); half_x(max(x0, WRAP_X), x1); from_side() children(); }
}
module rear_panel(t = PANEL_T, lift = 0, max_x = REAR_X, side = 0) {
    intersection() {
        shell_layer(t, lift, 0, max_x); half_x(-10, max_x);
        if (side != 0) half_y(side);
        from_rear() children();
    }
}
// Rear-view band: pts are [|y|, z]; side = -1 puts it on the lateral side.
// (Points are mirrored numerically — a 2D mirror() here gives CGAL an open
// mesh in OpenSCAD 2021.01.)
function ysign(side, pts) = [for (p = pts) [side * p[0], p[1]]];
module rear_band(side, pts, w, lift = 0) {
    q = ysign(side, pts);
    for (i = [0 : len(q) - 2]) {
        wa = is_list(w) ? w[i] : w; wb = is_list(w) ? w[i + 1] : w;
        rear_panel(lift = lift, side = side)
            hull() { translate(q[i]) circle(d = wa); translate(q[i + 1]) circle(d = wb); }
    }
}
module rear_patch(side, pts, lift = 0, r = 1.5) {
    rear_panel(lift = lift, side = side) offset(r = r) offset(delta = -r) polygon(ysign(side, pts));
}

// Panel bands are built one convex segment at a time, each intersected with
// only the shell stations it spans. (Keeps the OpenCSG preview correct — it
// needs convex primitives — and keeps the CSG tree small.)
function _xs(pts) = [for (p = pts) p[0]];
module side_band(side, pts, w, lift = 0) {
    for (i = [0 : len(pts) - 2]) {
        wa = is_list(w) ? w[i] : w; wb = is_list(w) ? w[i + 1] : w; m = max(wa, wb);
        side_panel(side, lift = lift,
                   x0 = min(pts[i][0], pts[i + 1][0]) - m, x1 = max(pts[i][0], pts[i + 1][0]) + m)
            hull() { translate(pts[i]) circle(d = wa); translate(pts[i + 1]) circle(d = wb); }
    }
}
// Convex filled patch (points are hulled).
module side_patch(side, pts, lift = 0, r = 1.5) {
    side_panel(side, lift = lift, x0 = min(_xs(pts)) - 2, x1 = max(_xs(pts)) + 2)
        offset(r = r) offset(delta = -r) hull() polygon(pts);
}

// ---- lateral cage (traced from left-view.jpg, side coordinates) ----------
LAT_UPPER_ARM   = [[25, 102], [42, 96], [62, 93], [87, 92], [110, 86], [133, 75], [155, 67], [176, 57], [190, 46]];
LAT_UPPER_ARM_W = [9, 9, 8.5, 8.5, 8, 8, 7.5, 7, 6];
LAT_LOWER_ARM   = [[31, 88], [42, 83], [53, 78], [67, 71.5], [76, 68], [87, 63.5], [99, 59], [110, 55], [117, 56], [117, 62], [112, 67]];
LAT_BRIDGE      = [[67, 72], [76, 78], [85, 83]];
LAT_BLACK_BAND  = [[35, 99], [55, 92], [76, 83], [99, 69], [110, 64], [121, 53], [133, 49]];
LAT_BLACK_BAND_W= [9, 9, 9, 8.5, 8, 6.5, 4.5];
LAT_BLACK_HEEL  = [[16, 60], [46, 58], [46, 63], [40, 72], [31, 84], [27, 92], [23, 100], [16, 103]];

module lateral_cage() {
    color(C_BLACK) { side_band(-1, LAT_BLACK_BAND, LAT_BLACK_BAND_W); side_patch(-1, LAT_BLACK_HEEL); }
    color(C_ORANGE) {
        side_band(-1, LAT_UPPER_ARM, LAT_UPPER_ARM_W, lift = 0.4);
        side_band(-1, LAT_LOWER_ARM, 7, lift = 0.4);
        side_band(-1, LAT_BRIDGE, 5, lift = 0.4);
    }
}

// ---- cougar logo (traced from left-view.jpg, lateral side; outline print) --
// Stylised outline: back line rising out of the orange arm to the ear, head
// profile (forehead, nose, muzzle, chin), neck, and a lower chest line.
LOGO_W = 1.6;
LOGO_BACK  = [[156, 68], [175, 75], [193, 81.5]];
LOGO_HEAD  = [[193, 81.5], [200, 79.2], [209.5, 77.2], [210.5, 75.5], [207, 74.2], [202.5, 74.5],
              [204.5, 72.5], [205.5, 70.5], [200.5, 68.6], [194.5, 68.4], [191.2, 70.8], [191.2, 74],
              [193.5, 76.2]];
LOGO_EYE   = [[201, 76.6], [204.5, 75.6]];
LOGO_CHEST = [[174, 58.5], [184, 59.5], [190, 60.6], [192.5, 63.5], [192.4, 66.8]];

module cougar_logo() {
    color(C_LOGO) {
        side_band(-1, LOGO_BACK,  LOGO_W, lift = 0.7);
        side_band(-1, LOGO_HEAD,  LOGO_W, lift = 0.7);
        side_band(-1, LOGO_EYE,   LOGO_W, lift = 0.7);
        side_band(-1, LOGO_CHEST, LOGO_W, lift = 0.7);
    }
}

// ---- medial chevron (traced from three-angles.jpg centre panel) -----------
MED_BLACK_UP  = [[91, 76], [64, 82], [37, 88]];
MED_BLACK_LOW = [[91, 74], [63, 66], [35, 58]];
MED_ORANGE    = [[86, 81], [60, 87], [34, 93], [26, 88], [22, 76], [20, 62]];

module medial_chevron() {
    color(C_BLACK) { side_band(+1, MED_BLACK_UP, 6); side_band(+1, MED_BLACK_LOW, 6); }
    color(C_ORANGE) side_band(+1, MED_ORANGE, 2.6, lift = 0.4);
}

// ---- heel wrap (observed in heel view, three-angles.jpg right panel) ------
// Rear-view coordinates [|y|, z]. On each side of the central orange strip a
// black wing runs from the strip edge out to the counter corner and down to
// the midsole; the cage's upper and lower arms wrap around the corner and end
// as inward-pointing chevron tips beside the strip; a neon stripe sits
// diagonally in the wing. The medial arms sit ~6 mm lower (medial chevron).
HEEL_STRIP_HW = 8;                      // strip is ~16 mm wide
HEEL_STRIP_Z  = [54, 106];              // inside the midsole cup .. bottom of the heel tab
HEEL_WING     = [[HEEL_STRIP_HW, 54], [HEEL_STRIP_HW, 106], [16, 103], [30, 102], [46, 104], [46, 54]];
HEEL_ARM_UP   = [[46, 101], [30, 99], [16, 98]];    HEEL_ARM_UP_W  = [8.5, 8, 6];
HEEL_ARM_LOW  = [[46, 77], [32, 83], [18, 86]];     HEEL_ARM_LOW_W = [7, 7, 5];
HEEL_NEON     = [[27, 68], [21, 88]];
function dz(pts, d) = [for (p = pts) [p[0], p[1] + d]];

module heel_wrap() {
    for (side = [-1, 1]) {
        d = side > 0 ? -6 : 0;
        color(C_BLACK)  rear_patch(side, dz(HEEL_WING, d));
        color(C_ORANGE) {
            rear_band(side, dz(HEEL_ARM_UP, d),  HEEL_ARM_UP_W,  lift = 0.4);
            rear_band(side, dz(HEEL_ARM_LOW, d), HEEL_ARM_LOW_W, lift = 0.4);
        }
        color(C_NEON) rear_band(side, dz(HEEL_NEON, d), 1.8, lift = 0.8);
    }
}

// ---- heel strip (observed in heel view: vertical orange bar) -------------
module heel_strip() {
    color(C_ORANGE) rear_panel(lift = 0.4, max_x = 30)
        rpoly([[-HEEL_STRIP_HW, HEEL_STRIP_Z[0]], [HEEL_STRIP_HW, HEEL_STRIP_Z[0]],
               [HEEL_STRIP_HW, HEEL_STRIP_Z[1]], [-HEEL_STRIP_HW, HEEL_STRIP_Z[1]]], 4);
    heel_wrap();
}

// ---- eyestay top plates + lace loops -------------------------------------
// Loop stations along the eyestay (x observed). Their height is LINKED to the
// upper's rim (up_zt) so they stay seated when the station table changes;
// the second column is the observed reference height, kept for checking.
LOOPS = [[122, 124], [150, 108], [172, 99], [194, 92], [214, 86]];
LOOP_SIZE = [9, 5, 6];

function loop_pos(i, side) = [LOOPS[i][0], side * (open_hw(LOOPS[i][0]) + 2.5), up_zt(LOOPS[i][0]) - 2];

module eyestay() {
    for (side = [-1, 1]) {
        // top plate with a lace hole (observed)
        color(C_ORANGE) difference() {
            side_patch(side, [[92, 106], [96, 130], [121, 132], [124, 108]], lift = 0.4, r = 4);
            translate([100, 0, 122]) rotate([90, 0, 0]) cylinder(d = 3, h = 200, center = true);
        }
        // webbing lace loops
        for (i = [1 : len(LOOPS) - 1])
            color(C_ORANGE) translate(loop_pos(i, side))
                rotate([0, tslope_deg(UP, LOOPS[i][0], 1), 0])
                    hull() {
                        cube([LOOP_SIZE[0], 1, LOOP_SIZE[2]], center = true);
                        translate([0, side * LOOP_SIZE[1], 0]) cube([LOOP_SIZE[0] - 2, 1, LOOP_SIZE[2] - 2], center = true);
                    }
    }
}

module panels() { lateral_cage(); cougar_logo(); medial_chevron(); heel_strip(); eyestay(); }

// --------------------------------------------------------------------------
// 5. HARDWARE — laces (observed: criss-cross through 5 stations)
// --------------------------------------------------------------------------
// Laces are flat woven ribbon (~7 x 1.5 mm), pulled taut: every run between
// two loops is a straight flat strip whose face follows the tongue surface.
LACE_W = 7;      // ribbon width (inferred, typical flat trail lace)
LACE_T = 1.5;    // ribbon thickness
LACE_LIFT = 1.2; // ribbon centre above the rim (tongue top is at up_zt - 0.5)

// flat strip between a and b; n = face normal (unit-ish), width across d x n
module ribbon(a, b, n = [0, 0, 1], w = LACE_W, t = LACE_T) {
    d = b - a;
    u = cross(n, d); u1 = u / norm(u);
    n1 = n / norm(n);
    hull() for (p = [a, b], sw = [-1, 1], sn = [-1, 1])
        translate(p + sw * (w / 2) * u1 + sn * (t / 2) * n1) cube(0.2, center = true);
}
module ribbon_path(pts, n = [0, 0, 1], w = LACE_W, t = LACE_T) {
    for (i = [0 : len(pts) - 2]) ribbon(pts[i], pts[i + 1], n, w, t);
}

// local frame on the tongue surface at x: tangent along x, outward normal
function lace_s(x) = tslope_deg(UP, x, 1);
function lace_e(x) = let(s = lace_s(x)) [cos(s), 0, sin(s)];
function lace_n(x) = let(s = lace_s(x)) [-sin(s), 0, cos(s)];
// ribbon centre height: above the rim, or above the tongue where it rises
function lace_z(x) = up_zt(x) + max(LACE_LIFT, tval(TONGUE, x, 1) + LACE_T / 2 + 0.3);

module laces() {
    color(C_LACE) {
        // criss-cross runs, loop i (one side) -> loop i+1 (other side); a mid
        // point keeps the taut strip on the (convex) tongue surface
        for (i = [0 : len(LOOPS) - 2]) for (side = [-1, 1]) {
            xa = LOOPS[i][0]; xb = LOOPS[i + 1][0]; xm = (xa + xb) / 2;
            a = [xa, side * (open_hw(xa) + 1), lace_z(xa)];
            b = [xb, -side * (open_hw(xb) + 1), lace_z(xb)];
            m = [xm, (a[1] + b[1]) / 2, lace_z(xm)];
            ribbon_path([a, m, b], lace_n(xm));
        }
        // tied bow at the top eyestay (observed): knot, two flat loops, two ends
        kx = LOOPS[0][0] - 6;      // knot sits on the tongue just in front of its peak
        k = [kx, 0, up_zt(kx) + tval(TONGUE, kx, 1) + LACE_T / 2];
        e = lace_e(kx); n = lace_n(kx); ey = [0, 1, 0];
        translate(k + 0.5 * n) scale([1.3, 1, 0.55]) sphere(4);
        for (side = [-1, 1]) {
            // loop = ellipse (11 x 7 mm semi-axes) hanging heelward over the
            // tongue peak and drooping slightly (observed: loops span x~85-110)
            ribbon_path([for (t = [0 : 20 : 360])
                k + side * (8 + 7 * sin(t)) * ey + (11 * cos(t) - 11) * e
                  + (0.3 - 3 * (1 - cos(t))) * n], n, LACE_W - 1, LACE_T);
            // free end running down the eyestay
            ribbon_path([k + side * 3 * ey + 1 * e, k + side * 13 * ey + 10 * e - 1 * n,
                         k + side * 20 * ey + 20 * e - 4 * n], n, LACE_W, LACE_T);
        }
    }
}

// --------------------------------------------------------------------------
// 6. ASSEMBLY
// --------------------------------------------------------------------------
module shoe() { sole(); upper(); panels(); laces(); }

module select(part) {
    if (part == "all")          shoe();
    else if (part == "midsole") midsole();
    else if (part == "lugs")    lugs();
    else if (part == "toe_cap") toe_cap();
    else if (part == "upper")   upper_shell();
    else if (part == "collar")  collar();
    else if (part == "tongue")  tongue();
    else if (part == "lateral_cage") lateral_cage();
    else if (part == "medial_chevron") medial_chevron();
    else if (part == "heel_strip") heel_strip();
    else if (part == "eyestay") eyestay();
    else if (part == "laces")   laces();
    else if (part == "logo")    cougar_logo();
    else if (part == "sole")    sole();
    else if (part == "silhouette") { midsole(); upper_shell(); tongue(); }
}

// shift so that the reference ground line (lug tips) lies on z = 0
translate([0, 0, -REF_GROUND]) select(part);
