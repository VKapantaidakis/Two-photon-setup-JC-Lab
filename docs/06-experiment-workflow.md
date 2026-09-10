# 06 — Experiment workflow

Running the **WhiteBack → BlackChamber** protocol: two visual worlds shown in sequence, switched on two-photon frame count, with every frame timestamped and logged.

Prerequisites: [00](00-user-setup.md)–[05](05-arduino-daq.md) complete.

---

## The protocol

1. Ask for experiment metadata (Command Window).
2. Open ViRMEn.
3. Open the Arduino via `arduinoFrameLog` (single reader).
4. **Wait for the first DAQ/2P frame pulse** — the script can be armed before the scan starts.
5. Load the **WhiteBack** world, run it until its frame threshold.
6. Switch to the **BlackChamber** world, run it likewise.
7. Save per-phase CSV logs and plot the session.

The movement function is `moveWithKeyboard` — **the fly does not drive the world in this protocol**. World switching is driven purely by 2P frame count. FicTrac, if running, records ball motion alongside.

## Files

| File | Role |
|---|---|
| [`MasterSwitchByDAQ_WhiteBack_BlackChamber.m`](../matlab/MasterSwitchByDAQ_WhiteBack_BlackChamber.m) | the script you run |
| [`WhiteBack.m`](../matlab/WhiteBack.m) / [`BlackChamber.m`](../matlab/BlackChamber.m) | phase logic (end after N frames) |
| `WhiteBack.mat` / `BlackChamber.mat` | the visual worlds |
| [`arduinoFrameLog.m`](../matlab/arduinoFrameLog.m) | serial reader, logger, live panel |
| [`plotSession.m`](../matlab/plotSession.m) | post-hoc plots and summary |

Install all of them into `~/Documents/MATLAB/virmen/experiments/`.

## Configuration block

At the top of the master script:

```matlab
SERIAL_PORT       = '/dev/ttyS101';   % symlink to /dev/ttyACM0 (see doc 05)
baudRate          = 115200;

SHOW_LIVE_MONITOR = true;   % live DAQ panel during the run
MONITOR_EVERY     = 10;     % panel refresh every N frames
AUTO_PLOT_AT_END  = true;   % plot the session when finished
PRINT_EVERY       = 50;     % console line every N frames (0 = off; 1 = every frame)

FULLSCREEN_VR     = false;  % true once the projector is a second display
VR_MONITOR        = 1;      % 1 = primary/laptop, 2 = projector
VR_WIN_W          = 900;    % windowed geometry (when FULLSCREEN_VR = false)
VR_WIN_H          = 700;
VR_WIN_LEFT       = 950;
VR_WIN_BOTTOM     = 300;
```

Frames per phase live in the phase files — `vr.frameThreshold` in `WhiteBack.m` and `BlackChamber.m`.

### Single screen vs projector

**Testing on one screen:** `FULLSCREEN_VR = false`. A windowed VR view sits beside the live monitor panel. With fullscreen on a single display, the VR window covers everything including the panel.

**With the projector**, extend the desktop rather than mirroring:

```bash
xrandr --listmonitors
xrandr | grep -E " connected"
xrandr --output <PROJECTOR> --auto --right-of <LAPTOP>
```

then set `FULLSCREEN_VR = true; VR_MONITOR = 2;`. The fly gets the projector fullscreen; the laptop screen keeps MATLAB and the monitor panel. You do not want your desktop and mouse pointer projected at the animal between trials.

## Running a session

Launch from the **MATLAB 2P EXPERIMENT (hardware GL)** icon — **not** the design one, which segfaults on Run ([03](03-matlab.md)).

```matlab
close all force
clear global guifig
clear all
clear functions
instrreset
MasterSwitchByDAQ_WhiteBack_BlackChamber
```

The preamble is not superstition: `clear functions` defeats MATLAB's function cache, `clear global guifig` clears a stale ViRMEn handle from a previous crash, and `instrreset` releases any serial object still holding the port.

Then:

