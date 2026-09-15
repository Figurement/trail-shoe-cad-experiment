/*
Reference-based trail shoe. Native, linked OpenSCAD construction; units: mm.
Edit dimensions, station tables and 2D panel sketches, not generated vertices.
Photos have no scale: dimensions, last, wall thickness and underside are inferred.
See MODEL_GUIDE.txt. No scanned/anatomically validated last is supplied.
*/

/* [Driving dimensions] */
shoe_length = 300;
width_scale = 1;
upper_height_scale = 1;
sole_height_scale = 1;
upper_wall = 2.4;
panel_thickness = 0.9;
collar_padding = 2.7;
lace_diameter = 3.2;
lug_depth = 4.5;

/* [Presentation] */
// 1: silhouette; 2: panels; 3: hardware and traction
stage = 3;
// all, midsole, outsole, upper, collar, tongue, panels, eyelets, laces, heel_webbing
part = "all";
quality = 1;
show_reference_last = false;

/* [Hidden] */
$fn = quality == 0 ? 12 : 24;
long_steps = quality == 0 ? 56 : 100;
ring_steps = quality == 0 ? 40 : 72;
curve_steps = quality == 0 ? 5 : 9;
textile_color = [0.38, 0.49, 0.53];
sole_color = [0.76, 0.78, 0.75];
rubber_color = [0.19, 0.23, 0.25];
panel_color = [0.65, 0.58, 0.48];
support_color = [0.26, 0.32, 0.35];
lace_color = [0.82, 0.81, 0.75];

// Heel -> toe: x, centre y, half-width, upper/sole join z, dome height.
// This is a photo-inferred last, NOT a fit or manufacturing specification.
last_sections = [
    [-1, 0, 0.7, 47, 1],
    [3, 0, 17, 47, 34],
    [12, 0, 30, 46, 62],
    [24, 0, 36, 44, 79],
    [42, 0, 38, 42, 78],
    [65, 1, 35.5, 39, 72],
    [88, 1, 34, 36, 76],
    [110, 0, 36, 34, 74],
    [139, -1, 41, 32, 66],
    [168, -2, 46, 32, 54],
    [201, -2, 48, 33, 44],
    [231, -1, 44, 36, 35],
    [258, 1, 35, 40, 27],
    [279, 2, 24, 46, 17],
    [293, 2, 12, 51, 6],
    [298, 2, 0.7, 53, 1]
];

// Organic plan sketch; unlike a stadium/capsule it has a recessed waist.
sole_outline = [
    [-6,0],[-4,-23],[10,-37],[37,-42],[77,-39],[112,-38],
    [146,-45],[187,-52],[222,-51],[253,-43],[280,-30],[296,-15],
    [300,2],[295,19],[279,35],[252,47],[218,53],[183,51],
    [148,43],[113,35],[78,37],[40,43],[12,38],[-4,24]
];
sole_levels = [0, 0.06, 0.21, 0.43, 0.55, 0.61, 0.68, 0.82, 0.94, 1];
sole_flare = [0.985, 1.013, 1.032, 1.013, 0.974, 0.966, 0.991, 0.983, 0.963, 0.947];
sole_profile = [
    [-10,15,48],[0,13,49],[25,10,47],[60,8,42],[100,7,37],
    [140,7,34],[180,8,34],[215,10,36],[246,15,40],
    [270,23,46],[288,33,53],[305,42,58]
];
collar_sketch = [
    [23,0],[27,-18],[44,-32],[65,-30],[84,-24],[99,-13],
    [103,1],[94,18],[75,30],[51,33],[34,25],[26,14]
];
tongue_sections = [
    [79,14,19],[84,22,23],[94,25,20],[111,24,12],
    [135,22,5],[158,20,3],[181,17,2],[198,10,1],[202,0.8,0.8]
];

// Cubic interpolants are evaluated from editable control sections.
function mix(a,b,t) = a*(1-t)+b*t;
function clamp(v,a,b) = min(max(v,a),b);
function catmull(a,b,c,d,t) =
    (2*b+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)/2;
function interval(rows,x,i=0) =
    i >= len(rows)-2 || x < rows[i+1][0] ? i : interval(rows,x,i+1);
function field(rows,x,col) =
    let(i=interval(rows,x), t=clamp((x-rows[i][0])/(rows[i+1][0]-rows[i][0]),0,1))
    catmull(rows[max(0,i-1)][col],rows[i][col],
            rows[i+1][col],rows[min(len(rows)-1,i+2)][col],t);
