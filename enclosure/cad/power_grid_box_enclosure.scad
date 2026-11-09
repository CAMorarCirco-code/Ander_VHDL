// Power Grid Box - 3D printed enclosure (PGB-ENC-001 rev A, PRELIMINARY)
// Parametric model matching drawing set drawings/PGB-ENC-001_*.
// Origin: external front-left-bottom corner. X = left->right, Y = front->back, Z = up.
// Values marked * are nominal/assumed (spec lists them TBC) - measure and update.
//
// Render:  part = "base" | "lid" | "assembly"
//   openscad -D 'part="base"' -o base.stl power_grid_box_enclosure.scad
//   openscad -D 'part="lid"'  -o lid.stl  power_grid_box_enclosure.scad

part = "assembly";
$fn = 64;

// ---------------- shell
t_wall  = 2.5;
t_floor = 2.5;
t_lid   = 3.0;
clear_e = 6.0;          // clearance around protoboard (>= 5 per spec, 6 for corner bosses)
hole_tol = 0.2;         // added to every printed hole

// ---------------- components (measure these!)
holder   = [31, 55, 21];          // * 9 V holder X x Y x Z
bay_b    = [41, 65];              // * battery bay planning reserve
pb_span  = [29 * 2.54, 32 * 2.54];// 73.66 x 81.28 hole-centre span (spec)
pb_edge  = 2.54;                  // * board edge margin
pb_t     = 1.6;
pb_comp  = 12;                    // * tallest part on protoboard
uno      = [68.58, 53.34];        // Uno R3 outline
uno_t    = 1.6;
uno_comp = 10.9;                  // USB-B / DC jack height
uno_ref_holes = [[13.97, 2.54], [15.24, 50.80], [66.04, 7.62], [66.04, 35.56]];

btn_cut  = 16;   btn_depth = 30;  // * Adafruit 1439
sel_cut  = 6;    sel_depth = 22;  // * Miyama MS-500E (M6x0.75 bushing)
led_cut  = 8;    led_depth = 12;  // * LED in 8 mm holder
min_gap  = 5;

// ---------------- derived layout
rib_w  = 2.0;   rib_h = 15;   notch = 8;
chan_w = 12.0;
pb     = [pb_span[0] + 2 * pb_edge, pb_span[1] + 2 * pb_edge];
ebay_w = pb[0] + 2 * clear_e;
in_w   = bay_b[0] + rib_w + chan_w + ebay_w;
in_d   = max(pb[1] + 2 * clear_e, bay_b[1]);
W = ceil(in_w + 2 * t_wall);                 // 151
D = ceil(in_d + 2 * t_wall);                 // 104
uno_z  = t_floor + 6;                        // Uno underside (6 mm standoffs)
pb_z   = uno_z + uno_t + uno_comp + 3;       // protoboard underside (24.0)
base_h = ceil(max(t_floor + holder[2] + min_gap + btn_depth,
             pb_z + pb_t + pb_comp + min_gap + led_depth));   // 59 (rounded up)
H = base_h + t_lid;                          // 62
cy = D / 2;

ix0 = t_wall; ix1 = W - t_wall; iy0 = t_wall; iy1 = D - t_wall;
bay_x1  = ix0 + bay_b[0];
chan_x0 = bay_x1 + rib_w;  chan_x1 = chan_x0 + chan_w;
pb_cx   = (chan_x1 + ix1) / 2;
pb_x0   = pb_cx - pb[0] / 2;  pb_y0 = cy - pb[1] / 2;
uno_x0  = 70.0;  uno_y0 = cy - uno[1] / 2;
uno_holes = [for (h = uno_ref_holes) [uno_x0 + uno[0] - h[0], uno_y0 + uno[1] - h[1]]];
pb_pillars = [for (x = [pb_x0 + 2.54, pb_x0 + pb[0] - 2.54]) for (y = [pb_y0 + 2.54, pb_y0 + pb[1] - 2.54]) [x, y]];
bosses = [for (x = [ix0 + 3, ix1 - 3]) for (y = [iy0 + 3, iy1 - 3]) [x, y]];
feet   = [for (x = [12, W - 12]) for (y = [12, D - 12]) [x, y]];

btn_x = ix0 + bay_b[0] / 2 - 0.0;   // 23
sel_x = (chan_x0 + chan_x1) / 2;    // 51.5
led_x = W - btn_x;                  // 128 (mirrors button column)
rows  = [cy - 25, cy, cy + 25];
lip_w = 1.5; lip_h = 3; lip_gap = 0.3;

