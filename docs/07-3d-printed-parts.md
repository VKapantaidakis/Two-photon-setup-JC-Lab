# 07 — 3D printed parts

Optomechanical mounting hardware for the rig: printed **optical posts and post holders** used to position the camera, mirrors, projector optics and the fly holder on the breadboard.

---

## Source and attribution

These parts come from the **PLAb: Optical Posts and Post Holders** system by **Louis Edelman (@LowBoom)**:

> https://www.printables.com/model/1729832-plab-optical-posts-and-post-holders

The published set contains 14 files — 8 post holders, 5 posts, and one example assembly (3MF). Only the two variants actually used on this rig are mirrored here; download the rest from the source page if you need other sizes.

> **Licence check before redistributing.** These are a third-party design. The two STEP files in `hardware/3d-prints/` are included for convenience of replication, but confirm the licence terms on the Printables page permit redistribution, and keep the attribution above with any copy. If the licence does not allow it, remove the files from this repo and rely on the link.

## Parts used on this rig

| File | Part | Interpretation of the name |
|---|---|---|
| `hardware/3d-prints/post_L50_A_M6.step` | Optical post | **L50** = 50 mm length · **A** = variant A · **M6** = M6 threaded interface |
| `hardware/3d-prints/holder_w50_h75_lr_M6.step` | Post holder | **w50** = 50 mm width · **h75** = 75 mm height · **lr** = left/right clamp variant · **M6** = M6 mounting |

Both were exported from Onshape as **STEP AP242**.

<!-- TODO (Vasilis): confirm the "A" and "lr" variant meanings against the source page,
     and record how many of each are used on the rig and for what (camera arm,
     projector mount, fly holder, etc.). -->

## Hardware required

The M6 designation means these interface with standard metric optomechanics:

- **M6 screws** for the breadboard interface (length depends on breadboard thickness)
- **M6 threaded inserts** — heat-set brass inserts are the usual approach for printed parts; printed threads work but wear quickly under repeated adjustment
- Standard optical breadboard with M6 tapped holes

<!-- TODO (Vasilis): record the exact screw lengths and insert part numbers used. -->

## Print settings

<!-- TODO (Vasilis): fill in from your actual prints. The source page does not
     publish recommended settings, so the numbers below are placeholders to be
     replaced with what worked. -->

| Setting | Value |
|---|---|
| Printer | *(to fill in)* |
| Material | *(PLA / PETG / ASA — PETG or ASA preferred for dimensional stability under lamp heat)* |
| Layer height | *(to fill in)* |
| Infill | *(to fill in — posts want high infill or solid for rigidity)* |
| Perimeters | *(to fill in)* |
| Supports | *(to fill in)* |
| Orientation | *(to fill in — posts printed vertically are weakest along the layer lines; consider printing horizontally or increasing perimeters)* |

**Rigidity matters more than speed here.** A post that flexes moves the camera between sessions and invalidates the FicTrac calibration ([02](02-fictrac.md)), which is tied to the exact camera position.

## Assembly notes

<!-- TODO (Vasilis): photograph the assembled mounts and describe which part
     holds what. A photo per mount point is worth more than paragraphs. -->

## Why this matters for the data

The FicTrac camera-to-animal transform is calibrated for one specific camera pose. If a printed mount creeps, slips or is disturbed, the calibration silently degrades — the tracking still runs, the numbers still look plausible, and the ball motion is wrong.

Practical consequences:

- Tighten and, where possible, mark mount positions so drift is visible.
- Re-run `configGui` after any change to the camera position ([02](02-fictrac.md)).
- Record in the session metadata when mounts were adjusted.

---

Next: [99 — Troubleshooting](99-troubleshooting.md)

---

*JC Lab, University of Groningen. Problems with this guide? Contact Vasilis Kapantaidakis — vaskapant@gmail.com or v.kapantaidakis@student.rug.nl*
