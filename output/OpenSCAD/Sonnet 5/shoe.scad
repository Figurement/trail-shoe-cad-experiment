// =====================================================================
// Cougar Trail — reference-based trail running shoe (right foot)
// Modeled in OpenSCAD from input/left-view.jpg and input/three-angles.jpg
//
// STRUCTURE (top to bottom of this file):
//   1. Global parameters               — the few numbers a human is meant
//                                         to tune (sizes, stack heights,
//                                         panel positions, colors).
//   2. Last / footprint driving curves — functions describing the
//                                         silhouette and stack height as a
//                                         function of length position.
//                                         Editing these re-shapes the
//                                         whole shoe.
//   3. Generic loft/sweep engine       — builds a solid from a stack of
//                                         cross-section rings (real
//                                         sweep, not a hand sculpted
//                                         blob).
//   4. Sole group (outsole + midsole)  — lofted from the driving curves,
//                                         plus a lug array on the bottom.
//   5. Upper group (mesh body + last)  — lofted last-shaped body plus
//                                         overlay panels, tongue, collar.
//   6. Hardware (eyelets + laces)
//   7. Assembly + material color groups
//   8. View presets used by render_views.sh for the comparison loop
//
// FIXED / NOT PARAMETRICALLY LINKED:
//   - Panel boundary curves (Section 5) are hand-authored polylines
//     traced from the reference photos. They are geometric guesses at
//     an inferred construction, not measured or manufacturing data.
//   - Lug layout (Section 4) is an inferred repeating pattern, not a
//     digitized tooling drawing.
// =====================================================================

/* ---------------------------------------------------------------
   1. GLOBAL PARAMETERS
   --------------------------------------------------------------- */
length            = 290;   // heel-back to toe-tip, mm (~US men's 9)
forefoot_width    = 108;   // widest point of footprint (ball of foot)
heel_width        = 82;    // width across heel
waist_width       = 74;    // narrowest point at the arch/waist
heel_stack        = 32;    // midsole+outsole stack height under heel
forefoot_stack    = 20;    // stack height under ball of foot
outsole_thk       = 8;     // outsole (lugged) thickness, included in stack
midsole_top_flat  = 6;     // extra flat rim of midsole above foot-bed edge
toe_rocker_rise   = 10;    // how far the sole tip curls upward
heel_rocker_rise  = 5;     // how far the sole rear curls upward
upper_collar_h    = 78;    // ankle collar height above ground at heel
upper_toe_h       = 46;    // toe-box height above ground at toe
$fn = 40;

/* ---------------------------------------------------------------
   2. LAST / FOOTPRINT DRIVING CURVES
   x runs 0 (heel back) .. length (toe tip)
   --------------------------------------------------------------- */

// normalized position helper
function u(x) = x / length;

// half-width of the footprint silhouette at length position x
// (heel rounded -> waist pinches in -> forefoot flares -> toe tapers)
function footprint_halfwidth(x) =
    let(t = u(x))
    t < 0.14 ? (heel_width/2) * (0.55 + 0.45*sin(t/0.14*90))                       // rounded heel
  : t < 0.40 ? (heel_width/2) - (heel_width-waist_width)/2 * ((t-0.14)/0.26)       // heel -> waist taper
  : t < 0.62 ? (waist_width/2) + (forefoot_width-waist_width)/2 * ((t-0.40)/0.22) // waist -> ball flare
  : t < 0.86 ? (forefoot_width/2)                                                  // ball, roughly constant
  : (forefoot_width/2) * (1 - pow((t-0.86)/0.14, 1.6)) + 3;                        // taper to toe tip

// stack height (ground to top of midsole rim) at length position x
function stack_height(x) =
    let(t = u(x))
    t < 0.30 ? heel_stack
  : t < 0.62 ? heel_stack - (heel_stack-forefoot_stack) * ((t-0.30)/0.32)
  : forefoot_stack;

