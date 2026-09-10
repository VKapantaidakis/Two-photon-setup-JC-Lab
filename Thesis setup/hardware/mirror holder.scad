



Beam_hight = 134; //hight of beam center
Beam_grain = 25; //align beam with center of M6 grooves
M6_groove = 6.3; //width of M6 grooves (M6 = 6mm)
M6_wall = 8; //wall for the M6 groove
M6_length = 50; //length of the M6 groove
M6_grid = 25; //distance between M6 holes

Holder_thiccness = 5; //thicness of the projector holder plate
Holder_wall = 2; //thicness of projector holder walls
Holder_wedge = 6; //wedges at the corners of the holder
Beam_side_adjust = 13; //ring outer edge to side of projector
Beam_height_adjust = 6; //ring outer edge to bottom of projector

Base_plate_higth = 7; //thicness of baseplate of projector
Support_wall = 4; //thicness of support structure
Support_heigth = 10; //heigth off angled support

Projector_width = 73.2; //long side of projector
Projector_width_thicc = 73.2; //long side at thiccer section
Projector_depth = 73.2; //short side of projector at thin section
Projector_depth_thicc = 75.2; //short side of projector at thicc section

// =====================================================
// Derived values
// =====================================================

Plate_hight = 80; //hight of plate the projecter will be resting on, beam diameter is 21mm, lens edge is at 6mm
M6_offset = 13.4; //M6 alignment distance
Plate_base = Plate_hight - Holder_thiccness;
Projecter_depth_outskirt = Projector_depth_thicc - Projector_depth; //how much the thicc section of the projector extends beyond the short section
M6_diameter = M6_groove/2; //M6 hole diameter
Base_start = M6_wall - M6_offset; // attach baseplate to m6 groove
Base_extend = 82.2; //attach baseplate to m6 groove

Support  = Support_wall / 2; //middle of support wall
Long_support = Projector_depth /2; //middle of thin long pojector side
Thicc_support = Projector_width_thicc /6; //quarter points thicc section
Thicc_support_edge = Long_support-Support+Projecter_depth_outskirt; //extention of the supports at thicc section to the end of the projector
Thin_support = (Projector_width - Projector_width_thicc) /4; //quarter points thin section
Support_angle_base = Plate_base - Support_heigth; //heigth at which angled support start

Wedge_root = sqrt(2* pow(Holder_wedge,2)); //size of cube to cut wedge


// =====================================================
// Projector holder
// =====================================================
module holder ()

{

