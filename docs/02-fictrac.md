# 02 — FicTrac (built against Pylon)

[FicTrac](https://github.com/rjdmoore/fictrac) reconstructs the path of an animal walking on a patterned sphere. Upstream supports FLIR/Spinnaker cameras; Basler support comes from a community fork, which needs one patch to build against a modern Pylon SDK.

Prerequisite: [01 — Basler camera](01-basler-camera.md) complete, with a live image in Pylon Viewer.

---

## 1. Dependencies

```bash
sudo apt-get update
sudo apt-get install -y \
  git build-essential gcc g++ cmake pkg-config \
  libopencv-dev \
  libboost-all-dev \
  libnlopt-dev libnlopt-cxx-dev \
  libavcodec-dev libavformat-dev libavutil-dev libswscale-dev \
  libgtk2.0-dev yasm unzip tar curl
```

> **Do not install `libavresample-dev`.** Older FicTrac docs list it, but it was removed in FFmpeg 5 (which Ubuntu 24.04 ships) and the package no longer exists — `apt` will fail with "unable to locate package". FicTrac builds fine without it; `libswscale-dev` covers the same ground.

## 2. Clone the Basler fork

```bash
cd ~
git clone https://github.com/neurophysiology-expertise-unit/fictrac-basler.git fictrac
cd fictrac
```

## 3. Patch for modern Pylon

The fork includes a USB3-specific header that **does not exist** in Pylon 7/8:

```
fatal error: pylon/usb/BaslerUsbInstantCameraArray.h: No such file or directory
```

There is no `pylon/usb/` directory in modern Pylon at all. The fix is one line — and it is safe, because the source only ever uses the generic `Pylon::CInstantCamera`, which handles GigE and USB3 alike.

In `include/BaslerSource.h`, line 16:

```diff
-#include <pylon/usb/BaslerUsbInstantCameraArray.h>
+#include <pylon/InstantCameraArray.h>
```

Or apply it directly:

```bash
sed -i 's|#include <pylon/usb/BaslerUsbInstantCameraArray.h>|#include <pylon/InstantCameraArray.h>|' \
  ~/fictrac/include/BaslerSource.h
```

See also `patches/fictrac-BaslerSource.patch`.

## 4. Build

```bash
cd ~/fictrac
source /opt/pylon/bin/pylon-setup-env.sh /opt/pylon
mkdir -p build && cd build
cmake -DBASLER_USB3=ON -DBASLER_DIR="/opt/pylon" ..
cmake --build . --config Release --parallel $(nproc)
```

> The flag is named `BASLER_USB3` but is **correct for a GigE camera**. It enables the Basler code path; Pylon's `CInstantCamera` API drives both transports through the same code. There is no separate GigE flag.

Binaries land in `~/fictrac/bin/`:

```bash
ls -la ~/fictrac/bin/       # expect: fictrac, configGui
```

Optionally make them available everywhere:

```bash
sudo cp ~/fictrac/bin/* /usr/local/bin
```

## 5. Verify without a camera

```bash
cd ~/fictrac/sample
../bin/fictrac config.txt
```

With `src_fn : basler` and no camera attached, the correct output is:

```
Opening Basler Camera...
Error opening capture device! No Basler devices found!
```

That is a **pass** — it proves the Basler code path compiled in and is trying to open a camera.

## 6. Set up an experiment config

```bash
mkdir -p ~/Documents/fictrac-experiments
cp ~/fictrac/sample/config.txt ~/Documents/fictrac-experiments/config.txt
cd ~/Documents/fictrac-experiments
grep -n "src_fn" config.txt        # must read: src_fn : basler
```

## 7. Calibrate with `configGui`

**Run without `sudo`.** GigE cameras need no root (that is a USB3 requirement), and a root GUI process under any display server hits permission problems — under Wayland it fails outright, and even on Xorg you get `QStandardPaths: runtime directory ... is not owned by UID 0`. The `Recorder processing thread unable to set thread priority!` warnings are harmless.

Make sure nothing else holds the camera first:

```bash
pkill -f pylonviewer; pkill -f configGui; pkill -f fictrac
sleep 8                                    # let the GigE heartbeat expire
pgrep -a "pylonviewer|configGui|fictrac" || echo "camera free"
```

Then:

```bash
cd ~/Documents/fictrac-experiments
source /opt/pylon/bin/pylon-setup-env.sh /opt/pylon
~/fictrac/bin/configGui config.txt
```

A successful open looks like:

```
Found 1 Basler device(s). Connecting to index 0...
Opening Basler camera device: acA1300-60gm
Basler camera initialised (1280x1024 @ 59.952 fps)!
```

### Starting from a clean calibration

The sample config ships with the demo video's ROI and transform. To be asked nothing and configure everything fresh:

```bash
cd ~/Documents/fictrac-experiments
cp config.txt config_backup_$(date +%H%M).txt
sed -i '/^roi_/d; /^c2a_r/d; /^c2a_t/d' config.txt
~/fictrac/bin/configGui config.txt
```

### How to answer the prompts

This trips people up, so read it before you start:

- **y/n questions are answered in the terminal.** **ENTER and ESC are keystrokes in the image window** — click the image first, then press them.
- **Answer one prompt at a time.** Typing ahead queues characters in stdin, which later prompts then consume; you end up silently keeping the sample's calibration. If you see prompts answering themselves, that is what happened.
- Answer **n** to "keep the existing …" unless you deliberately want the previous calibration.

### Drawing the ball ROI

- **Single deliberate clicks**, 6–8 points spread around the ball's edge (clock positions 12, 2, 4, 6, 8, 10). Dragging produces clusters of duplicate points and a poor circle fit.
- Right-click removes the last point.
- Click only where the ball's **true circumference** is visible — not along an edge where the fly holder or a pipette cuts across it.

### Check the fit before trusting it

`configGui` writes an image with the fitted circle drawn in red:

```bash
xdg-open ~/Documents/fictrac-experiments/fictrac-configImg.png
```

The circle should sit neatly on the ball's edge. If it does not, redo the ROI — every downstream number depends on it.

## 8. Run tracking

```bash
cd ~/Documents/fictrac-experiments
source /opt/pylon/bin/pylon-setup-env.sh /opt/pylon
~/fictrac/bin/fictrac config.txt
```

A live window shows the ball with the tracking overlay, and numbers stream in the terminal. **Spin the ball by hand** — roll it forward and the forward-motion column should change; rotate it and heading should change. Incoherent numbers mean the calibration is wrong, not the software.

Output files: `*.dat` (one row per frame) and `*.log`.

### Stopping FicTrac

- **ESC** in the FicTrac window (click it first so it has focus) — the clean exit; closes the camera and finishes the `.dat` file.
- **Ctrl+C** in the terminal.
- `pkill -f fictrac` from another terminal; `pkill -9 -f fictrac` if unresponsive (skips cleanup, may truncate output).

Then **wait ~8 s** before starting anything else that uses the camera.

## 9. Closed loop into ViRMEn (optional)

For closed-loop protocols, FicTrac publishes over TCP and MATLAB reads it:

```matlab
vr.socket = tcpclient('127.0.0.1', 3000);
```

Check the socket settings in your config:

```bash
grep -nE "sock|port|out_" config.txt
```

> The **WhiteBack → BlackChamber** protocol in [06](06-experiment-workflow.md) does **not** use this — its movement function is `moveWithKeyboard` and world switching is driven by 2P frame count. FicTrac runs alongside to record ball motion.

---

## Checklist

- [ ] Builds with no errors, `bin/fictrac` and `bin/configGui` present
- [ ] Camera opens: `Basler camera initialised (1280x1024 @ 59.952 fps)`
- [ ] Red circle in `fictrac-configImg.png` sits on the ball
- [ ] Ball motion produces coherent numbers

Next: [03 — MATLAB R2014b](03-matlab.md)

---

*JC Lab, University of Groningen. Problems with this guide? Contact Vasilis Kapantaidakis — vaskapant@gmail.com or v.kapantaidakis@student.rug.nl*
