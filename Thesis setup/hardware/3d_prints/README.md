# 3D-print files

This folder is the single place for all 3D-print files used in the conical visual stimulation setup.

Keep all printable or slicer files here, including STL, 3MF, and OpenSCAD files. The goal is that someone can open this folder and understand what every printed part is for.

## Important screen-file distinction

There are two related conical screen designs:

1. **Full-size screen / behavioral arena screen**: the full-size design. In the uploaded files, this is the version labelled `Full screen Max Planck (Philip)`.
2. **Two-photon screen**: the reduced version used in the two-photon microscope setup. In the uploaded files, this is the version labelled `Full screen 2mm groove sized 0.5 when sliced`, meaning the full-screen design was used at 0.5 scale during slicing.

The two-photon screen is therefore the 0.5-scale file, not the Max Planck full-size file.

## File list and purpose

| Part | Recommended file name | Format | Purpose |
|---|---|---|---|
| Full-size screen / behavioral arena screen | `full_screen_max_planck_philip.stl` | STL | Full-size conical screen design. Uploaded originally as `Full screen Max Planck (Philip).stl`. |
| Full-size screen OpenSCAD design | `full_screen_max_planck_philip.scad` | SCAD | OpenSCAD source file for the full-size screen. Uploaded originally as `Full screen Max Planck (Philip).scad`. |
| Two-photon 0.5-scale screen | `twophoton_screen_0p5_scale_2mm_groove.stl` | STL | Reduced two-photon screen. Uploaded originally as `Full screen 2mm groove sized 0.5 when sliced.stl`. |
| Two-photon 0.5-scale screen OpenSCAD design | `twophoton_screen_0p5_scale_2mm_groove.scad` | SCAD | OpenSCAD source file for the reduced two-photon screen. Uploaded originally as `Full screen 2mm groove sized 0.5 when sliced.scad`. |
| Behavioral full-size conical screen project file | `behavioral_full_screen_2mm_groove.3mf` | 3MF | Slicer/project file for the full-size screen, if used. |
| Two-photon reduced conical screen project file | `twophoton_reduced_screen.3mf` | 3MF | Slicer/project file for the reduced two-photon screen. |
| Conical screen OpenSCAD design | `conical_screen_design.scad` | SCAD | Parametric design file for generating the conical screen and retaining rings. |
| Projector holder | `projector_holder_height_adjustable.stl` | STL | Holds and positions the Texas Instruments DLP3010 LightCrafter projector relative to the mirror and breadboard. |
| Projector holder OpenSCAD design | `projector_holder_height_adjustable.scad` | SCAD | Parametric source file for the projector holder. |
| Projector holder project file | `projector_holder_height_adjustable.3mf` | 3MF | Slicer/project file for the projector holder, if available. |
| Circular screen mounts | `screen_circular_mounts.3mf` | 3MF | Circular mounting parts used to stabilize or position the conical screen. |
| Fly plate | `Flyplate5.stl` | STL | Fly holder/plate component used with the setup. |
| 9 mm ball holder | `ball_9mm_holder_65mm.3mf` | 3MF | Adjustable ball-holder component, 9 mm ball size and 65 mm length. |
| 6 mm ball holder | `ball_6mm_holder_32mm.3mf` | 3MF | Adjustable ball-holder component, 6 mm ball size and 32 mm length. |

## Uploaded file names to keep or rename

The following original file names are acceptable, but the recommended names above are cleaner for long-term use:

```text
Full screen Max Planck (Philip).scad
Full screen Max Planck (Philip).stl
Full screen 2mm groove sized 0.5 when sliced.scad
Full screen 2mm groove sized 0.5 when sliced.stl
Flyplate5.stl
```

## Printing material

The ring used during setup testing was printed from Prusament PLA Prusa Galaxy Black on an Original Prusa XL 5-Toolhead 3D Printer with enclosure.

A matte charcoal-black PLA was considered as an alternative to reduce light reflections from the printed parts.

## Notes

Use descriptive file names and keep older test versions only if they are clearly labelled. For example, use `_old`, `_failed`, or `_prototype` only when the file is useful for documenting the design process.

Do not mix raw experimental data with 3D-print files in this folder.
