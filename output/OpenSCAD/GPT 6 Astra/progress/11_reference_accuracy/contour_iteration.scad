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
collar_padding = 3.4;
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
    [-1, 0, 0.7, 52, 1],
    [3, 0, 17, 52, 29],
    [12, 0, 30, 51, 57],
    [24, 0, 36, 49, 74],
    [42, 0, 38, 46.6, 73.4],
    [65, 1, 35.5, 47.8, 63.2],
    [88, 1, 34, 47.6, 74.4],
    [110, 0, 36, 44.5, 80.5],
    [139, -1, 41, 39, 72],
    [168, -2, 46, 34, 62],
    [201, -2, 48, 33, 47],
    [231, -1, 44, 39, 32],
    [258, 1, 35, 43.5, 23.5],
    [279, 2, 24, 48, 15],
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
sole_flare = [0.985, 1.013, 1.04, 1.013, 0.970, 0.958, 0.997, 0.990, 0.963, 0.947];
sole_flare_table = [for(k=[0:len(sole_levels)-1]) [sole_levels[k],sole_flare[k]]];
sole_profile = [
    [-10,15,53],[0,13,54],[25,10,53],[60,8,51],[100,7,48],
    [140,7,41],[180,8,34],[215,10,37],[246,15,44],
    [270,23,49],[288,33,53],[305,42,58]
];
// Fixed registration of the traced upper to the nominal sole. Editing
// sole_profile moves the upper and its attached features relative to this datum.
upper_join_reference = [
    [-10,53],[0,54],[25,53],[60,51],[100,48],[140,41],
    [180,34],[215,37],[246,44],[270,49],[288,53],[305,58]
];
sole_rail_height = [[-10,12],[60,11],[140,9],[210,9],[270,7.5],[305,6.5]];
collar_sketch = [
    [23,0],[28,-15],[43,-24],[64,-22],[83,-20],[99,-13],
    [103,1],[94,17],[75,22],[51,25],[34,21],[26,13]
];
tongue_sections = [
    [91,14,11],[96,22,14],[102,22,10],[112,17,4],[125,18,4],
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
perimeter_lug_stations = [14,40,67,95,125,155,185,214,240,263,282];
heel_rubber_roof = [
    [-44,12],[-32,17],[-17,23],[-5,18],[0,14],
    [5,18],[17,23],[33,17],[44,12]
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

// Fixed photo-traced sketches, linked to the last by side_panel().
// Coordinates refer to the saved panel crops in progress/11_reference_accuracy.
// The image-to-last placement remains inferred, not a calibrated measurement.
function lateral_trace(points) = [for(p=points)
    [(420+p[0]/1.408-357)*306/1310,(850-365-p[1]/1.408)*306/1310]];
function medial_trace(points) = [for(p=points)
    [(1400-770-p[0]/1.408)*306/819,(825-445-p[1]/1.408)*0.335]];
lateral_sweep = lateral_trace([
    [52,64],[353,127],[383,130],[399,125],[556,56],[587,39],
    [592,23],[609,14],[639,25],[658,44],[576,80],[492,128],
    [476,140],[488,149],[705,176],[822,219],[908,277],[988,361],
    [1088,473],[1043,471],[972,365],[890,285],[813,239],
    [697,201],[541,178],[354,149],[75,119]
]);
lateral_sweep_underlay = lateral_trace([
    [105,94],[355,145],[650,193],[792,245],[876,309],[924,373],
    [945,405],[929,405],[901,361],[862,314],[781,256],
    [649,207],[350,160],[115,122]
]);
lateral_lower_frame = lateral_trace([
    [85,170],[106,167],[232,198],[265,201],[285,191],[305,181],
    [377,202],[457,230],[549,270],[604,304],[624,336],
    [610,367],[581,406],[548,417],[472,394],[407,367],
    [340,320],[281,271],[237,235],[193,211],[112,186],
    [137,220],[172,269],[183,290],[181,306],[165,320],
    [106,352],[70,374],[45,366],[66,346],[137,308],[157,292],
    [149,277],[112,226],[87,187]
]);
lateral_heel_foundation = lateral_trace([
    [64,124],[346,147],[544,184],[747,235],[833,286],[891,339],
    [939,406],[988,482],[598,480],[172,402],[34,377],
    [96,345],[155,314],[167,292],[153,272],[84,178]
]);
lateral_mesh_window = lateral_trace([
    [363,228],[388,226],[439,238],[493,260],[540,284],[568,304],
    [573,325],[561,348],[530,375],[500,368],[456,341],
    [404,310],[356,277],[343,257],[350,238]
]);
lateral_lattice_windows = [
    lateral_mesh_window,
    lateral_trace([[536,204],[624,232],[694,267],[745,312],
        [775,348],[790,379],[783,391],[637,366],[640,325],
        [624,290],[590,257]]),
    lateral_trace([[760,265],[821,282],[894,343],[960,429],
        [982,470],[863,461],[834,410],[798,353],[767,310]])
];
lateral_quarter_webs = [lateral_trace([
    [372,134],[556,57],[593,30],[609,15],[651,18],[691,37],
    [765,41],[785,13],[820,14],[824,70],[875,112],[919,137],
    [949,92],[982,111],[983,149],[1030,175],[1100,181],
    [1127,193],[1127,237],[1088,228],[995,255],[932,284],
    [843,241],[743,207],[612,180],[483,161]
])];
lateral_quarter_windows = [
    lateral_trace([[488,141],[502,125],[602,82],[704,58],
        [739,57],[754,65],[753,83],[735,104],[659,141],
        [617,166],[565,161]]),
    lateral_trace([[671,175],[706,149],[810,120],[861,118],
        [884,131],[917,148],[973,161],[996,169],[1008,180],
        [1001,193],[974,213],[923,244],[896,263],[837,236],[767,205]])
];
medial_quarter = medial_trace([
    [398,89],[417,87],[480,115],[550,150],[600,172],[633,177],
    [688,159],[798,116],[815,117],[809,153],[778,208],
    [733,251],[728,266],[750,286],[810,312],[767,316],[742,312],
    [701,307],[640,313],[554,327],[475,345],[404,369],[314,388],
    [260,393],[312,349],[351,303],[389,255],[435,210],
    [422,193],[376,171],[337,149],[322,130],[326,111],
    [347,100],[372,102],[394,106]
]);
medial_window = medial_trace([
    [339,116],[352,115],[408,139],[474,174],[548,209],[567,224],
    [564,240],[535,262],[471,301],[415,332],[348,365],
    [329,368],[355,321],[386,284],[418,247],[443,212],
    [430,199],[385,174],[345,151],[332,132]
]);
medial_quarter_webs = [
    medial_trace([[76,192],[106,191],[155,211],[194,235],[241,268],
        [244,280],[222,306],[190,348],[168,384],[144,391],
        [162,354],[184,315],[204,283],[211,274],[182,253],
        [139,226],[98,207]]),
    medial_trace([[155,165],[172,151],[193,145],[231,154],
        [329,190],[410,232],[407,252],[369,292],[325,341],
        [312,368],[287,381],[255,387],[280,346],[311,299],
        [343,259],[355,232],[327,218],[268,190],[208,173],[178,176]])
];
medial_heel_frame = medial_trace([
    [490,329],[538,301],[614,252],[687,210],[762,184],[784,184],
    [782,195],[757,224],[727,253],[724,263],[730,272],
    [758,289],[808,310],[795,315],[772,307],[730,287],
    [710,275],[705,264],[712,248],[731,225],[755,202],
    [720,212],[667,239],[610,274],[553,309],[515,330]
]);
medial_heel_insert = medial_trace([
    [500,329],[539,309],[614,263],[695,218],[774,192],
    [746,224],[716,254],[716,269],[738,289],[789,315],
    [646,318],[551,327]
]);
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
// Bounded tangents preserve closely spaced corners without spline loops.
function panel_point(a,b,c,d,t) =
    let(length=norm(c-b),
        m0=(c-a)*min(0.5,length/max(0.001,norm(c-a))),
        m1=(d-b)*min(0.5,length/max(0.001,norm(d-b))))
    (2*t*t*t-3*t*t+1)*b+(t*t*t-2*t*t+t)*m0+
    (-2*t*t*t+3*t*t)*c+(t*t*t-t*t)*m1;
function panel_curve(points,n=curve_steps) = [
    for(i=[0:len(points)-1],j=[0:n-1])
        panel_point(points[(i+len(points)-1)%len(points)],points[i],
            points[(i+1)%len(points)],points[(i+2)%len(points)],j/n)
];
function sole_bottom(x) = field(sole_profile,x,1);
function sole_top(x) = sole_bottom(x)+(field(sole_profile,x,2)-sole_bottom(x))*sole_height_scale;
function join_z(x) = field(last_sections,x,3)+sole_top(x)-field(upper_join_reference,x,1);
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
    let(height=sole_top(p[0])-sole_bottom(p[0]),
        channel=1-field(sole_rail_height,p[0],1)/height,
        wave=height*(channel-0.61)*pow(sin(t*180)/sin(0.61*180),2),
        heel_cup=9*exp(-pow(p[1]/26,2))*clamp(1-(p[0]+6)/45,0,1)*t)
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
            let(x=mix(tongue_sections[0][0],tongue_sections[len(tongue_sections)-1][0],i/60),
                w=field(tongue_sections,x,1)*width_scale)
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
        polygon([for(p=panel_curve(outline)) linked_side_point(p)]);
        for(hole=holes)
            polygon([for(p=panel_curve(hole)) linked_side_point(p)]);
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
                polygon([for(p=panel_curve(outline)) [p[0],p[1]*width_scale]]);
    }
}