// sole bottom (ground contact) height at length position x — 0 except
// where the toe rocker and heel-strike bevel curl the sole off the ground
function sole_bottom(x) =
    let(t = u(x))
    t > 0.78 ? toe_rocker_rise * pow((t-0.78)/0.22, 1.8)         // toe rocker: sole stays
                                                                  // flat through the
                                                                  // midfoot/forefoot, then
                                                                  // curls up smoothly over
                                                                  // roughly the last fifth,
                                                                  // matching the reference's
                                                                  // moderate meta-rocker
  : t < 0.05 ? heel_rocker_rise * pow(1 - t/0.05, 2.2)            // heel-strike bevel: a
                                                                  // small, tightly-radiused
                                                                  // corner curl, not a long
                                                                  // visible rocker
  : 0;

// upper last height (top of the foot-following upper surface) above
// ground at length position x — the collar at the heel, dropping to
// the toe box height at the front
function upper_top_height(x) =
    let(t = u(x))
    t < 0.18 ? upper_collar_h
  : t < 0.55 ? upper_collar_h - (upper_collar_h-upper_toe_h*1.15) * ((t-0.18)/0.37)
  : t < 0.90 ? upper_toe_h
  : upper_toe_h * (1 - pow((t-0.90)/0.10, 1.4));   // slope down to meet the toe tip

/* ---------------------------------------------------------------
   3. GENERIC LOFT / SWEEP ENGINE
   Builds a solid polyhedron by skinning a stack of same-size rings.
   rings = [ [ [x,y,z], ... n pts ], ... m rings ]
   --------------------------------------------------------------- */
module loft_solid(rings) {
    m = len(rings);
    n = len(rings[0]);
    pts = [ for (r = rings) for (p = r) p ];

    side_faces = [
        for (i = [0:m-2], j = [0:n-1])
            each [
                [ i*n+j, i*n+(j+1)%n, (i+1)*n+(j+1)%n ],
                [ i*n+j, (i+1)*n+(j+1)%n, (i+1)*n+j ]
            ]
    ];
    cap0 = [ [ for (j=[n-1:-1:0]) j ] ];       // heel end cap (reversed winding)
    cap1 = [ [ for (j=[0:n-1]) (m-1)*n+j ] ];  // toe end cap

    polyhedron(points = pts, faces = concat(side_faces, cap0, cap1), convexity = 10);
}

// one rounded-rectangle style cross-section ring in the Y-Z plane at
// length position x, from z0 (bottom) to z1 (top), half-width hw,
// built as a superellipse so it stays symmetric left/right and
// top/bottom; round_f near 1 -> ellipse, near 0 -> boxy rounded rect
function cross_ring(x, hw, z0, z1, round_f=0.35, n=16) =
    let(
        hmid = (z0+z1)/2,
        hh   = (z1-z0)/2,
        p    = 2 + (1-round_f)*6
    )
    [ for (k = [0:n-1])
        let(a = k/n*360)
        let(c = cos(a), s = sin(a))
        let(sc = c==0 ? 0 : (c>0?1:-1)*pow(abs(c), 2/p))
        let(ss = s==0 ? 0 : (s>0?1:-1)*pow(abs(s), 2/p))
        [ x, hw*sc, hmid + hh*ss ]
    ];

/* ---------------------------------------------------------------
   4. SOLE GROUP
   --------------------------------------------------------------- */
sole_slices = 44;

function midsole_ring(i) =
    let(
        x  = length * i/(sole_slices-1),
        hw = footprint_halfwidth(x) * 1.06,       // midsole slightly proud of upper
        z0 = sole_bottom(x),
        z1 = z0 + stack_height(x)
    )
    cross_ring(x, hw, z0, z1, round_f=0.30, n=16);

function outsole_ring(i) =
    let(
        x  = length * i/(sole_slices-1),
        hw = footprint_halfwidth(x) * 1.09,        // outsole is the widest layer
        z0 = sole_bottom(x),
        z1 = z0 + min(outsole_thk, stack_height(x)*0.4)
    )
    cross_ring(x, hw, z0, z1, round_f=0.22, n=16);

