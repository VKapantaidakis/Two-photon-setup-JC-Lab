# How to run an experiment

The day-to-day checklist. Follow it top to bottom. Assumes the rig is already installed — if not, start at [docs/00-user-setup.md](docs/00-user-setup.md).

**Problems? Contact Vasilis Kapantaidakis — vaskapant@gmail.com or v.kapantaidakis@student.rug.nl**

---

## Before you start

- [ ] Camera powered and Ethernet connected
- [ ] Arduino plugged in via USB
- [ ] Projector on
- [ ] Ball and air supply on
- [ ] **Arduino IDE Serial Monitor CLOSED** (it blocks MATLAB from the port)
- [ ] **Pylon Viewer CLOSED** (it blocks FicTrac from the camera)

---

## Step 1 — Open a terminal and check the hardware

```bash
ping -c 2 192.168.4.3
ls -l /dev/ttyS101
```

**Good:** ping replies, and `/dev/ttyS101` exists.

If the ping fails → camera is off or unplugged.
If `/dev/ttyS101` is missing → run `sudo ln -sf /dev/ttyACM0 /dev/ttyS101`.

---

## Step 2 — Calibrate FicTrac *(only if the camera moved)*

Skip this if nobody touched the camera since the last session.

```bash
cd ~/Documents/fictrac-experiments
source /opt/pylon/bin/pylon-setup-env.sh /opt/pylon
~/fictrac/bin/configGui config.txt
```

Answer the prompts **one at a time** (do not type ahead):

- "keep the existing sphere ROI?" → **n** (to redraw it)
- "keep the existing ignore regions?" → **n**
- "keep the existing transform?" → **n**

Drawing the ball circle:

- Click **6–8 single points** around the edge of the ball (like clock positions 12, 2, 4, 6, 8, 10)
- **Do not drag** — single clicks only
- Right-click undoes the last point
- **Click on the image window first**, then press **ENTER** to accept

Check the result:

```bash
xdg-open ~/Documents/fictrac-experiments/fictrac-configImg.png
```

The red circle must sit on the edge of the ball. If not, run `configGui` again.

---

## Step 3 — Start FicTrac

```bash
cd ~/Documents/fictrac-experiments
source /opt/pylon/bin/pylon-setup-env.sh /opt/pylon
~/fictrac/bin/fictrac config.txt
```

A window opens showing the ball with tracking overlay, and numbers scroll in the terminal.

**Test it:** spin the ball by hand. The numbers should change sensibly.

**Leave this running.** Use a different terminal for anything else.

To stop later: click the FicTrac window and press **ESC**.

---

## Step 4 — Open MATLAB

Click the **"MATLAB 2P EXPERIMENT (hardware GL)"** icon in the applications menu.

> ⚠️ **Not** the "ViRMEn DESIGN" icon. That one crashes when an experiment runs.
> DESIGN is only for building worlds.

---

## Step 5 — Clean start in MATLAB

Paste this into the MATLAB Command Window every time, before running:

```matlab
close all force
clear global guifig
clear all
clear functions
instrreset
```

This clears leftovers from any previous run. Skipping it causes strange errors.

---

## Step 6 — Run the experiment

```matlab
MasterSwitchByDAQ_WhiteBack_BlackChamber
```

---

## Step 7 — Fill in the fly details

The Command Window asks for these one at a time. Type the answer, press Enter:

```
Experimenter name        :
Fly strain / genotype    :
Fly age (days)           :
Sex (M/F)                :
Experiment name          :
Notes (optional)         :
```

This creates the data folder and saves a metadata file with the session.

---

## Step 8 — Wait for the script to arm

ViRMEn opens and the Arduino connects. You will see:

```
Master script is armed.
Waiting for first DAQ/Arduino frame pulse on /dev/ttyS101 ...
```

---

## Step 9 — Start the two-photon scan

**Now start the 2P.** The first frame trigger starts the experiment automatically.

You will see:

```
First DAQ pulse received.
=== Running WhiteBack ===
```

---

## Step 10 — Watch it run

- The **VR window** shows the world the fly sees
- The **live panel** shows frames, rate, dropped frames, temperature
- The **Command Window** prints a line as frames arrive

The white world runs for its set number of frames, then switches automatically to the black world.

**To stop early:** press **ESC** in the ViRMEn window, or **Ctrl+C** in MATLAB.

---

## Step 11 — When it finishes

It saves the data and opens a summary plot by itself. Check the table it prints:

```
phase              frames    dur (s)  rate (Hz)    dt mean      dt sd
WhiteBack             600      20.01      29.98     33.355      0.412
BlackChamber          600      20.02      29.97     33.362      0.395

Frames lost in transit (sequence gaps): 0
```

**These two numbers must be 0:**

- `Frames lost in transit` — if not 0, the serial link dropped data
- `Missed by sketch` — if not 0, triggers came faster than the Arduino could send

If either is non-zero, the session's frame alignment is unreliable.

---

## Step 12 — Find your data

```
~/Documents/MATLAB/ExperimentData/<date>/<yourname>_<strain>_<experiment>_<time>/
```

Inside:

| File | What it is |
|---|---|
| `metadata.txt` | the fly details you typed |
| `*_allframes.csv` | every frame, all phases |
| `*_WhiteBack.csv` | white phase only |
| `*_BlackChamber.csv` | black phase only |
| `*_sync.csv` | Arduino clock vs MATLAB clock — use this to align with imaging |

To re-plot a session later:

```matlab
plotSession                     % most recent
plotSession('/path/to/folder')  % a specific one
```

---

## Running another fly

1. Press **ESC** in the ViRMEn window if it is still open
2. Run the clean-start block from **Step 5** again
3. Go from **Step 6**

You do **not** need to redo the FicTrac calibration unless the camera moved.

---

## If something goes wrong

| What you see | Do this |
|---|---|
| `Port /dev/ttyS101 is not available` | `sudo ln -sf /dev/ttyACM0 /dev/ttyS101`, then `instrreset` in MATLAB |
| `The device is controlled by another application` | Close Pylon Viewer / other FicTrac. Wait 8 seconds. Try again |
| MATLAB crashes when the world loads | You used the DESIGN icon. Use **2P EXPERIMENT** |
| `guidata ... H must be the handle` | Run the Step 5 clean-start block |
| Nothing happens after "armed" | The 2P is not sending triggers. Check it is scanning and the BNC reaches Arduino pin D2 |
| ViRMEn design panels are blank | Normal in the EXPERIMENT launcher. Use DESIGN only for editing worlds |

Full list: [docs/99-troubleshooting.md](docs/99-troubleshooting.md)

---

**Still stuck? Contact Vasilis Kapantaidakis — vaskapant@gmail.com or v.kapantaidakis@student.rug.nl**
