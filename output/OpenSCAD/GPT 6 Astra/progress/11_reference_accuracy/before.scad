/*
Reference-based trail shoe. Native, linked OpenSCAD construction; units: mm.
Edit dimensions, station tables and 2D panel sketches, not generated vertices.
Photos have no scale: dimensions, last, wall thickness and underside are inferred.
See MODEL_GUIDE.txt. No scanned/anatomically validated last is supplied.
*/

/* [Driving dimensions] */
shoe_length = 300;
width_scale = 1.08;
upper_height_scale = 1;
sole_height_scale = 1;
upper_wall = 2.4;
panel_thickness = 0.9;
collar_padding = 2.7;
lace_width = 4.8;
lace_thickness = 1.25;
cougar_line_width = 1.3;
cougar_film = 0.14;
cougar_offset = [5,-7];
lug_depth = 4.5;

/* [Presentation] */
// 1: silhouette; 2: panels; 3: hardware and traction
stage = 3;
// all, or a named construction/rendering group listed in MODEL_GUIDE.txt
part = "all";
quality = 1;
show_reference_last = false;
// Derived cache for scripted viewing only; normal editing always uses false.
use_exported_meshes = false;

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
graphic_color = [0.83, 0.85, 0.83];

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
// A broad instep crown seats the tongue/laces; toe and heel stay rounder.
cross_section_powers = [
    [-1,0.8],[65,0.8],[84,0.45],[100,0.34],[155,0.38],
    [190,0.48],[212,0.7],[240,0.8],[298,0.8]
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
sole_flare_table = [for(k=[0:len(sole_levels)-1]) [sole_levels[k],sole_flare[k]]];
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
    [79,14,13],[84,22,15],[94,22,10],[105,17,4],[125,18,4],
    [145,18,3],[165,17,2],[185,14,1.5],[198,9,1],[202,0.8,0.8]
];
eyelet_x = [105,132,155,177,196];
eyelet_y = [21,23,24,23,20];
bumper_sections = [
    [28,23,292],[34,22,300],[41,17,303],
    [50,13,302],[58,9,298],[63,6,287]
];
outsole_widths = [
    [-5,23],[14,38],[40,42],[75,39],[110,38],
    [150,46],[190,52],[220,51],[245,46],[269,36],[286,24],[298,10]
];

