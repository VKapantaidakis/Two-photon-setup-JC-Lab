// =====================================================
// ONE SIDE ONLY
// - bottom ring = 135°
// - flipped top ring = 135°
// - groove unchanged
// - male plug on SIDE FACE at 135° of bottom ring
// - female slot on SIDE FACE at 135° of top ring
// =====================================================

phi_deg = 56.3;
ring_thickness = 10;
radial_wall    = 20;
groove_depth   = 4;
groove_width   = 2;

top_inner_d    = 200;
bottom_inner_d = 20;

ring_angle     = 270;
ring_gap       = 60;

$fn = 220;

// =====================================================
// plug / slot sizes
// =====================================================
plug_out       = 4;     // how far it sticks out of the side face
plug_wide      = 6;     // width across the ring thickness direction
plug_tall      = 4;     // height in z

fit_clearance  = 0.3;   // female slot extra size

// choose which flat side face gets the connector
side_angle = ring_angle;   // 135° side face

// =====================================================
// Derived values
// =====================================================
delta_r = groove_depth * tan(phi_deg);

top_clear_r    = top_inner_d / 2;
top_outer_r    = top_clear_r + radial_wall;

bottom_clear_r = bottom_inner_d / 2;
bottom_outer_r = bottom_clear_r + radial_wall;

top_groove_center_r    = (top_clear_r + top_outer_r) / 2;
bottom_groove_center_r = (bottom_clear_r + bottom_outer_r) / 2;

// middle radius of each ring wall
bottom_mid_r = (bottom_clear_r + bottom_outer_r) / 2;
top_mid_r    = (top_clear_r + top_outer_r) / 2;

// radial thickness of each ring wall
wall_mid_span = radial_wall / 2;

// bottom ring: z = 0 .. ring_thickness
// top ring flipped: bottom face sits above by ring_gap
top_translate_z = 2 * ring_thickness + ring_gap;



// =====================================================
// Bottom ring
// groove in TOP face, leaning inward
// male plug added on 135° side face
// =====================================================
module bottom_ring_part()
{
    union()
    {
        difference()
        {
            rotate_extrude(angle = ring_angle)
                polygon([
                    [bottom_clear_r, 0],
                    [bottom_outer_r, 0],
                    [bottom_outer_r, ring_thickness],
                    [bottom_clear_r, ring_thickness]
                ]);

            translate([0,0,ring_thickness - groove_depth])
                rotate_extrude(angle = ring_angle)
                    polygon([
                        [bottom_groove_center_r - groove_width/2, groove_depth],
                        [bottom_groove_center_r + groove_width/2, groove_depth],
                        [bottom_groove_center_r + groove_width/2 - delta_r, 0],
                        [bottom_groove_center_r - groove_width/2 - delta_r, 0]
                    ]);
        }

    }
}

// =====================================================
// Top ring (flipped)
// groove faces downward
// =====================================================
module top_ring_part_flipped()
{
    translate([0,0,top_translate_z])
        mirror([0,0,1])
            difference()
            {
                rotate_extrude(angle = ring_angle)
                    polygon([
                        [top_clear_r, 0],
                        [top_outer_r, 0],
                        [top_outer_r, ring_thickness],
                        [top_clear_r, ring_thickness]
                    ]);

                translate([0,0,ring_thickness - groove_depth])
                    rotate_extrude(angle = ring_angle)
                        polygon([
                            [top_groove_center_r - groove_width/2, groove_depth],
                            [top_groove_center_r + groove_width/2, groove_depth],
                            [top_groove_center_r + groove_width/2 + delta_r, 0],
                            [top_groove_center_r - groove_width/2 + delta_r, 0]
                        ]);
            }
}



// =====================================================
// One side assembly
// =====================================================
module one_side()
{
    union()
    {
        bottom_ring_part();
        top_ring_part_flipped();
        
    }
}

one_side();

// =====================================================
// Bar
// =====================================================
module Bar()