// midsole is lofted in two overlapping halves so it can carry the
// heel-blue -> forefoot-lime two-tone seen in the reference photos
module midsole() {
    split_i = round(sole_slices*0.52);
    rings_a = [ for (i=[0:split_i+1]) midsole_ring(i) ];      // heel/arch half
    rings_b = [ for (i=[split_i:sole_slices-1]) midsole_ring(i) ]; // forefoot half
    color([0.18,0.52,0.86]) loft_solid(rings_a);
    color([0.55,0.86,0.20]) loft_solid(rings_b);
}

// raised "flow wave" rib traced along the midsole sidewall — the
// reference photos show a stylized contour line swept the length of
// the midsole (rising near the heel/arch, dipping through the waist);
// modeled here as a proud rib rather than a flat printed line since
// OpenSCAD can't fake a surface highlight without real geometry.
function midsole_wave_point(x, s) =
    let(
        hw    = footprint_halfwidth(x) * 1.05,
        z0    = sole_bottom(x),
        h     = stack_height(x),
        zfrac = 0.30 + 0.20*sin(x/length*200 + 15)
    )
    [x, s*hw, z0 + zfrac*h];

module midsole_wave_ridge() {
    for (s = [1,-1]) {
        pts = [ for (t=[0.05:0.02:0.95]) midsole_wave_point(length*t, s) ];
        color([0.32,0.66,0.92]) panel_ribbon(pts, w=3.5, t=3.2);
    }
}

module outsole_base() {
    rings = [ for (i=[0:sole_slices-1]) outsole_ring(i) ];
    loft_solid(rings);
}

// simple lug: a low truncated pyramid
module lug(w=6, l=8, h=3) {
    hull() {
        translate([0,0,0.2]) cube([l,w,0.4], center=true);
        translate([0,0,h]) cube([l*0.7,w*0.7,0.4], center=true);
    }
}

module outsole_lugs() {
    rows = 12;
    for (i = [0:rows-1]) {
        x = length * (0.04 + 0.90*i/(rows-1));
        hw = footprint_halfwidth(x);
        z  = sole_bottom(x);
        cols = (hw > forefoot_width*0.42) ? 4 : 3;
        for (c = [0:cols-1]) {
            yfrac = (c+0.5)/cols*2-1;              // -1..1 across the width
            y  = yfrac * hw * 0.86;
            ang = 8*yfrac + (i%2)*6 - 3;
            translate([x, y, z])
                rotate([0,0,ang])
                    lug(w=hw*0.34, l=length*0.05, h=4.2);
        }
    }
}

module outsole() {
    intersection() {
        union() {
            color([0.15,0.15,0.17]) outsole_base();
            color([0.90,0.35,0.20]) outsole_lugs();
        }
        // keep lugs from poking out past the outsole footprint silhouette
        scale([1,1.2,1]) outsole_base();
    }
}

module sole_group() {
    midsole();
    outsole();
    midsole_wave_ridge();
}

/* ---------------------------------------------------------------
   5. UPPER GROUP
   --------------------------------------------------------------- */
upper_slices = 44;

// upper last cross-section: sits on top of the midsole rim and rises
// to the collar/toe-box heights, tapering inward slightly (draft) as
// it goes up so the foot-box reads as a soft dome rather than a wall
function upper_ring(i) =
    let(
        x   = length * i/(upper_slices-1),
        hw  = footprint_halfwidth(x) * 0.94,
        z0  = sole_bottom(x) + stack_height(x) - 1.5,   // seat into midsole rim
        z1  = z0 + max(upper_top_height(x), 3)
    )
    cross_ring(x, hw, z0, z1, round_f=0.55, n=16);

module upper_body() {
    rings = [ for (i=[0:upper_slices-1]) upper_ring(i) ];
    color([0.05,0.32,0.42])
        difference() {
            loft_solid(rings);
            collar_opening_cutter();
        }
}