echo(str("Envelope W x D x H = ", W, " x ", D, " x ", H, " mm"));
echo(str("PB z=", pb_z, "  base_h=", base_h, "  btn->holder gap=", base_h - btn_depth - t_floor - holder[2]));

// ---------------- parts
module base() {
    difference() {
        cube([W, D, base_h]);
        translate([ix0, iy0, t_floor]) cube([in_w, in_d, base_h]);
        for (f = feet) translate([f[0], f[1], -0.01]) cylinder(d = 10, h = 1.0);
    }
    // corner bosses with M3 heat-set insert bore
    for (b = bosses) translate([b[0], b[1], 0]) difference() {
        cylinder(d = 7, h = base_h);
        translate([0, 0, base_h - 6]) cylinder(d = 4.0, h = 7);
    }
    // battery bay rib with wire notch
    translate([bay_x1, iy0, 0]) difference() {
        cube([rib_w, in_d, t_floor + rib_h]);
        translate([-1, cy - iy0 - notch / 2, t_floor + rib_h - notch]) cube([rib_w + 2, notch, notch + 1]);
    }
    // cable-tie anchors in channel
    for (y = [25, 79]) translate([chan_x0 + 2, y - 2, t_floor]) difference() {
        cube([chan_w - 4, 4, 4]);
        translate([-1, 0.75, 1]) cube([chan_w - 2, 2.5, 1.8]);
    }
    // protoboard pillars
    for (p = pb_pillars) translate([p[0], p[1], 0]) difference() {
        cylinder(d = 7, h = pb_z);
        translate([0, 0, t_floor]) cylinder(d = 2.5, h = pb_z);
    }
    // Uno standoffs
    for (h = uno_holes) translate([h[0], h[1], 0]) difference() {
        cylinder(d = 6, h = uno_z);
        translate([0, 0, t_floor]) cylinder(d = 2.5, h = uno_z);
    }
}

module lid() {
    difference() {
        union() {
            translate([0, 0, base_h]) cube([W, D, t_lid]);
            // locating lip, notched around bosses
            difference() {
                translate([ix0 + lip_gap, iy0 + lip_gap, base_h - lip_h])
                    cube([in_w - 2 * lip_gap, in_d - 2 * lip_gap, lip_h]);
                translate([ix0 + lip_gap + lip_w, iy0 + lip_gap + lip_w, base_h - lip_h - 1])
                    cube([in_w - 2 * (lip_gap + lip_w), in_d - 2 * (lip_gap + lip_w), lip_h + 2]);
                for (b = bosses) translate([b[0] - 4, b[1] - 4, base_h - lip_h - 1]) cube([8, 8, lip_h + 1]);
            }
        }
        for (y = rows) {
            translate([btn_x, y, base_h - 1]) cylinder(d = btn_cut + hole_tol, h = t_lid + 2);
            translate([led_x, y, base_h - 1]) cylinder(d = led_cut + hole_tol, h = t_lid + 2);
        }
        translate([sel_x, cy, base_h - 1]) cylinder(d = sel_cut + hole_tol, h = t_lid + 2);
        for (b = bosses) {
            translate([b[0], b[1], base_h - 1]) cylinder(d = 3.4, h = t_lid + 2);
            translate([b[0], b[1], H - 1.6]) cylinder(d1 = 3.4, d2 = 6.6, h = 1.61);   // 90 deg CSK
        }
    }
}

// ---------------- reference components (assembly view only)
module components() {
    color("dimgray") translate([ix0 + (bay_b[0] - holder[0]) / 2, cy - holder[1] / 2, t_floor]) cube(holder);
    color("teal")    translate([uno_x0, uno_y0, uno_z]) cube([uno[0], uno[1], uno_t]);
    color("goldenrod", 0.9) translate([pb_x0, pb_y0, pb_z]) cube([pb[0], pb[1], pb_t]);
    for (y = rows) {
        color("red")   translate([btn_x, y, base_h - btn_depth]) cylinder(d = 16, h = btn_depth);
        color("white") translate([led_x, y, base_h - led_depth]) cylinder(d = 8, h = led_depth);
    }
    color("silver") translate([sel_x - 3.9, cy - 6.5, base_h - sel_depth]) cube([7.8, 13, sel_depth]);
}

if (part == "base") base();
else if (part == "lid") translate([0, D, H]) rotate([180, 0, 0]) lid();   // print face-down
else { color("lightsteelblue") base(); color("whitesmoke", 0.6) lid(); components(); }