{
    difference()
    {
        union()
        {
            // ---------------------------------------------
            // bottom block
            // ---------------------------------------------
            polyhedron(
                points = [
                    [10,0,0],    // 0
                    [30,0,0],    // 1
                    [30,-10,0],  // 2
                    [10,-10,0],  // 3
                    [10,0,10],   // 4
                    [30,0,10],   // 5
                    [30,-10,10], // 6
                    [10,-10,10]  // 7
                ],
                faces = [
                    [0,2,1], [0,3,2],   // bottom
                    [4,5,6], [4,6,7],   // top
                    [0,1,5], [0,5,4],   // front
                    [1,2,6], [1,6,5],   // right
                    [2,3,7], [2,7,6],   // back
                    [3,0,4], [3,4,7]    // left
                ],
                convexity = 10
            );

            // ---------------------------------------------
            // top block
            // ---------------------------------------------
            polyhedron(
                points = [
                    [100,0,70],    // 0
                    [120,0,70],    // 1
                    [120,-10,70],  // 2
                    [100,-10,70],  // 3
                    [100,0,80],    // 4
                    [120,0,80],    // 5
                    [120,-10,80],  // 6
                    [100,-10,80]   // 7
                ],
                faces = [
                    [0,2,1], [0,3,2],   // bottom
                    [4,5,6], [4,6,7],   // top
                    [0,1,5], [0,5,4],   // front
                    [1,2,6], [1,6,5],   // right
                    [2,3,7], [2,7,6],   // back
                    [3,0,4], [3,4,7]    // left
                ],
                convexity = 10
            );

            // ---------------------------------------------
            // middle connector
            // ---------------------------------------------
            polyhedron(
                points = [
                    [10,0,10],     // 0
                    [30,0,10],     // 1
                    [30,-10,10],   // 2
                    [10,-10,10],   // 3
                    [100,0,70],    // 4
                    [120,0,70],    // 5
                    [120,-10,70],  // 6
                    [100,-10,70]   // 7
                ],
                faces = [
                    [0,2,1], [0,3,2],   // lower end
                    [4,5,6], [4,6,7],   // upper end
                    [0,1,5], [0,5,4],   // front side
                    [1,2,6], [1,6,5],   // right side
                    [2,3,7], [2,7,6],   // back side
                    [3,0,4], [3,4,7]    // left side
                ],
                convexity = 10
            );
        }

        // ---------------------------------------------
        // groove cutter
        // made slightly bigger in y so it fully passes through
        // ---------------------------------------------
        polyhedron(
            points = [
                [15.4023,  1,  6],   // 0
                [13.4023,  1,  6],   // 1
                [117.3977, 1, 74],   // 2
                [115.3977, 1, 74],   // 3
                [15.4023,-11, 6],    // 4
                [13.4023,-11, 6],    // 5
                [117.3977,-11,74],   // 6
                [115.3977,-11,74]    // 7
            ],
            faces = [
                [0,1,3], [0,3,2],    // front end
                [4,6,7], [4,7,5],    // back end
                [0,4,5], [0,5,1],    // lower side
                [1,5,7], [1,7,3],    // left side
                [3,7,6], [3,6,2],    // upper side
                [2,6,4], [2,4,0]     // right side
            ],
            convexity = 10
        );
    }
}

Bar();

// =====================================================
// Bar
// =====================================================
module Bartwo()
{

rotate([0,0,270])

    difference()
    {
        union()
        {
            // ---------------------------------------------
            // bottom block
            // ---------------------------------------------
            polyhedron(
                points = [
                    [10,10,0],    // 0
                    [30,10,0],    // 1
                    [30,0,0],  // 2
                    [10,0,0],  // 3
                    [10,10,10],   // 4
                    [30,10,10],   // 5
                    [30,0,10], // 6
                    [10,0,10]  // 7
                ],
                faces = [
                    [0,2,1], [0,3,2],   // bottom
                    [4,5,6], [4,6,7],   // top
                    [0,1,5], [0,5,4],   // front
                    [1,2,6], [1,6,5],   // right
                    [2,3,7], [2,7,6],   // back
                    [3,0,4], [3,4,7]    // left
                ],
                convexity = 10
            );

            // ---------------------------------------------
            // top block
            // ---------------------------------------------
            polyhedron(
                points = [
                    [100,10,70],    // 0
                    [120,10,70],    // 1
                    [120,0,70],  // 2
                    [100,0,70],  // 3
                    [100,10,80],    // 4
                    [120,10,80],    // 5
                    [120,0,80],  // 6
                    [100,0,80]   // 7
                ],
                faces = [
                    [0,2,1], [0,3,2],   // bottom
                    [4,5,6], [4,6,7],   // top
                    [0,1,5], [0,5,4],   // front
                    [1,2,6], [1,6,5],   // right
                    [2,3,7], [2,7,6],   // back
                    [3,0,4], [3,4,7]    // left
                ],
                convexity = 10
            );

            // ---------------------------------------------
            // middle connector
            // ---------------------------------------------
            polyhedron(
                points = [
                    [10,10,10],     // 0
                    [30,10,10],     // 1
                    [30,0,10],   // 2
                    [10,0,10],   // 3
                    [100,10,70],    // 4
                    [120,10,70],    // 5
                    [120,0,70],  // 6
                    [100,0,70]   // 7
                ],
                faces = [
                    [0,2,1], [0,3,2],   // lower end
                    [4,5,6], [4,6,7],   // upper end
                    [0,1,5], [0,5,4],   // front side
                    [1,2,6], [1,6,5],   // right side
                    [2,3,7], [2,7,6],   // back side
                    [3,0,4], [3,4,7]    // left side
                ],
                convexity = 10
            );
        }

        // ---------------------------------------------
        // groove cutter
        // made slightly bigger in y so it fully passes through
        // ---------------------------------------------
        polyhedron(
            points = [
                [15.4023,  11,  6],   // 0
                [13.4023,  11,  6],   // 1
                [117.3977, 11, 74],   // 2
                [115.3977, 11, 74],   // 3
                [15.4023,-1, 6],    // 4
                [13.4023,-1, 6],    // 5
                [117.3977,-1,74],   // 6
                [115.3977,-1,74]    // 7
            ],
            faces = [
                [0,1,3], [0,3,2],    // front end
                [4,6,7], [4,7,5],    // back end
                [0,4,5], [0,5,1],    // lower side
                [1,5,7], [1,7,3],    // left side
                [3,7,6], [3,6,2],    // upper side
                [2,6,4], [2,4,0]     // right side
            ],
            convexity = 10
        );
    }
}

Bartwo();