// scoops the foot-entry opening out of the top of the upper, from the
// heel collar forward through the lace throat; the toe box ahead of
// the throat is left solid (closed toe cap)
module collar_opening_cutter() {
    pts = [ for (t=[0.01:0.03:0.66])
        let(x = length*t)
        let(taper = t < 0.10 ? t/0.10 : (t > 0.55 ? (0.66-t)/0.11 : 1))
        let(hw = footprint_halfwidth(x) * 0.72 * taper)
        let(z0 = sole_bottom(x) + stack_height(x) - 1.5)
        let(ztop = z0 + upper_top_height(x))
        [x, hw, z0, ztop, taper]
    ];
    for (i = [0:len(pts)-2]) {
        p0 = pts[i]; p1 = pts[i+1];
        depth0 = (p0[3]-p0[2]) * 0.60 * p0[4];
        depth1 = (p1[3]-p1[2]) * 0.60 * p1[4];
        hull() {
            translate([p0[0], 0, p0[3] - depth0/2 + 2])
                cube([length*0.032, p0[1]*1.9, depth0+4], center=true);
            translate([p1[0], 0, p1[3] - depth1/2 + 2])
                cube([length*0.032, p1[1]*1.9, depth1+4], center=true);
        }
    }
}

// --- Panel overlays: hand-traced polylines following the reference
// photos, extruded as thin raised ribbons glued to the upper surface.
// These are inferred construction lines, not measured data.

function panel_offset_point(x, yfrac, zfrac) =
    let(
        hw = footprint_halfwidth(x) * 0.95,
        z0 = sole_bottom(x) + stack_height(x) - 1.5,
        z1 = z0 + upper_top_height(x)
    )
    [x, yfrac*hw, z0 + zfrac*(z1-z0)];

module panel_ribbon(pts, w=6, t=1.6) {
    // sweep a small rounded rectangle cross-section along a 3D polyline
    for (i = [0:len(pts)-2]) {
        p0 = pts[i]; p1 = pts[i+1];
        d  = p1 - p0;
        len_seg = norm(d);
        // orient a box from p0 to p1
        yaw   = atan2(d[1], d[0]);
        pitch = -atan2(d[2], sqrt(d[0]*d[0]+d[1]*d[1]));
        translate(p0)
            rotate([0,0,yaw]) rotate([0,pitch,0])
                translate([len_seg/2,0,0])
                    cube([len_seg+0.5, w, t], center=true);
    }
}

// stylized leaping-cougar brand emblem — a simplified silhouette decal
// (traced by eye from the reference photo's logo mark, not a precise
// vector reproduction), sitting proud of the panel like a printed/
// embroidered badge. Faces toward the toe (+x).
cougar_pts = [
    [-2.2,-1.0], [-0.6, 0.8], [ 0.2, 2.0], [-0.5, 3.0], [ 0.3, 3.6],
    [ 1.1, 3.0], [ 2.0, 3.4], [ 5.0, 4.0], [ 9.0, 3.2], [12.0, 3.8],
    [14.0, 2.8], [17.5, 4.2], [19.0, 3.4], [16.0, 2.0], [13.0, 0.4],
    [15.0,-3.4], [13.4,-4.0], [11.0,-0.9], [ 7.0,-0.7], [ 4.0,-1.1],
    [ 1.0,-2.8], [-1.0,-3.8], [-2.2,-3.1], [ 0.2,-0.9]
];

module cougar_emblem() {
    rotate([90,0,0])
        linear_extrude(height=1.2, center=true)
            scale(2.0) polygon(points = cougar_pts);
}

module emblems() {
    // lateral + medial, sitting centrally on top of the coral swoosh,
    // bigger and higher than the first pass so it reads clearly like
    // the reference's mid-panel leaping-cat mark
    for (s = [1,-1]) {
        p = panel_offset_point(length*0.53, s, 0.50);
        color([0.92,0.94,0.95])
            translate(p) translate([0, s*2.4, 0])
                rotate([0,8,0])
                    scale(1.5) cougar_emblem();
    }
}

