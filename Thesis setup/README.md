# Thesis setup

Design, build and calibration material for the **conical visual stimulation system** - the rig used for behavioural testing and two-photon calcium imaging in *Drosophila melanogaster*.

This folder is the archived content of the original project repository. It documents **how the rig was designed and built**; the numbered guides in [`../docs/`](../docs/) document **how to install and operate the software** on the Ubuntu machine.

**Author:** Vasilis Kapantaidakis - JC Lab (Billeter Lab), University of Groningen

---

## The two screens - key numbers

Two conical rear-projection screens were built from the same parametric design.

| | Behavioural arena screen | Two-photon screen |
|---|---|---|
| Visible diameter | 220 mm -> 40 mm | 110 mm -> 20 mm |
| Height | 60 mm | 30 mm |
| Print file | `Full screen Max Planck (Philip).stl` | `Full screen 2mm groove sized 0.5 when sliced.stl` |
| Relationship | full size | **the same design sliced at 0.5 scale** |

### Paper cone templates (midline / centering check)

Generated with **templatemaker.nl/en/cone**, printed at 100% scale on A4, and used to find the midline before the rear-projection film was fitted.

Two-photon screen:

    BOTTOM = 113 mm    TOP = 17 mm    H = 32 mm    A4, mm
    https://www.templatemaker.nl/en/cone/?BOTTOM=113&TOP=17&H=32&PAGEPRESET=A4&UNITS=mm

Behavioural arena screen:

    BOTTOM = 226 mm    TOP = 34 mm    H = 64 mm    A4, mm
    https://www.templatemaker.nl/en/cone/?BOTTOM=226&TOP=34&H=64&PAGEPRESET=A4&UNITS=mm

> **Note on the numbers.** The template values above (113/17/32 and 226/34/64) are the *corrected* ones and supersede the earlier draft figures of 110/20/30 and 220/40/60 that still appear in some places. The template dimensions are the outer paper geometry; the "visible diameter" figures in the table above are the screen aperture. Use the template values when generating a new cone.

---

## What is in here

| Folder | Contents |
|---|---|
| `hardware/` | All STL, 3MF and OpenSCAD files for printed parts, with a README explaining each one |
| `calibration/` | Cone templates and projector/mirror/screen alignment, including the projection-analysis PDF |
| `docs/` | `APPENDIX_TECHNICAL_PROTOCOL.tex` - the full thesis technical appendix, plus the repository manifest |
| `figures/` | Setup photographs: both screens, the template/midline step, the fly preparation, the imaging area of interest |
| `matlab_virmen/` | The original MATLAB R2018a / ViRMEn worlds and master scripts |
| `arduino/` | The original TTL frame-counter sketch |
| `analysis/` | Behavioural and calcium-imaging analysis notes, and the ImageJ to Excel workflow template |

Also here: `README-original-repo.md` (the original repository README) and `gitignore-original.txt` (its ignore rules, renamed so they do not silently exclude files from this repository).

## Optical setup

- Texas Instruments **DLP3010 LightCrafter** projector
- **45 degree folding mirror** to keep the projector clear of the objective
- Rear-projection film in the printed conical support
- 3D-printed height-adjustable projector holder, mirror holder, screen mounts

The projector, mirror and cone are **mechanically aligned first**; software offsets only correct small residual error. The alignment grid uses concentric circles, radial spokes and crosshairs.

## 3D printing

Printed on an **Original Prusa XL** (5-toolhead, enclosed) in **Prusament PLA Galaxy Black**. A matte charcoal-black PLA was considered as an alternative to reduce reflections from the printed parts - worth trying, since stray light off the cone reaches the animal.

Parts: conical screens (both scales), projector holder, mirror holder, circular screen mounts, fly plate, and 6 mm / 9 mm ball holders. See `hardware/3d_prints/README.md` for the file-by-file breakdown.

> **Duplicate files.** `Full screen 2mm groove (1).stl` and `(2).stl` are almost certainly the same file saved twice - both are 269,684 bytes. All four screen STLs share that size, which is expected rather than suspicious: scaling an STL does not change its triangle count, so the 0.5-scale two-photon screen is byte-for-byte the same size as the full-size one. Worth pruning at some point; kept here for completeness.

## Technical appendix

`docs/APPENDIX_TECHNICAL_PROTOCOL.tex` is the complete written protocol, covering: required components, conical screen design, 3D printing and assembly, projection-path geometry, optical alignment, spectral filtering, MATLAB/ViRMEn workflow, Arduino synchronisation, behavioural implementation, setup checklist and troubleshooting.

## Analysis

Calcium imaging follows an **ImageJ/Fiji to Excel** route: ROI mean intensities are exported per frame, then baseline-normalised (dF/F) against pre-stimulus frames and aligned to the black/white stimulus epochs.

`analysis/calcium_imaging/Results_darktowhite1518.csv.xlsx` is **real data from a dark-to-white recording**, five ROIs, kept as a worked template. To reuse it: copy it first, replace the ImageJ/Fiji export, and check the formula columns still point at the right columns. Record the baseline frame range and the stimulus onset/offset frames for each experiment - the workbook does not carry them.

The final two-photon protocol used black and white visual stimulation, **1500 imaging frames per stimulus followed by a 300-frame break**.

---

## Relationship to the rest of this repository

| This folder (`Thesis setup/`) | The rest of the repo |
|---|---|
| MATLAB **R2018a**, Windows | MATLAB **R2014b**, Ubuntu 24.04 |
| Original design and build record | Current working installation |
| `frame_counter.ino` - simple `FRAME,n` counter | `daq_frame_logger_v6.ino` - RTC timestamps, analog channels, temp/RH |
| `MasterSwitchByDAQ600*.m` | `MasterSwitchByDAQ_WhiteBack_BlackChamber.m` |

The scripts here are the **earlier generation**. The versions in [`../matlab/`](../matlab/) are the current ones: ported to Linux and R2014b, and rebuilt around a single-reader serial model. Keep both - this folder is the record of how the rig was designed, not the code to run today.

## Licensing note

The original repository carried `LICENSE_PENDING.txt`, stating that a licence had to be approved by the lab before publication. If that has not happened yet, keep this repository **private** until it has.

---

*JC Lab, University of Groningen. Questions: Vasilis Kapantaidakis - vaskapant@gmail.com or v.kapantaidakis@student.rug.nl*