// Traced from the supplied lateral photo. Hidden tail continuation sits under
// the support cage; the print is not an embossed structural panel.
cougar_outline = [
    [126.30,48.75],[168.77,68.17],[196.64,75.13],[195.98,77.46],
    [211.91,73.31],[212.73,70.99],[215.06,69.16],[212.07,66.17],
    [209.08,67.34],[206.93,67.00],[205.10,65.84],[203.61,64.18],
    [202.95,63.19],[208.59,62.52],[206.60,59.37],[197.80,59.21],
    [192.83,62.19],[185.03,52.07]
];
cougar_inner_lines = [
    [[194.65,66.51],[197.80,59.21]],
    [[208.09,71.98],[212.73,70.99]]
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
lateral_quarter_webs = [
    [[63,83],[82,93],[99,109],[107,110],[111,108],
     [103,98],[84,87],[103,85],[96,80],[78,80]],
    [[98,78],[113,89],[131,102],[139,103],[144,99],
     [132,91],[116,82],[135,79],[141,74],[126,72]],
    [[131,64],[146,77],[159,91],[167,92],[173,87],[160,80],
     [149,70],[171,71],[180,75],[190,79],[198,73],[181,65],
     [159,52],[149,48],[151,60]]
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
function cross_power(x) = field(cross_section_powers,x,1);
function upper_z(x,y) = join_z(x)+last_height(x)*
    pow(max(0,1-pow((y-centre_y(x))/last_width(x),2)),cross_power(x)/2);
function side_y(x,z,side=-1,offset=0) =
    centre_y(x)+side*(last_width(x)*
        sqrt(max(0,1-pow(clamp((z-join_z(x))/last_height(x),0,1),2/cross_power(x))))+offset);
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

module inferred_last(width_offset=0, height_offset=0, inset=0, bottom_offset=0) {
    section_loft([
        for(i=[0:long_steps])
            let(x=mix(-1+inset,298-inset,i/long_steps),
                w=max(0.25,last_width(x)+width_offset),
                h=max(0.3,last_height(x)+height_offset))
            [for(j=[0:ring_steps-1])
                let(a=360*j/ring_steps)
                [x,centre_y(x)+w*cos(a),
                 join_z(x)+(sin(a)>=0 ? h*pow(sin(a),cross_power(x)) : (2+bottom_offset)*sin(a))]
            ]
    ],reverse=true);
}

module midsole() {
    outline=closed_curve(sole_outline);
    section_loft([
        for(k=[0:36])
            let(t=k/36)
            [for(p=outline) sole_point(p,t)]
    ],reverse=true,strip_caps=true);
}

function sole_point(p,t) =
    let(wave=-4*sin(clamp((p[0]-30)/245,0,1)*180)*pow(sin(t*180),2),
        heel_cup=8*pow(clamp(1-(p[0]+6)/46,0,1),2)*pow(t,4))
    [150+(p[0]-150)*mix(1,0.981,t),
     p[1]*width_scale*field(sole_flare_table,t,1)*
        (1+0.09*(1-t)*(1-clamp((p[0]-35)/80,0,1))),
     mix(sole_bottom(p[0]),sole_top(p[0]),t)+wave+heel_cup];

module outsole_carrier() {
    outline=closed_curve(sole_outline);
    section_loft([
        for(k=[0:2])
            [for(p=outline)
                [150+(p[0]-150)*(k==0 ? 0.993 : 1),
                 p[1]*width_scale*(k==0 ? 0.971 : 0.985)*
                    (1+0.09*(1-clamp((p[0]-35)/80,0,1))),
                 sole_bottom(p[0])+(k==0 ? -2.6 : k==1 ? -1.8 : 0.35)]]
    ],reverse=true,strip_caps=true);
}

module upper() {
    difference() {
        inferred_last();
        translate([0,0,upper_wall])
            inferred_last(-upper_wall,-2*upper_wall,upper_wall);
        collar_opening();
        if(stage>=3) eyelet_bores();
    }
}

module collar_opening() {
    translate([0,0,78])
        linear_extrude(height=150)
            polygon([for(p=closed_curve(collar_sketch)) [p[0],p[1]*width_scale]]);
}

module sweep_round(path,r,closed=false) {
    n=len(path); m=quality==0 ? 12 : 20;
    rings=[
        for(i=[0:n-1])
            let(tangent=closed ? path[(i+1)%n]-path[(i+n-1)%n] :
                                path[min(i+1,n-1)]-path[max(i-1,0)],
                t=tangent/norm(tangent),
                horizontal=[-t[1],t[0],0],
                a=horizontal/norm(horizontal),b=cross(t,a))
            [for(j=[0:m-1]) path[i]+r*(a*cos(360*j/m)+b*sin(360*j/m))]
    ];
    if(!closed) section_loft(rings,reverse=true);
    else
        polyhedron(
            points=[for(ring=rings) for(p=ring) p],
            faces=[for(i=[0:n-1],j=[0:m-1]) each [
                [i*m+j,((i+1)%n)*m+(j+1)%m,i*m+(j+1)%m],
                [i*m+j,((i+1)%n)*m+j,((i+1)%n)*m+(j+1)%m]
            ]],convexity=12
        );
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
        for(i=[0:60])
            let(x=mix(79,202,i/60),w=field(tongue_sections,x,1)*width_scale)
            concat(
                [for(j=[0:32]) let(y=mix(-w,w,j/32)) [x,y,tongue_z(x,y)]],
                [for(j=[32:-1:0]) let(y=mix(-w,w,j/32)) [x,y,tongue_z(x,y)-2.3]]
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

module last_skin(depth=0.9) {
    thickness=depth*panel_thickness/0.9;
    difference() {
        inferred_last(thickness,thickness,bottom_offset=thickness);
        inferred_last(-0.18,-0.18,bottom_offset=-0.18);
    }
}

module side_panel(outline,side=-1,holes=[],depth=0.9) {
    intersection() {
        last_skin(depth);
        scale([1,-side,1])
            rotate([90,0,0])
                linear_extrude(height=85*width_scale,convexity=10)
                    side_sketch(outline,holes);
    }
}

module top_panel(outline,depth=0.9) {
    intersection() {
        last_skin(depth);
        translate([0,0,40])
            linear_extrude(height=130)
                polygon([for(p=closed_curve(outline)) [p[0],p[1]*width_scale]]);
    }
}

module panels() {
    if(part=="all" || part=="panels" || part=="support_panels") color(support_color) {
        side_panel(lateral_heel_foundation,-1,[lateral_mesh_window],0.6);
        side_panel(lateral_sweep_underlay,-1,[],1.1);
        for(web=lateral_quarter_webs) side_panel(web,-1,[],0.7);
        side_panel(medial_quarter,1,[medial_window],0.75);
        side_panel(medial_heel_insert,1,[],0.8);
        rear_panel([[-29,47],[-25,76],[-15,94],[0,100],[15,94],[25,76],[29,47]],0.8);
    }
    if(part=="all" || part=="panels" || part=="toe_guard")
        color(support_color) top_panel(toe_cap_sketch,1.3);
    if(part=="all" || part=="panels" || part=="overlay_panels") color(panel_color) {
        side_panel(lateral_sweep,-1,[],1.8);
        side_panel(lateral_lower_frame,-1,[],1.5);
        side_panel(medial_heel_frame,1,[],1.5);
    }
}

module rear_panel(outline,depth) {
    intersection() {
        last_skin(depth);
        translate([-10,0,0]) rotate([90,0,90])
            linear_extrude(height=37)
                polygon([for(p=closed_curve(outline)) [p[0]*width_scale,
                    47+(p[1]-47)*upper_height_scale+sole_top(0)-field(sole_profile,0,2)]]);
    }
}

function eyelet_pad(i,side) =
    i==0 ? [for(p=[
        [90,18],[96,15],[107,15],[114,20],[124,23],
        [125,30],[117,33],[108,29],[97,30],[89,26]
    ]) [p[0],p[1]*side]] :
    let(x=eyelet_x[i],y=eyelet_y[i])
    [for(p=[
        [x-6,y-4],[x+4,y-4],[x+8,y],[x+7,y+8],
        [x-3,y+9],[x-8,y+6]
    ]) [p[0],p[1]*side]];

function upper_normal(x,y) =
    let(v=[-(upper_z(x+0.2,y)-upper_z(x-0.2,y))/0.4,
           -(upper_z(x,y+0.2)-upper_z(x,y-0.2))/0.4,1])
    v/norm(v);
module along_normal(n) {
    rotate(a=acos(n[2]),v=[-n[1],n[0],0]) children();
}
module eyelet_bores() {
    for(side=[-1,1]) {
        for(i=[0:len(eyelet_x)-1])
            let(x=eyelet_x[i],y=side*eyelet_y[i]*width_scale)
            translate([x,y,upper_z(x,y)])
                along_normal(upper_normal(x,y))
                    cylinder(r=2.5,h=14,center=true,$fn=24);
        let(x=95,y=side*27*width_scale)
            translate([x,y,upper_z(x,y)])
                along_normal(upper_normal(x,y))
                    cylinder(r=1.9,h=14,center=true,$fn=24);
    }
}

module eyelets() {
    difference() {
        union() {
            for(side=[-1,1]) {
                for(i=[0:len(eyelet_x)-1]) top_panel(eyelet_pad(i,side),1.8);
                top_panel(concat(
                    [for(i=[1:len(eyelet_x)-1]) [eyelet_x[i],side*(eyelet_y[i]+8)]],
                    [for(i=[len(eyelet_x)-1:-1:1]) [eyelet_x[i],side*(eyelet_y[i]+5)]]
                ),1.3);
            }
        }
        eyelet_bores();
        collar_opening();
    }
}

function smooth_step(t) = let(s=clamp(t,0,1)) s*s*(3-2*s);
function signed_power(v,p) = sign(v)*pow(abs(v),p);
function lace_surface_z(x,y) =
    abs(y)<=field(tongue_sections,x,1)*width_scale
        ? max(upper_z(x,y),tongue_z(x,y)) : upper_z(x,y);
function lace_support_z(x,y) =
    let(w=field(tongue_sections,x,1)*width_scale,
        edge=smooth_step((abs(y)-w+3)/3),
        depth=1.8*panel_thickness/0.9,
        pad=join_z(x)+(last_height(x)+depth)*
            pow(max(0,1-pow((y-centre_y(x))/(last_width(x)+depth),2)),cross_power(x)/2))
    max(lace_surface_z(x,y),mix(upper_z(x,y),pad,edge));
function lace_path(a,b,over=0) = [
    for(j=[0:64])
        let(t=j/64,x=mix(a[0],b[0],t),y=mix(a[1],b[1],t)*width_scale,
            entry=1-smooth_step(t/0.045)*smooth_step((1-t)/0.045),
            crossing=1-smooth_step((abs(t-0.5)-0.045)/0.12),
            z=lace_support_z(x,y)+0.10+over*crossing-1.2*entry)
        [x,y,z]
];

module lace_ribbon(path) {
    n=len(path); m=quality==0 ? 16 : 32;
    section_loft([
        for(i=[0:n-1])
            let(tangent=path[min(i+1,n-1)]-path[max(i-1,0)],
                across=[-tangent[1],tangent[0],0],a=across/norm(across),
                lift=path[i][2]-lace_support_z(path[i][0],path[i][1]),
                // Fabric narrows into the bore but remains broad over the tongue.
                w=lace_width*mix(0.76,1,smooth_step(min(i,n-1-i)/(0.12*(n-1)))))
            [for(j=[0:m-1])
                let(angle=360*j/m,
                    p=path[i]+a*(w/2*signed_power(cos(angle),0.45)))
                [p[0],p[1],lace_support_z(p[0],p[1])+lift+
                    lace_thickness/2*(1+signed_power(sin(angle),0.45))]]
    ],reverse=true);
}

module laces() {
    for(i=[0:len(eyelet_x)-2]) {
        lace_ribbon(lace_path([eyelet_x[i],-eyelet_y[i]],
                              [eyelet_x[i+1],eyelet_y[i+1]]));
        lace_ribbon(lace_path([eyelet_x[i],eyelet_y[i]],
                              [eyelet_x[i+1],-eyelet_y[i+1]],lace_thickness+0.15));
    }
    // Return passes enter behind the crossing passes within the same bores.
    for(i=[0,len(eyelet_x)-1])
        let(x=eyelet_x[i]+(i==0 ? 1 : -1)*lace_thickness*0.35)
        lace_ribbon(lace_path([x,-eyelet_y[i]],[x,eyelet_y[i]]));
}

module cougar_graphic() {
    intersection() {
        difference() {
            inferred_last(cougar_film,cougar_film,bottom_offset=cougar_film);
            inferred_last(-0.05,-0.05,bottom_offset=-0.05);
        }
        rotate([90,0,0]) linear_extrude(height=85*width_scale,convexity=10)
            union() {
                difference() {
                    offset(delta=cougar_line_width/2)
                        polygon([for(p=cougar_outline) linked_side_point(p+cougar_offset)]);
                    offset(delta=-cougar_line_width/2)
                        polygon([for(p=cougar_outline) linked_side_point(p+cougar_offset)]);
                }
                for(line=cougar_inner_lines)
                    hull() for(p=line)
                        translate(linked_side_point(p+cougar_offset))
                            circle(r=cougar_line_width/2,$fn=16);
            }
    }
}

module tongue_keeper() {
    section_loft([
        for(i=[0:12])
            let(x=mix(120,140,i/12),lift=0.7+2.6*sin(i/12*180))
            [
                [x,-3.6,tongue_z(x,-3.6)+lift],
                [x,3.6,tongue_z(x,3.6)+lift],
                [x,3.6,tongue_z(x,3.6)+lift-1.2],
                [x,-3.6,tongue_z(x,-3.6)+lift-1.2]
            ]
    ]);
}

module heel_webbing() {
    rear_panel([[-8,48],[-8,108],[-6,116],[0,119],
                [6,116],[8,108],[8,48]],1.5);
}

module heel_cushion() {
    rear_panel([[-14,110],[-12,119],[0,124],[12,119],
                [14,110],[8,106],[-8,106]],2.4);
}

function bumper_x(z,y) = field(bumper_sections,z,2)-0.025*pow(y/width_scale,2);
module toe_bumper() {
    section_loft([
        for(i=[0:22])
            let(z=mix(28,63,i/22),w=field(bumper_sections,z,1)*width_scale)
            concat(
                [for(j=[0:24]) let(y=mix(-w,w,j/24)) [bumper_x(z,y)+1.4,y,z]],
                [for(j=[24:-1:0]) let(y=mix(-w,w,j/24)) [bumper_x(z,y)-4.2,y,z]]
            )
    ],reverse=true);
    for(z=[38,50],side=[-1,1])
        let(y=side*(z==38 ? 10 : 7)*width_scale)
        translate([bumper_x(z,y)+0.9,y,z])
            rotate([0,90,0])
                linear_extrude(height=2.4,scale=0.75)
                    polygon([[-2.7,-2.5],[1.5,-3.1],[3,0],[1,3],[-2.7,2]]);
}

module lug(x,y,angle=0,central=false) {
    slope=(sole_bottom(x+0.5)-sole_bottom(x-0.5));
    translate([x,y,sole_bottom(x)-1.7])
        rotate([0,-atan(slope),0]) rotate([0,0,angle])
            translate([0,0,-lug_depth])
                linear_extrude(height=lug_depth+0.3,scale=1.12)
                    if(central)
                        polygon([[-6,-16],[4,-16],[10,0],[4,16],[-6,16],[0,0]]);
                    else
                        polygon([[-8,-5],[-4,-7],[7,-6],[9,3],[4,7],[-7,6]]);
}

module traction() {
    // Visible perimeter blocks guide these rows. Hidden centre lugs are inferred.
    for(x=[14,40,67,95,125,155,185,214,240,263,282],side=[-1,1])
        lug(x,side*field(outsole_widths,x,1)*width_scale*0.79,side*12);
    for(x=[30,63,99,136,173,209,241,267])
        lug(x,0,x<135 ? 180 : 0,true);
}

module side_rubber_wraps() {
    intersection() {
        sole_side_skin();
        rotate([90,0,0]) translate([0,0,-85*width_scale])
            linear_extrude(height=170*width_scale)
                for(x=[14,40,67,95,125,155,185,214,240,263,282])
                    let(b=sole_bottom(x))
                    polygon([[x-9,b-1],[x-9,b+3],[x-3,b+8],
                             [x+5,b+7],[x+9,b+3],[x+10,b-1]]);
    }
}

module sole_side_skin() {
    outline=closed_curve(sole_outline);
    rings=[
        for(i=[0:len(outline)-1])
            concat(
                [for(k=[0:36]) sole_skin_point(outline,i,k/36,0.75)],
                [for(k=[36:-1:0]) sole_skin_point(outline,i,k/36,-0.5)]
            )
    ];
    n=len(rings); m=len(rings[0]);
    polyhedron(
        points=[for(r=rings) for(p=r) p],
        faces=[for(i=[0:n-1],j=[0:m-1]) each [
            [i*m+j,i*m+(j+1)%m,((i+1)%n)*m+(j+1)%m],
            [i*m+j,((i+1)%n)*m+(j+1)%m,((i+1)%n)*m+j]
        ]],convexity=12
    );
}

function sole_skin_point(outline,i,t,offset) =
    let(p=sole_point(outline[i],t),
        before=sole_point(outline[(i+len(outline)-1)%len(outline)],t),
        after=sole_point(outline[(i+1)%len(outline)],t),
        tangent=after-before,normal=[tangent[1],-tangent[0],0])
    p+offset*normal/norm(normal);

module shoe() {
    if(part=="last") inferred_last();
    if(selected("midsole")) color(sole_color) midsole();
    if(selected("outsole")) color(rubber_color) {
        outsole_carrier();
        if(stage>=3) {
            traction();
            side_rubber_wraps();
        }
    }
    if(selected("upper")) color(textile_color) upper();
    if(selected("collar")) color(support_color) collar();
    if(selected("tongue")) color(textile_color) {
        tongue();
        if(stage>=3) tongue_keeper();
    }
    if(stage>=2) panels();
    if(stage>=3) {
        if(selected("eyelets")) color(panel_color) eyelets();
        if(selected("laces")) color(lace_color) laces();
        if(selected("heel_webbing")) color(panel_color) heel_webbing();
        if(selected("collar")) color(textile_color) heel_cushion();
        if(selected("toe_bumper")) color(rubber_color) toe_bumper();
        if(selected("cougar_graphic")) color(graphic_color) cougar_graphic();
    }
    if(show_reference_last) %inferred_last();
}

module cached_meshes() {
    // Generated by export_geometry.py; never a replacement for the features above.
    names = [
        ["midsole","01_Continuous_midsole",sole_color],
        ["outsole","02_Rubber_carrier_and_traction",rubber_color],
        ["upper","03_Continuous_textile_upper",textile_color],
        ["tongue","04_Tongue_and_keeper",textile_color],
        ["collar","05_Collar_padding",support_color],
        ["support_panels","06_Asymmetric_support_panels",support_color],
        ["overlay_panels","07_Variable_width_overlay_panels",panel_color],
        ["toe_guard","08_Continuous_toe_reinforcement",support_color],
        ["eyelets","09_Eyestays_with_functional_bores",panel_color],
        ["laces","10_Crossed_lace_sweeps",lace_color],
        ["heel_webbing","11_Heel_webbing",panel_color],
        ["toe_bumper","12_Rubber_toe_wrap",rubber_color],
        ["cougar_graphic","13_Cougar_outline_graphic",graphic_color]
    ];
    for(item=names)
        if(selected(item[0])) color(item[2]) import(str("meshes/",item[1],".stl"),convexity=12);
}

if(use_exported_meshes) cached_meshes();
else scale([shoe_length/306,shoe_length/306,shoe_length/306]) shoe();