// toe bumper — a full wrap-around cap (not just a side ribbon) proud
// of the last, closing over the top-front of the toe box like the
// coral rand seen in the reference photos
function toecap_ring(i, n) =
    let(
        t   = 0.80 + 0.20*i/(n-1),
        x   = length*t,
        hw  = footprint_halfwidth(x) * 0.94 * 1.01,
        z0  = sole_bottom(x) + stack_height(x) - 1.8,
        z1  = z0 + max(upper_top_height(x), 0.6) + 0.4
    )
    cross_ring(x, hw, z0, z1, round_f=0.5, n=16);

module toecap_wrap() {
    n = 10;
    rings = [ for (i=[0:n-1]) toecap_ring(i, n) ];
    color([0.95,0.35,0.25]) loft_solid(rings);
}

module overlay_panels() {
    // lateral coral swoosh: a bold angular "flame" from the heel/arch
    // up through the midfoot to a flared lace-eyestay wing tab, traced
    // as a hand-picked set of sharp waypoints rather than a smooth
    // sine curve so it reads as angular tooling, not a soft ribbon
    swoosh_wp = [ [0.05,0.28],[0.10,0.62],[0.15,0.38],[0.21,0.68],
                  [0.28,0.44],[0.35,0.72],[0.43,0.48],[0.50,0.70],
                  [0.58,0.58],[0.63,0.72] ];
    swoosh   = [ for (p=swoosh_wp) panel_offset_point(length*p[0],  1.0, p[1]) ];
    swoosh_m = [ for (p=swoosh_wp) panel_offset_point(length*p[0], -1.0, p[1]) ];
    color([0.95,0.35,0.25]) panel_ribbon(swoosh,   w=15, t=2.6);
    color([0.95,0.35,0.25]) panel_ribbon(swoosh_m, w=15, t=2.6);

    // eyestay wing tabs flaring off the top of the swoosh toward the
    // lace throat, echoing the reference's coral loop backing
    for (s = [1,-1]) {
        wing = [ panel_offset_point(length*0.58, s, 0.62),
                 panel_offset_point(length*0.66, s, 0.80),
                 panel_offset_point(length*0.60, s, 0.90) ];
        color([0.95,0.35,0.25]) panel_ribbon(wing, w=8, t=2.4);
    }

    // toe cap / toe bumper (protective coral overlay wrapping the tip)
    toecap_wrap();

    // thin coral pinstripe tracing the top edge of the midsole for
    // nearly the full length of the shoe
    pinstripe   = [ for (t=[0.04:0.02:0.94]) panel_offset_point(length*t,  1.0, 0.05) ];
    pinstripe_m = [ for (t=[0.04:0.02:0.94]) panel_offset_point(length*t, -1.0, 0.05) ];
    color([0.95,0.35,0.25]) panel_ribbon(pinstripe,   w=3, t=1.2);
    color([0.95,0.35,0.25]) panel_ribbon(pinstripe_m, w=3, t=1.2);

    // dark underlay accent: a narrow angular dagger tucked just below
    // the swoosh, tapering to a point toward the front (near-black)
    underlay_wp = [ [0.08,0.18],[0.13,0.44],[0.19,0.26],[0.25,0.48],
                     [0.32,0.30],[0.39,0.12] ];
    underlay = [ for (p=underlay_wp) panel_offset_point(length*p[0], 1.0, p[1]) ];
    color([0.08,0.09,0.10]) panel_ribbon(underlay, w=5, t=1.8);

    // heel counter rear wrap: a vertical coral pull-tab stripe running
    // down the back of the heel, flanked by angular black wing panels
    // with a thin lime pinstripe along their inner edge — traced from
    // the reference's rear-view shot, not measured
    heel_stripe = [ for (zf=[0.85:-0.05:0.28]) panel_offset_point(length*0.015, 0, zf) ];
    color([0.95,0.35,0.25]) panel_ribbon(heel_stripe, w=9, t=2.8);