function closed_curve(pts,n=curve_steps) = [
    for(i=[0:len(pts)-1], j=[0:n-1])
        catmull(pts[(i+len(pts)-1)%len(pts)],pts[i],
                pts[(i+1)%len(pts)],pts[(i+2)%len(pts)],j/n)
];
function open_curve(pts,n=curve_steps) = concat([
    for(i=[0:len(pts)-2],j=[0:n-1])
        catmull(pts[max(0,i-1)],pts[i],pts[i+1],pts[min(len(pts)-1,i+2)],j/n)
], [pts[len(pts)-1]]);
function sole_bottom(x) = field(sole_profile,x,1);
function sole_top(x) = sole_bottom(x)+(field(sole_profile,x,2)-sole_bottom(x))*sole_height_scale;
function join_z(x) = field(last_sections,x,3)+sole_top(x)-field(sole_profile,x,2);
function last_width(x) = max(0.6,field(last_sections,x,2))*width_scale;
function centre_y(x) = field(last_sections,x,1)*width_scale;
function last_height(x) = max(0.5,field(last_sections,x,4))*upper_height_scale;
function upper_z(x,y) = join_z(x)+last_height(x)*
    pow(max(0,1-pow((y-centre_y(x))/last_width(x),2)),0.4);
function side_y(x,z,side=-1,offset=0) =
    centre_y(x)+side*(last_width(x)*
        sqrt(max(0,1-pow(clamp((z-join_z(x))/last_height(x),0,1),2.5)))+offset);
function selected(name) = part == "all" || part == name;

// A reusable linked section loft. Ring order is preserved between sections.
module section_loft(rings) {
    n=len(rings); m=len(rings[0]);
    polyhedron(
        points=[for(r=rings) for(p=r) p],
        faces=concat(
            [[for(j=[m-1:-1:0]) j]],
            [for(i=[0:n-2],j=[0:m-1]) each [
                [i*m+j,i*m+(j+1)%m,(i+1)*m+(j+1)%m],
                [i*m+j,(i+1)*m+(j+1)%m,(i+1)*m+j]
            ]],
            [[for(j=[0:m-1]) (n-1)*m+j]]
        ), convexity=12
    );
}

module inferred_last(width_offset=0, height_offset=0, inset=0) {
    section_loft([
        for(i=[0:long_steps])
            let(x=mix(-1+inset,298-inset,i/long_steps),
                w=max(0.25,last_width(x)+width_offset),
                h=max(0.3,last_height(x)+height_offset))
            [for(j=[0:ring_steps-1])
                let(a=360*j/ring_steps)
                [x,centre_y(x)+w*cos(a),
                 join_z(x)+(sin(a)>=0 ? h*pow(sin(a),0.8) : 2*sin(a))]
            ]
    ]);
}

module midsole() {
    outline=closed_curve(sole_outline);
    section_loft([
        for(k=[0:len(sole_levels)-1])
            let(t=sole_levels[k])
            [for(p=outline)
                let(x=150+(p[0]-150)*mix(1,0.968,t),
                    // Gentle longitudinal sculpting, not a color-band split.
                    wave=sin(clamp((p[0]-20)/270,0,1)*180)*sin(t*180)*1.2)
                [x,p[1]*width_scale*sole_flare[k],
                 mix(sole_bottom(p[0]),sole_top(p[0]),t)+wave]]
    ]);
}

module outsole_carrier() {
    outline=closed_curve(sole_outline);
    section_loft([
        for(k=[0:2])
            [for(p=outline)
                [150+(p[0]-150)*(k==0 ? 0.993 : 1),
                 p[1]*width_scale*(k==0 ? 0.971 : 0.985),
                 sole_bottom(p[0])+(k==0 ? -2.6 : k==1 ? -1.8 : 0.35)]]
    ]);
}

module upper() {
    difference() {
        inferred_last();
        translate([0,0,upper_wall])
            inferred_last(-upper_wall,-2*upper_wall,upper_wall);
        translate([0,0,78])
            linear_extrude(height=150)
                polygon([for(p=closed_curve(collar_sketch)) [p[0],p[1]*width_scale]]);
    }
}

module sweep_round(path,r,closed=false) {
    for(i=[0:len(path)-(closed ? 1 : 2)])
        hull() {
            translate(path[i]) sphere(r=r);
            translate(path[(i+1)%len(path)]) sphere(r=r);
        }
}

module collar() {
    path=[for(p=closed_curve(collar_sketch,quality==0 ? 3 : 5))
        [p[0],p[1]*width_scale,upper_z(p[0],p[1]*width_scale)]];
    sweep_round(path,collar_padding,true);
}

function tongue_z(x,y) = upper_z(x,y)+field(tongue_sections,x,2);
module tongue() {
    // Each transverse sketch follows the inferred last and an editable lift.
    section_loft([
        for(i=[0:36])
            let(x=mix(79,202,i/36),w=field(tongue_sections,x,1)*width_scale)
            concat(
                [for(j=[0:20]) let(y=mix(-w,w,j/20)) [x,y,tongue_z(x,y)]],
                [for(j=[20:-1:0]) let(y=mix(-w,w,j/20)) [x,y,tongue_z(x,y)-2.3]]
            )
    ]);
}

module shoe() {
    if(selected("midsole")) color(sole_color) midsole();
    if(selected("outsole")) color(rubber_color) outsole_carrier();
    if(selected("upper")) color(textile_color) upper();
    if(selected("collar")) color(support_color) collar();
    if(selected("tongue")) color(textile_color) tongue();
    if(show_reference_last) %inferred_last();
}

scale([shoe_length/306,shoe_length/306,shoe_length/306]) shoe();