1. **Metadata** — answer in the Command Window (experimenter, strain, age in days, sex, experiment name, notes). Command Window rather than a dialog because `inputdlg` is unreliable in the hardware-GL launcher.
2. ViRMEn opens; the Arduino is opened, zeroed, and started.
3. `Waiting for first DAQ/Arduino frame pulse ...` — **now start the 2P scan.**
4. WhiteBack loads and runs to its threshold, then BlackChamber.
5. Logs are written and the session is plotted.

### Stopping a run

- **ESC** in the ViRMEn window ends it normally
- **Ctrl+C** in the Command Window
- If a fullscreen window traps the display: **Alt+Tab** away, or `Ctrl+Alt+F3` to a text console and `pkill MATLAB`

After any abort, run `instrreset` before trying again.

## Output

```
~/Documents/MATLAB/ExperimentData/
└── 20260819/
    └── Vasilis_CS_WhiteBlackSwitch_154312/
        ├── metadata.txt / metadata.mat
        ├── sess_20260819_154312_allframes.csv
        ├── sess_20260819_154312_WhiteBack.csv
        ├── sess_20260819_154312_BlackChamber.csv
        ├── sess_20260819_154312_sync.csv
        └── sess_20260819_154312_frameLogTable.mat
```

CSV columns: `phase, frame, arduino_time, matlab_time, t_rel_s, dt_ms, A0_V, A1_V, tempC, RH_pct, sketch_missed`.

`*_sync.csv` records the Arduino RTC against the MATLAB clock at the first and last frame — that is your offset for aligning with the imaging data.

## Live feedback during a run

**Panel** (`SHOW_LIVE_MONITOR`): frames, rate, dt mean/sd, dropped-in-transit, sketch-missed, temp/RH, current phase, plus a rolling frame-interval plot. Driven from inside `arduinoFrameLog('poll')`, so it shares the one port connection.

**Console** (`PRINT_EVERY`):

```
[WhiteBack] frames 50      seq 1247     29.98 Hz  dropped 0  missed 0  23.4C 41%RH
```

`PRINT_EVERY = 1` prints every frame. Fine for verification; for real recordings use 10–50 so console I/O does not compete with the render loop. Printing text is much cheaper than redrawing figures — prefer the console over a fast panel refresh.

## After the run

```matlab
plotSession                              % most recent session, found automatically
plotSession('/path/to/session/folder')   % a specific one
```

Four panels — frame timing coloured by phase, cumulative frames, analog channels, temp/RH — plus a per-phase summary:

```
phase              frames    dur (s)  rate (Hz)    dt mean      dt sd
preTrigger             12       0.40      29.97     33.361      0.388
WhiteBack             600      20.01      29.98     33.355      0.412
interval                8       0.27      29.99     33.348      0.301
BlackChamber          600      20.02      29.97     33.362      0.395

Frames lost in transit (sequence gaps): 0
```

**Check these before trusting a session:**

- `Frames lost in transit` should be **0**. Non-zero means the serial link dropped lines — reduce `PRINT_EVERY`, close other applications, check the USB cable.
- `Missed by sketch` should be **0**. Non-zero means triggers arrived faster than the Arduino could send — the trigger rate is too high for 115200 baud.
- `rate` should match your 2P scan rate.
- `dt sd` should be small relative to `dt mean`. Large scatter means jitter somewhere in the chain.

## Adapting the protocol

**Different worlds:** point `whiteBackMat` / `blackChamberMat` at your own `.mat` files and pass the matching code handles to `loadSavedExperimentIntoGui`.

**Different phase lengths:** edit `vr.frameThreshold` in each phase file.

**Closed loop with FicTrac:** change the movement function from `moveWithKeyboard` to your FicTrac movement function and start FicTrac with its TCP output enabled ([02](02-fictrac.md)).

**Writing a new phase file:** copy `WhiteBack.m`. The pattern is initialization → runtime → termination, and the runtime function must call `arduinoFrameLog('poll')` then read `latestArduinoFrame` from the base workspace — never the serial port directly.

---

Next: [07 — 3D printed parts](07-3d-printed-parts.md) · [99 — Troubleshooting](99-troubleshooting.md)

---

*JC Lab, University of Groningen. Problems with this guide? Contact Vasilis Kapantaidakis — vaskapant@gmail.com or v.kapantaidakis@student.rug.nl*
