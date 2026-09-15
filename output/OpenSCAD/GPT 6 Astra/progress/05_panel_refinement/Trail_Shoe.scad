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
    [88, 1, 34, 36, 86],
    [110, 0, 36, 34, 91],
    [139, -1, 41, 32, 79],
    [168, -2, 46, 32, 64],
    [201, -2, 48, 33, 47],
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
    [23,0],[27,-16],[44,-27],[65,-26],[84,-22],[99,-13],
    [103,1],[94,18],[75,26],[51,28],[34,23],[26,14]
];
tongue_sections = [
    [79,14,13],[84,22,15],[94,25,13],[111,24,4],
    [135,22,5],[158,20,3],[181,17,2],[198,10,1],[202,0.8,0.8]
];

// Lateral side sketches: x, height above the nominal datum.
// These are separately shaped boundaries, NOT offset ribbons.
lateral_sweep = [
    [20,94],[40,91],[72,85],[103,81],[136,76],[162,68],[181,56],
    [201,33],[192,33],[178,52],[160,63],[132,72],[101,77],
    [72,81],[42,85],[23,88]
];
lateral_sweep_underlay = [
    [27,89],[63,82],[101,77],[135,72],[162,62],[178,49],[191,33],
    [166,32],[158,48],[141,59],[110,68],[79,75],[47,82],[29,85]
];
lateral_lower_frame = [
    [23,77],[46,73],[64,74],[89,68],[112,58],[118,49],[113,41],
    [106,34],[91,34],[100,44],[99,51],[86,58],[66,64],[63,60],
    [72,52],[90,35],[75,36],[53,52],[36,66],[42,56],[40,51],
    [20,43],[15,44],[32,56],[28,65]
];
lateral_heel_foundation = [
    [8,76],[22,75],[32,66],[41,56],[33,51],[19,45],
    [57,39],[89,34],[142,31],[143,45],[129,57],[104,66],
    [69,77],[27,88],[12,94]
];
lateral_mesh_window = [
    [68,64],[85,61],[105,53],[109,47],[103,41],[87,48],[72,57]
];
medial_quarter = [
    [18,91],[46,84],[66,86],[100,107],[107,108],[102,99],
    [83,81],[108,71],[143,59],[130,46],[116,32],[85,35],
    [96,49],[105,60],[77,72],[51,73],[25,77]
];
medial_window = [
    [57,77],[75,79],[97,68],[112,60],[104,51],[83,44],
    [75,52],[84,63]
];
medial_heel_frame = [
    [18,76],[27,76],[51,63],[76,47],[94,36],[78,37],
    [49,52],[28,66],[37,54],[32,50],[18,44],[12,45],
    [27,55],[22,65]
];
medial_heel_insert = [
    [10,76],[23,71],[33,57],[25,51],[16,46],[53,40],[86,35],
    [66,48],[42,65],[19,78]
];
// Each web ends at a real eyestay pad; side-specific sketches remain editable.
lateral_quarter_web = [
    [64,83],[91,98],[101,110],[111,109],[105,99],[91,87],
    [126,96],[139,101],[145,95],[125,84],[109,77],
    [149,84],[164,89],[172,82],[151,71],[136,63],
    [173,74],[190,77],[199,71],[174,62],[157,53],
    [147,48],[151,59],[126,69],[115,70],[101,76],[78,80]
];
toe_cap_sketch = [
    [236,-60],[239,-38],[253,-25],[265,0],[253,28],[238,43],
    [236,60],[280,65],[314,45],[319,0],[314,-45],[280,-65]
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
function strip_cap(m) = concat(
    [[0,1,m-1]],
    [for(j=[1:m/2-2]) each [
        [j,j+1,m-j-1],[j,m-j-1,m-j]
    ]],
    [[m/2-1,m/2,m/2+1]]
);
function reversed(v) = [for(i=[len(v)-1:-1:0]) v[i]];
module section_loft(rings,reverse=false,strip_caps=false) {
    n=len(rings); m=len(rings[0]);
    caps=strip_caps ? strip_cap(m) : [[for(j=[0:m-1]) j]];
    faces=concat(
        [for(f=caps) reversed(f)],
        [for(i=[0:n-2],j=[0:m-1]) each [
            [i*m+j,i*m+(j+1)%m,(i+1)*m+(j+1)%m],
            [i*m+j,(i+1)*m+(j+1)%m,(i+1)*m+j]
        ]],
        [for(f=caps) [for(j=f) (n-1)*m+j]]
    );
    polyhedron(
        points=[for(r=rings) for(p=r) p],
        faces=[for(f=faces) reverse ? reversed(f) : f], convexity=12
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
    ],reverse=true);
}