module panels() {
    if(part=="all" || part=="panels" || part=="support_panels") color(support_color) {
        side_panel(lateral_heel_foundation,-1,lateral_lattice_windows,0.6);
        side_panel(lateral_sweep_underlay,-1,[],1.1);
        for(web=lateral_quarter_webs) side_panel(web,-1,lateral_quarter_windows,0.7);
        side_panel(medial_quarter,1,[medial_window],0.75);
        for(web=medial_quarter_webs) side_panel(web,1,[],0.75);
        side_panel(medial_heel_insert,1,[],0.8);
        rear_panel([[-29,47],[-25,76],[-15,94],[0,100],[15,94],[25,76],[29,47]],0.8);
    }
    if(part=="all" || part=="panels" || part=="toe_guard")
        color(support_color) top_panel(toe_cap_sketch,1.3);
    if(part=="all" || part=="panels" || part=="overlay_panels") color(panel_color) {
        side_panel(lateral_sweep,-1,[],1.8);
        side_panel(lateral_lower_frame,-1,[lateral_mesh_window],1.5);
        side_panel(medial_heel_frame,1,[],1.5);
    }
}

module rear_panel(outline,depth) {
    intersection() {
        last_skin(depth);
        translate([-10,0,0]) rotate([90,0,90])
            linear_extrude(height=37)
                polygon([for(p=closed_curve(outline)) [p[0]*width_scale,
                    47+(p[1]-47)*upper_height_scale+sole_top(0)-field(upper_join_reference,0,1)]]);
    }
}