        {
            // ---------------------------------------------
            // Projector outskirt block
            // ---------------------------------------------
            difference()
            {
            polyhedron(
                points = [
                    [Projector_depth,0,Plate_hight],    // 0
                    [Projector_depth_thicc,0,Plate_hight],    // 1
                    [Projector_depth_thicc,Projector_width_thicc,Plate_hight],  // 2
                    [Projector_depth,Projector_width_thicc,Plate_hight],  // 3
                    [Projector_depth,0,Plate_base],   // 4
                    [Projector_depth_thicc,0,Plate_base],   // 5
                    [Projector_depth_thicc,Projector_width_thicc,Plate_base], // 6
                    [Projector_depth,Projector_width_thicc,Plate_base]  // 7
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
            
            union(){
            translate([62.2,24.1,Plate_hight])
            cylinder(10, 3.15, 3.15, center = true);
            
            translate([62.2,49.1,Plate_hight])
            cylinder(10, 3.15, 3.15, center = true);
            }
        }

            // ---------------------------------------------
            // Projector long block
            // ---------------------------------------------
                        difference()
            {
        
        polyhedron(
                points = [
                    [0,0,Plate_hight],    // 0
                    [Projector_depth,0,Plate_hight],    // 1
                    [Projector_depth,Projector_width,Plate_hight],  // 2
                    [0,Projector_width,Plate_hight],  // 3
                    [0,0,Plate_base],   // 4
                    [Projector_depth,0,Plate_base],   // 5
                    [Projector_depth,Projector_width,Plate_base], // 6
                    [0,Projector_width,Plate_base]  // 7
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
            
                        union(){
            translate([12.2,24.1,Plate_hight])
            cylinder(10, 3.15, 3.15, center = true);
            
            translate([12.2,49.1,Plate_hight])
            cylinder(10, 3.15, 3.15, center = true);
                                       
            translate([62.2,24.1,Plate_hight])
            cylinder(10, 3.15, 3.15, center = true);
            
            translate([62.2,49.1,Plate_hight])
            cylinder(10, 3.15, 3.15, center = true);        
            }
       
        }
     
        }

}

holder ();

// =====================================================
// Base plate
// =====================================================
module base ()

{

        {
            // ---------------------------------------------
            // Projector outskirt block
            // ---------------------------------------------
            polyhedron(
                points = [
                    [Projector_depth,Base_start,Base_plate_higth],    // 0
                    [Projector_depth_thicc,Base_start,Base_plate_higth],    // 1
                    [Projector_depth_thicc,Projector_width_thicc,Base_plate_higth],  // 2
                    [Projector_depth,Projector_width_thicc,Base_plate_higth],  // 3
                    [Projector_depth,Base_start,0],   // 4
                    [Projector_depth_thicc,Base_start,0],   // 5
                    [Projector_depth_thicc,Projector_width_thicc,0], // 6
                    [Projector_depth,Projector_width_thicc,0]  // 7
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
            // Projector long block
            // ---------------------------------------------
            polyhedron(
                points = [
                    [0,Base_start,Base_plate_higth],    // 0
                    [Projector_depth,Base_start,Base_plate_higth],    // 1
                    [Projector_depth,Base_extend,Base_plate_higth],  // 2
                    [0,Base_extend,Base_plate_higth],  // 3
                    [0,Base_start,0],   // 4
                    [Projector_depth,Base_start,0],   // 5
                    [Projector_depth,Base_extend,0], // 6
                    [0,Base_extend,0]  // 7
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

        }

}

base ();


// =====================================================
// M6 grooves
// =====================================================
module M6 ()

        // ---------------------------------------------
        // Left block
        // ---------------------------------------------
translate([0,-M6_offset,0]){
    difference()
    {
        // ---------------------------------------------
        // Left block
        // ---------------------------------------------
        polyhedron(
                points = [
                    [0,-M6_wall,Base_plate_higth],    // 0
                    [(2*M6_wall) + M6_length,-M6_wall,Base_plate_higth],    // 1
                    [(2*M6_wall) + M6_length,M6_wall,Base_plate_higth],  // 2
                    [0,M6_wall,Base_plate_higth],  // 3
                    [0,-M6_wall,0],   // 4
                    [(2*M6_wall) + M6_length,-M6_wall,0],   // 5
                    [(2*M6_wall) + M6_length,M6_wall,0], // 6
                    [0,M6_wall,0]  // 7
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
        
        union()
        {
            // ---------------------------------------------
            // M6 groove
            // ---------------------------------------------
            polyhedron(
                points = [
                    [M6_wall,-M6_diameter,Base_plate_higth],    // 0
                    [M6_wall + M6_length,-M6_diameter,Base_plate_higth],    // 1
                    [M6_wall + M6_length,M6_diameter,Base_plate_higth],  // 2
                    [M6_wall,M6_diameter,Base_plate_higth],  // 3
                    [M6_wall,-M6_diameter,0],   // 4
                    [M6_wall + M6_length,-M6_diameter,0],   // 5
                    [M6_wall + M6_length,M6_diameter,0], // 6
                    [M6_wall,M6_diameter,0]  // 7
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
            // Front curve
            // ---------------------------------------------
            translate([M6_wall,0,0]){
            cylinder(Base_plate_higth,M6_diameter,M6_diameter);
            }
            // ---------------------------------------------
            // Rear curve
            // ---------------------------------------------
            translate([M6_wall + M6_length,0,0]){
            cylinder(Base_plate_higth,M6_diameter,M6_diameter);
            }
        }


    }
}

translate([0,-M6_offset + (4 * M6_grid),0]){
    difference()
    {
        // ---------------------------------------------
        // Left block
        // ---------------------------------------------
        polyhedron(
                points = [
                    [0,-M6_wall,Base_plate_higth],    // 0
                    [(2*M6_wall) + M6_length,-M6_wall,Base_plate_higth],    // 1
                    [(2*M6_wall) + M6_length,M6_wall,Base_plate_higth],  // 2
                    [0,M6_wall,Base_plate_higth],  // 3
                    [0,-M6_wall,0],   // 4
                    [(2*M6_wall) + M6_length,-M6_wall,0],   // 5
                    [(2*M6_wall) + M6_length,M6_wall,0], // 6
                    [0,M6_wall,0]  // 7
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
        
        union()
        {
            // ---------------------------------------------
            // M6 groove
            // ---------------------------------------------
            polyhedron(
                points = [
                    [M6_wall,-M6_diameter,Base_plate_higth],    // 0
                    [M6_wall + M6_length,-M6_diameter,Base_plate_higth],    // 1
                    [M6_wall + M6_length,M6_diameter,Base_plate_higth],  // 2
                    [M6_wall,M6_diameter,Base_plate_higth],  // 3
                    [M6_wall,-M6_diameter,0],   // 4
                    [M6_wall + M6_length,-M6_diameter,0],   // 5
                    [M6_wall + M6_length,M6_diameter,0], // 6
                    [M6_wall,M6_diameter,0]  // 7
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
            // Front curve
            // ---------------------------------------------
            translate([M6_wall,0,0]){
            cylinder(Base_plate_higth,M6_diameter,M6_diameter);
            }
            // ---------------------------------------------
            // Rear curve
            // ---------------------------------------------
            translate([M6_wall + M6_length,0,0]){
            cylinder(Base_plate_higth,M6_diameter,M6_diameter);
            }
        }


    }
}

M6 ();

// =====================================================
// Supports
// =====================================================
module support ()

{

        {
            // ---------------------------------------------
            // long support
            // ---------------------------------------------
            polyhedron(
                points = [
                    [Long_support-Support,0,Base_plate_higth],    // 0
                    [Long_support+Support,0,Base_plate_higth],    // 1
                    [Long_support+Support,Projector_width,Base_plate_higth],  // 2
                    [Long_support-Support,Projector_width,Base_plate_higth],  // 3
                    [Long_support-Support,0,Plate_base],   // 4
                    [Long_support+Support,0,Plate_base],   // 5
                    [Long_support+Support,Projector_width,Plate_base], // 6
                    [Long_support-Support,Projector_width,Plate_base]  // 7
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
            // Thicc supports
            // ---------------------------------------------
            polyhedron(
                points = [
                    [0,Thicc_support-Support,Base_plate_higth],    // 0
                    [Long_support-Support,Thicc_support-Support,Base_plate_higth],    // 1
                    [Long_support-Support,Thicc_support+Support,Base_plate_higth],  // 2
                    [0,Thicc_support+Support,Base_plate_higth],  // 3
                    [0,Thicc_support-Support,Plate_base],   // 4
                    [Long_support-Support,Thicc_support-Support,Plate_base],   // 5
                    [Long_support-Support,Thicc_support+Support,Plate_base], // 6
                    [0,Thicc_support+Support,Plate_base]  // 7
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
            
            
            translate([0,4*Thicc_support,0])
            polyhedron(
                points = [
                    [0,Thicc_support-Support,Base_plate_higth],    // 0
                    [Long_support-Support,Thicc_support-Support,Base_plate_higth],    // 1
                    [Long_support-Support,Thicc_support+Support,Base_plate_higth],  // 2
                    [0,Thicc_support+Support,Base_plate_higth],  // 3
                    [0,Thicc_support-Support,Plate_base],   // 4
                    [Long_support-Support,Thicc_support-Support,Plate_base],   // 5
                    [Long_support-Support,Thicc_support+Support,Plate_base], // 6
                    [0,Thicc_support+Support,Plate_base]  // 7
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

            translate([Long_support+Support,0,0])
            polyhedron(
                points = [
                    [0,Thicc_support-Support,Base_plate_higth],    // 0
                    [Thicc_support_edge,Thicc_support-Support,Base_plate_higth],    // 1
                    [Thicc_support_edge,Thicc_support+Support,Base_plate_higth],  // 2
                    [0,Thicc_support+Support,Base_plate_higth],  // 3
                    [0,Thicc_support-Support,Plate_base],   // 4
                    [Thicc_support_edge,Thicc_support-Support,Plate_base],   // 5
                    [Thicc_support_edge,Thicc_support+Support,Plate_base], // 6
                    [0,Thicc_support+Support,Plate_base]  // 7
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
            
            
            translate([Long_support+Support,4*Thicc_support,0])
            polyhedron(
                points = [
                    [0,Thicc_support-Support,Base_plate_higth],    // 0
                    [Thicc_support_edge,Thicc_support-Support,Base_plate_higth],    // 1
                    [Thicc_support_edge,Thicc_support+Support,Base_plate_higth],  // 2
                    [0,Thicc_support+Support,Base_plate_higth],  // 3
                    [0,Thicc_support-Support,Plate_base],   // 4
                    [Thicc_support_edge,Thicc_support-Support,Plate_base],   // 5
                    [Thicc_support_edge,Thicc_support+Support,Plate_base], // 6
                    [0,Thicc_support+Support,Plate_base]  // 7
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
            // angled supports
            // ---------------------------------------------
difference(){
    
    union(){
            polyhedron(
                points = [
                    [Long_support-Support,Projector_width_thicc,Support_angle_base],    // 0
                    [Long_support+Support,Projector_width_thicc,Support_angle_base],    // 1
                    [Long_support+Support,Projector_width,Support_angle_base],  // 2
                    [Long_support-Support,Projector_width,Support_angle_base],  // 3
                    [0,Projector_width_thicc,Plate_base],   // 4
                    [Projector_depth,Projector_width_thicc,Plate_base],   // 5
                    [Projector_depth,Projector_width,Plate_base], // 6
                    [0,Projector_width,Plate_base]  // 7
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
            
            polyhedron(
                points = [
                    [Long_support-Support,Projector_width_thicc,Support_angle_base],    // 0
                    [Long_support+Support,Projector_width_thicc,Support_angle_base],    // 1
                    [Long_support+Support,0,Support_angle_base],  // 2
                    [Long_support-Support,0,Support_angle_base],  // 3
                    [0,Projector_width_thicc,Plate_base],   // 4
                    [Projector_depth_thicc,Projector_width_thicc,Plate_base],   // 5
                    [Projector_depth_thicc,0,Plate_base], // 6
                    [0,0,Plate_base]  // 7
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
            
        }
            
                                   union(){
            translate([12.2,24.1,Plate_hight])
            cylinder(30, 3.15, 3.15, center = true);
            
            translate([12.2,49.1,Plate_hight])
            cylinder(30, 3.15, 3.15, center = true);
                                       
            translate([62.2,24.1,Plate_hight])
            cylinder(30, 3.15, 3.15, center = true);
            
            translate([62.2,49.1,Plate_hight])
            cylinder(30, 3.15, 3.15, center = true);        
            }

        }
    }

}

support ();