    for (s = [1,-1]) {
        heel_wing = [ panel_offset_point(length*0.015, s*0.30, 0.80),
                      panel_offset_point(length*0.020, s*0.42, 0.62),
                      panel_offset_point(length*0.032, s*0.34, 0.46),
                      panel_offset_point(length*0.022, s*0.46, 0.30) ];
        color([0.08,0.09,0.10]) panel_ribbon(heel_wing, w=7, t=2.2);

        heel_accent = [ panel_offset_point(length*0.022, s*0.50, 0.64),
                        panel_offset_point(length*0.028, s*0.50, 0.36) ];
        color([0.55,0.86,0.20]) panel_ribbon(heel_accent, w=2.5, t=1.6);
    }
}

module tongue() {
    // simple padded tongue slab sitting in the lace gap on top of the foot
    color([0.05,0.32,0.42])
    for (t = [0.20:0.03:0.55]) {
        x = length*t;
        p = panel_offset_point(x, 0, 0.95);
        translate(p) cube([length*0.03+1, 26, 3], center=true);
    }
}

module upper_group() {
    upper_body();
    overlay_panels();
    emblems();
    tongue();
}

/* ---------------------------------------------------------------
   6. HARDWARE — EYELETS + LACES
   --------------------------------------------------------------- */
n_eyelets = 5;

function eyelet_pos(i) =
    let(t = 0.24 + i*0.065)
    panel_offset_point(length*t, 1.0, 0.80 + i*0.015);

// flat, woven-fabric lace segment between two 3D points — a thin flat
// ribbon (not a round cord), with an optional roll/twist so adjacent
// crossing segments read as flat tape rather than round rope
module flat_lace(p0, p1, w=4.2, t=1.0, twist=0) {
    d = p1 - p0;
    seg = norm(d);
    yaw   = atan2(d[1], d[0]);
    pitch = -atan2(d[2], sqrt(d[0]*d[0]+d[1]*d[1]));
    translate(p0)
        rotate([0,0,yaw]) rotate([0,pitch,0]) rotate([twist,0,0])
            translate([seg/2,0,0])
                cube([seg, w, t], center=true);
}

module eyelets() {
    color([0.1,0.1,0.1])
    for (i=[0:n_eyelets-1]) {
        for (s = [1,-1]) {
            p = eyelet_pos(i); p2 = [p[0], s*abs(p[1]), p[2]];
            translate(p2) rotate([0,90,0]) cylinder(h=4, r=2.6, center=true);
        }
    }
}

module laces() {
    color([0.15,0.45,0.55])
    for (i=[0:n_eyelets-2]) {
        pA = eyelet_pos(i);   pB = eyelet_pos(i+1);
        a1 = [pA[0], -abs(pA[1]), pA[2]];
        a2 = [pB[0],  abs(pB[1]), pB[2]];
        b1 = [pA[0],  abs(pA[1]), pA[2]];
        b2 = [pB[0], -abs(pB[1]), pB[2]];
        // opposite roll on each crossing strand so the flat weave
        // catches light differently, like real laces do as they cross
        flat_lace(a1, a2, twist=22);
        flat_lace(b1, b2, twist=-22);
    }
    // free lace ends: flat ribbon tails with a slight relaxed bend,
    // knotted/tucked look instead of a stiff round cylinder
    pTop = eyelet_pos(n_eyelets-1);
    for (s=[1,-1]) {
        mid = [pTop[0]+9,  s*abs(pTop[1])*0.7, pTop[2]+5];
        tip = [pTop[0]+16, s*abs(pTop[1])*0.55, pTop[2]-2];
        flat_lace([pTop[0], s*abs(pTop[1]), pTop[2]], mid, w=4.2, t=1.0, twist=s*15);
        flat_lace(mid, tip, w=3.6, t=0.9, twist=s*30);
    }
}

/* ---------------------------------------------------------------
   7. ASSEMBLY
   --------------------------------------------------------------- */
module shoe() {
    sole_group();
    upper_group();
    eyelets();
    laces();
}

shoe();
