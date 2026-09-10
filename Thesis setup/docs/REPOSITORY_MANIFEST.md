# Repository manifest

This repository archives the files required to reproduce the conical visual stimulation setup used for behavioral testing and two-photon calcium imaging.

## Core folders

| Folder | Contents |
|---|---|
| `hardware/3d_prints/` | All STL, 3MF, and OpenSCAD files for printed parts, with one README explaining each part. |
| `arduino/` | Arduino TTL frame-counting and synchronization code used for the two-photon calcium-imaging workflow. |
| `matlab_virmen/` | MATLAB and ViRMEn stimulus-control scripts. |
| `calibration/` | Paper cone template, calibration grid, projection-analysis PDF, and alignment documentation. |
| `analysis/` | Post-acquisition behavioral and calcium-imaging analysis documentation/scripts. |
| `docs/` | Thesis appendix and repository documentation. |
| `figures/` | Approved setup diagrams and photographs. |

## Files already added

- `README.md`
- `.gitignore`
- `LICENSE_PENDING.txt`
- `arduino/README.md`
- `arduino/frame_counter/frame_counter.ino`
- `matlab_virmen/README.md`
- `matlab_virmen/twophoton/README.md`
- `matlab_virmen/behavioral/WhiteChamber.m`
- `matlab_virmen/behavioral/WhiteChamberDots.m`
- `matlab_virmen/behavioral/MasterSwitchByDAQ600_LoadedWorlds_NOTES.md`
- `hardware/3d_prints/README.md`
- `calibration/cone_template/README.md`
- `calibration/projection_alignment/README.md`
- `analysis/README.md`
- `analysis/behavioral/README.md`
- `analysis/calcium_imaging/README.md`
- `figures/README.md`
- `docs/APPENDIX_TECHNICAL_PROTOCOL.tex`

## Files still to upload manually

Upload all 3D-print files into `hardware/3d_prints/`:

- full-size behavioral screen STL and 3MF files
- reduced two-photon screen STL and 3MF files
- conical screen OpenSCAD file
- projector-holder STL, 3MF, and OpenSCAD files
- circular screen mount files
- 6 mm and 9 mm ball-holder 3MF files

Upload calibration and experiment files into the relevant folders:

- exact A4 cone-template PDF used for centering
- calibration grid image
- projection-analysis PDF in `calibration/projection_alignment/`
- saved ViRMEn `.mat` world files
- finalized analysis scripts

## Data policy

Raw videos, raw two-photon imaging files, and large experimental datasets should not be committed to this repository unless a separate data-release plan is approved.