function eyelet_pad(i,side) =
    i==0 ? [for(p=[
        [86,22],[90,18],[100,15],[112,16],[120,20],[137,22],
        [141,26],[139,31],[129,32],[117,28],[107,28],[96,30],[87,28]
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
                for(i=[0:len(eyelet_x)-1])
                    if(i!=1) top_panel(eyelet_pad(i,side),1.8);
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
    rear_panel([[-15,110],[-15,117],[0,123],[15,117],
                [15,110],[8,108],[-8,108]],2.4);
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
    for(x=perimeter_lug_stations,side=[-1,1])
        lug(x,side*field(outsole_widths,x,1)*width_scale*0.79,side*12);
    for(x=[30,63,99,136,173,209,241,267])
        lug(x,0,x<135 ? 180 : 0,true);
}

function linear_profile(rows,x) =
    let(i=interval(rows,x),t=clamp((x-rows[i][0])/(rows[i+1][0]-rows[i][0]),0,1))
    mix(rows[i][1],rows[i+1][1],t);
function side_wrap_roof(x,station) =
    let(d=x-station)
    d < -9 || d > 10 ? 0.65 :
    linear_profile([[-9,3],[-3,8],[5,7],[9,3],[10,0.65]],d);
function rubber_roof(p) =
    let(base=sole_bottom(p[0]),
        side=base+max([for(x=perimeter_lug_stations) side_wrap_roof(p[0],x)]),
        rear=linear_profile(heel_rubber_roof,sole_point(p,0)[1]/width_scale),
        blend=clamp((20-p[0])/6,0,1))
    min(sole_top(p[0])-0.5,max(side,mix(base+0.65,rear,blend)));
function sole_level_for_z(p,z,lo=0,hi=1,steps=14) =
    let(mid=(lo+hi)/2)
    steps==0 ? mid :
    sole_point(p,mid)[2] < z
        ? sole_level_for_z(p,z,mid,hi,steps-1)
        : sole_level_for_z(p,z,lo,mid,steps-1);
function sole_skin_point(outline,i,t,offset) =
    let(p=sole_point(outline[i],t),
        before=sole_point(outline[(i+len(outline)-1)%len(outline)],t),
        after=sole_point(outline[(i+1)%len(outline)],t),
        tangent=after-before,normal=[tangent[1],-tangent[0],0])
    p+offset*normal/norm(normal);

module wrapped_outsole() {
    // One continuous sheet: underside, outer wrap, cut edge, inner return,
    // then the carrier's top surface. No coincident bonded-shell Booleans.
    outline=closed_curve(sole_outline,curve_steps*2);
    tops=[for(p=outline) sole_level_for_z(p,rubber_roof(p))];
    bases=[for(p=outline) sole_level_for_z(p,sole_bottom(p[0])+0.35)];
    section_loft(concat(
        [for(k=[0:1]) [for(p=outline)
            [150+(p[0]-150)*(k==0 ? 0.993 : 1),
             p[1]*width_scale*(k==0 ? 0.971 : 0.985)*
                (1+0.09*(1-clamp((p[0]-35)/80,0,1))),
             sole_bottom(p[0])+(k==0 ? -2.6 : -1.8)]]],
        [for(k=[0:12]) [for(i=[0:len(outline)-1])
            sole_skin_point(outline,i,tops[i]*k/12,0.75)]],
        [for(k=[0:12]) [for(i=[0:len(outline)-1])
            sole_skin_point(outline,i,mix(tops[i],bases[i],k/12),-0.5)]]
    ),reverse=true,strip_caps=true);
}

module shoe() {
    if(part=="last") inferred_last();
    if(selected("midsole")) color(sole_color) midsole();
    if(selected("outsole")) color(rubber_color) {
        if(stage>=3) {
            wrapped_outsole();
            traction();
        } else outsole_carrier();
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
