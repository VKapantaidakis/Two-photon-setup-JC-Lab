# Conical visual stimulation system for Drosophila experiments

This repository contains the 3D-print files, control scripts, and documentation for a conical visual stimulation setup used for behavioral testing and two-photon calcium imaging in *Drosophila melanogaster*.

The system was developed to present controlled visual stimuli while preserving optical access for two-photon microscopy. It includes a conical rear-projection screen, 3D-printed supports, a folded projector path, Arduino-based synchronization for two-photon calcium imaging, and MATLAB/ViRMEn stimulus control.

## Repository structure

```text
.
├── arduino/
│   └── frame_counter/
├── calibration/
│   ├── cone_template/
│   └── projection_alignment/
├── docs/
├── hardware/
│   └── 3d_prints/
├── matlab_virmen/
│   ├── behavioral/
│   └── twophoton/
├── analysis/
│   ├── behavioral/
│   └── calcium_imaging/
└── figures/
```

## Folder purpose

| Folder | Purpose |
|---|---|
| `hardware/3d_prints/` | One folder containing all STL, 3MF, and OpenSCAD files for printed parts. |
| `arduino/` | Arduino TTL frame-counting and synchronization code used for the two-photon calcium-imaging workflow. |
| `matlab_virmen/` | MATLAB and ViRMEn stimulus-control scripts. |
| `calibration/` | Paper cone template, calibration grid, and projection-alignment documentation. |
| `analysis/` | Behavioral and calcium-imaging analysis documentation/scripts. |
| `docs/` | Thesis appendix, repository manifest, and protocol documentation. |
| `figures/` | Approved setup diagrams and photographs. |

## Hardware overview

The setup uses:

- Texas Instruments DLP3010 LightCrafter projector / DLP3010-based projection system
- rear-projection film mounted in a conical support
- 45° folding mirror
- 3D-printed conical screen supports and mounts
- Arduino Uno Rev3 for TTL frame counting and synchronization during two-photon calcium imaging
- MATLAB R2018a with ViRMEn

## Tested hardware and software environment

The setup was tested using the following hardware and software environment:

| Component | Tested setup |
|---|---|
| Operating system | Microsoft Windows 11 |
| MATLAB | MATLAB R2018a |
| Virtual reality engine | ViRMEn from the Tank Lab GitHub repository: `https://github.com/Tank-Lab/ViRMEn` |
| Arduino board | Arduino Uno Rev3 |
| Arduino software | Arduino IDE, latest installed version at the time of use |
| Projector / DMD | Texas Instruments DLP3010-based projector / DMD system |
| 3D printer | Original Prusa XL 5-Toolhead 3D Printer with enclosure |
| Filament | Prusament PLA Prusa Galaxy Black |
| Printed part confirmed | Current ring / conical support ring |

MATLAB R2018a was used because it is compatible with the ViRMEn workflow used for this setup.

The printed ring currently available for the setup was printed using Prusament PLA Prusa Galaxy Black on an Original Prusa XL 5-Toolhead 3D Printer with enclosure.

The ViRMEn version should be taken from the Tank Lab GitHub repository. For exact long-term reproducibility, record the ViRMEn commit or download date used for a specific experiment when available.

## Conical screen designs

Two related screen designs were used:

1. **Behavioral arena screen**: full-size conical screen with visible diameter 220 mm to 40 mm and height 60 mm.
2. **Two-photon screen**: reduced conical screen with visible diameter 110 mm to 20 mm and height 30 mm.

All 3D-print files should be placed in:

```text
hardware/3d_prints/
```

The README in that folder explains what every printable file is.

## Arduino synchronization

The Arduino frame counter was used for the two-photon calcium-imaging workflow. It listens for TTL pulses on digital pin 2. Each rising edge is counted as one acquired frame and sent to MATLAB over serial at 115200 baud:

```text
FRAME,<frame number>
```

The Arduino was not part of the freely moving behavioral experiment.

## MATLAB and ViRMEn

Two-photon stimulation files are stored in:

```text
matlab_virmen/twophoton/
```

Behavioral files, if added later, should be stored in:

```text
matlab_virmen/behavioral/
```

Before use, update local paths, serial port settings, and saved ViRMEn world locations in the master scripts.