module midsole() {
    outline=closed_curve(sole_outline);
    flare_table=[for(k=[0:len(sole_levels)-1]) [sole_levels[k],sole_flare[k]]];
    section_loft([
        for(k=[0:36])
            let(t=k/36)
            [for(p=outline)
                let(x=150+(p[0]-150)*mix(1,0.981,t),
                    // Gentle longitudinal sculpting, not a color-band split.
                    wave=-4*sin(clamp((p[0]-30)/245,0,1)*180)*pow(sin(t*180),2))
                [x,p[1]*width_scale*field(flare_table,t,1),
                 mix(sole_bottom(p[0]),sole_top(p[0]),t)+wave]]
    ],reverse=true,strip_caps=true);
}

module outsole_carrier() {
    outline=closed_curve(sole_outline);
    section_loft([
        for(k=[0:2])
            [for(p=outline)
                [150+(p[0]-150)*(k==0 ? 0.993 : 1),
                 p[1]*width_scale*(k==0 ? 0.971 : 0.985),
                 sole_bottom(p[0])+(k==0 ? -2.6 : k==1 ? -1.8 : 0.35)]]
    ],reverse=true,strip_caps=true);
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

function tongue_z(x,y) = upper_z(x,y)+field(tongue_sections,x,2)*
    mix(1,pow(max(0,1-pow(y/(field(tongue_sections,x,1)*width_scale),2)),0.7),
        clamp((x-90)/25,0,1));
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

function linked_side_point(p) = [
    p[0],join_z(p[0])+(p[1]-field(last_sections,p[0],3))*upper_height_scale
];

module side_sketch(outline,holes=[]) {
    difference() {
        polygon([for(p=closed_curve(outline)) linked_side_point(p)]);
        for(hole=holes)
            polygon([for(p=closed_curve(hole)) linked_side_point(p)]);
    }
}

module last_skin(depth=panel_thickness) {
    difference() {
        inferred_last(depth,depth);
        inferred_last(-0.18,-0.18);
    }
}

module side_panel(outline,side=-1,holes=[],depth=panel_thickness) {
    intersection() {
        last_skin(depth);
        scale([1,-side,1])
            rotate([90,0,0])
                linear_extrude(height=85*width_scale,convexity=10)
                    side_sketch(outline,holes);
    }
}

module top_panel(outline,depth=panel_thickness) {
    intersection() {
        last_skin(depth);
        translate([0,0,40])
            linear_extrude(height=130)
                polygon([for(p=closed_curve(outline)) [p[0],p[1]*width_scale]]);
    }
}

module panels() {
    color(support_color) {
        side_panel(lateral_heel_foundation,-1,[lateral_mesh_window],0.6);
        side_panel(lateral_sweep_underlay,-1,[],1.1);
        side_panel(lateral_quarter_web,-1,[],0.7);
        side_panel(medial_quarter,1,[medial_window],0.75);
        side_panel(medial_heel_insert,1,[],0.8);
        top_panel(toe_cap_sketch,1.3);
    }
    color(panel_color) {
        side_panel(lateral_sweep,-1,[],1.8);
        side_panel(lateral_lower_frame,-1,[],1.5);
        side_panel(medial_heel_frame,1,[],1.5);
    }
}

module shoe() {
    if(part=="last") inferred_last();
    if(selected("midsole")) color(sole_color) midsole();
    if(selected("outsole")) color(rubber_color) outsole_carrier();
    if(selected("upper")) color(textile_color) upper();
    if(selected("collar")) color(support_color) collar();
    if(selected("tongue")) color(textile_color) tongue();
    if(stage>=2 && selected("panels")) panels();
    if(show_reference_last) %inferred_last();
}

scale([shoe_length/306,shoe_length/306,shoe_length/306]) shoe();
