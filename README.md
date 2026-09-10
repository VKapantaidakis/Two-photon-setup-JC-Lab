# Two Photon Setup — JC Lab

Two-photon imaging and behaviour setup for tethered *Drosophila*. A **Basler GigE camera** tracks a spherical treadmill through **FicTrac**, a **ViRMEn** virtual world is projected onto a **conical screen**, and an **Arduino** timestamps every two-photon frame trigger so imaging and behaviour can be aligned offline.

Built and documented on **Ubuntu 24.04 LTS** with **MATLAB R2014b**.
**JC Lab (Billeter Lab), University of Groningen.**

Everything here was run on a real machine and the commands are reproduced verbatim, including the workarounds for the awkward combinations (a 2014 MATLAB on a 2024 Linux, a Pylon SDK newer than the FicTrac fork expects, GigE over a USB-Ethernet adapter).

> ### ▶ Just want to run an experiment today?
> **[RUN-AN-EXPERIMENT.md](RUN-AN-EXPERIMENT.md)** — the step-by-step checklist: open MATLAB, run the config, start FicTrac, start the scan.
> The numbered `docs/` below are for building the rig from scratch.

---

## Hardware

| Component | Model / notes |
|---|---|
| Camera | Basler **acA1300-60gm**, GigE (Ethernet), 1280×1024 @ 60 fps |
| Camera link | RTL8153 USB-Ethernet adapter (see the MTU caveat in [01](docs/01-basler-camera.md)) |
| Microcontroller | Arduino Uno R3 |
| RTC | DS3231 (I²C) |
| Environment sensor | DHT22 |
| Illumination | IR LED array via IRF520 MOSFET module |
| Projection | projector onto a 3D-printed conical screen ([07](docs/07-3d-printed-parts.md)) |
| Treadmill | patterned foam sphere on an air support |
| Host | Dell Pro 14, Ubuntu 24.04.4 LTS |

## Software stack

```
Basler camera ──GigE──> FicTrac ──(TCP, optional closed loop)──> ViRMEn (MATLAB)
                                                                      │
2P frame TTL ──> Arduino ──USB serial──> arduinoFrameLog ─────────────┘
                                              │
                                              └──> per-frame CSV logs
```

In the **WhiteBack → BlackChamber** protocol documented here, ViRMEn's movement function is `moveWithKeyboard` — the fly does not drive the world. FicTrac records ball motion alongside; closed-loop is a separate protocol.

## Replicate it — follow in order

| # | Document | What it gets you |
|---|---|---|
| ▶ | **[Run an experiment](RUN-AN-EXPERIMENT.md)** | **daily checklist once the rig is built** |
| 00 | [User & OS setup](docs/00-user-setup.md) | Ubuntu user, groups, **Xorg session**, folder layout |
| 01 | [Basler camera](docs/01-basler-camera.md) | Pylon SDK, GigE network, live image |
| 02 | [FicTrac](docs/02-fictrac.md) | Built against Pylon, calibrated, tracking |
| 03 | [MATLAB R2014b](docs/03-matlab.md) | Installed, licensed, **two launchers** |
| 04 | [ViRMEn](docs/04-virmen.md) | Compiled for Linux, worlds rendering |
| 05 | [Arduino / DAQ](docs/05-arduino-daq.md) | Sketch, wiring, serial into MATLAB |
| 06 | [Experiment workflow](docs/06-experiment-workflow.md) | Running a session end to end |
| 07 | [3D printed parts](docs/07-3d-printed-parts.md) | Conical screen and mounts |
| 99 | [Troubleshooting](docs/99-troubleshooting.md) | Every error we hit, and its fix |

## Repository layout

```
matlab/     experiment scripts (see docs/06)
arduino/    daq_frame_logger_v6 sketch
patches/    source patches for FicTrac and ViRMEn
setup/      udev rule, desktop launchers
hardware/   3D print files
docs/       the guides above
```

## Five things that will cost you a day if you skip them

1. **Use an Xorg session, not Wayland.** FicTrac's GUI dies on Wayland with a protocol error. [→ 00](docs/00-user-setup.md)
2. **You need two MATLAB launchers.** `-softwareopengl` makes ViRMEn's design panels render but **segfaults** when an experiment runs; without it the experiment runs but the panels are blank. They cannot be reconciled. [→ 03](docs/03-matlab.md)
3. **MATLAB R2014b on Linux only sees `/dev/ttyS*`.** Your Arduino on `/dev/ttyACM0` is invisible until you symlink it. [→ 05](docs/05-arduino-daq.md)
4. **Do not enable jumbo frames** on a USB-Ethernet adapter. Pylon's optimiser sets MTU 9000, ping still works, and video silently dies. [→ 01](docs/01-basler-camera.md)
5. **One program per device.** Pylon Viewer blocks FicTrac; the DAQ monitor blocks the experiment script. Wait ~8 s after killing a client for the GigE heartbeat to expire. [→ 99](docs/99-troubleshooting.md)

## Contact

**If you have problems with anything in this repository, contact Vasilis Kapantaidakis:**

- **vaskapant@gmail.com**
- **v.kapantaidakis@student.rug.nl**

JC Lab (Billeter Lab), University of Groningen.
