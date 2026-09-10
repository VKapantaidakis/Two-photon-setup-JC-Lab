// OpenSCAD editing scaffold for:
// Ball_Treadmill_with_Nozzle_alligned.stl
//
// - Bounding box from the STL:
//   X: 99.356 mm, Y: 63.467 mm, Z: 39.863 mm

$fa = 6;
$fs = 0.8;

// ---------- USER CONTROLS ----------
show_original = true;
center_model  = false;

pos   = [0, 0, 0];
rot   = [0, 0, 0];
scale_xyz = [1, 1, 1];

// Easy edit toggles
make_left_right_copy = false;
copy_spacing = 120;

cut_bottom_flat = false;
cut_bottom_z = 0;

add_mount_plate = false;
plate_size = [110, 75, 4];
plate_pos  = [60, 70, -4];

add_holes = false;
hole_d = 4;
hole_spacing = [80, 45];
hole_center = [60, 70, 0];

// ---------- SOURCE STL ----------
module source_mesh() {
    import("Ball_Treadmill_with_Nozzle_alligned.stl", convexity=20);
}

module model_raw() {
    translate(pos)
    rotate(rot)
    scale(scale_xyz)
    if (center_model)
        translate([-60, -69, -20]) // rough visual centering offset for this STL
            source_mesh();
    else
        source_mesh();
}

module editable_model() {
    difference() {
        union() {
            model_raw();

            if (add_mount_plate)
                translate(plate_pos)
                    cube(plate_size);
        }

        if (cut_bottom_flat)
            translate([-200, -200, -200])
                cube([400, 400, 200 + cut_bottom_z]);

        if (add_holes)
            for (sx = [-1, 1], sy = [-1, 1])
                translate([
                    hole_center[0] + sx * hole_spacing[0] / 2,
                    hole_center[1] + sy * hole_spacing[1] / 2,
                    -20
                ])
                    cylinder(d=hole_d, h=100, $fn=48);
    }
}

module final_model() {
    if (make_left_right_copy) {
        translate([-copy_spacing/2, 0, 0]) editable_model();
        translate([ copy_spacing/2, 0, 0]) mirror([1,0,0]) editable_model();
    } else {
        editable_model();
    }
}

// ---------- HELPERS ----------
// Example add-on geometry block. Duplicate/edit as needed.
module add_block(block_pos=[0,0,0], block_size=[10,10,10]) {
    translate(block_pos) cube(block_size);
}

module add_cylinder(cyl_pos=[0,0,0], d=10, h=10, axis="z") {
    translate(cyl_pos)
    if (axis == "x") rotate([0,90,0]) cylinder(d=d, h=h, $fn=64);
    else if (axis == "y") rotate([-90,0,0]) cylinder(d=d, h=h, $fn=64);
    else cylinder(d=d, h=h, $fn=64);
}

// ---------- OUTPUT ----------
if (show_original)
    final_model();
