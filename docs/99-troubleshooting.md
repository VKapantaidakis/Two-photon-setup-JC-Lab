# 99 — Troubleshooting

Every error hit while building this rig, with its cause and fix. Search this page by the error text.

---

## Camera / FicTrac

### `Failed to open ... The device is controlled by another application. (0xE1018006)`

A GigE camera accepts **one controlling application at a time**. Pylon Viewer, an earlier `configGui` still sitting at "Hit ENTER to exit", or a previous `fictrac` is holding it.

```bash
pkill -f pylonviewer; pkill -f configGui; pkill -f fictrac
sleep 8
pgrep -a "pylonviewer|configGui|fictrac" || echo "camera free"
```

The `sleep 8` matters: after a client dies the camera keeps its control channel until the heartbeat expires, so an immediate retry fails identically. If it persists, power-cycle the camera.

### `The Wayland connection experienced a fatal error: Protocol error`

FicTrac's OpenCV/Qt GUI does not work under Wayland. Switch the session to **Xorg** — [00](00-user-setup.md). Check with `echo $XDG_SESSION_TYPE` (want `x11`).

### `QStandardPaths: runtime directory '/run/user/1000' is not owned by UID 0`

You ran a GUI application with `sudo`. GigE cameras need no root — drop it.

### Camera pings but video does not stream

**Jumbo frames.** The host MTU is 9000 but the link cannot carry it. Small packets (ping) pass, large ones (video) do not.

```bash
ping -M do -s 8972 -c 3 192.168.4.3     # 100% loss = jumbo broken
sudo ip link set <iface> mtu 1500
```

Pin it: `nmcli con mod "<connection-name>" 802-3-ethernet.mtu 1500`. Also check the camera's own **GevSCPSPacketSize** does not exceed the host MTU. [01](01-basler-camera.md)

### Camera not found at all

```bash
ip -br addr show <iface>              # link UP? host IP set?
ip neigh show | grep <subnet>         # a 00:30:53:* MAC = Basler
/opt/pylon/bin/ipconfigurator &       # finds cameras with a wrong IP
```

### `fatal error: pylon/usb/BaslerUsbInstantCameraArray.h: No such file or directory`

Modern Pylon removed the transport-specific headers. Apply the one-line patch in [02](02-fictrac.md).

### `E: Unable to locate package libavresample-dev`

Removed in FFmpeg 5 / Ubuntu 24.04. Do not install it; FicTrac builds without it.

### configGui prompts answer themselves

You typed ahead. Characters queue in stdin and later prompts consume them — you silently keep the sample's calibration. Answer **one prompt at a time**. Remember **y/n go to the terminal, ENTER/ESC go to the image window** (click it first). [02](02-fictrac.md)

### Ball circle fit looks wrong

Duplicate click points from dragging. Use single deliberate clicks, 6–8 spread around the edge. Check `fictrac-configImg.png` — the red circle must sit on the ball. To start clean:

```bash
sed -i '/^roi_/d; /^c2a_r/d; /^c2a_t/d' config.txt
```

### `Error! Recorder processing thread unable to set thread priority!`

Harmless. FicTrac asks for real-time scheduling priority and Linux declines.

---

## MATLAB

### `License Manager Error -9 — Your username does not match`

The activation is bound to a different OS login name. Fix in the MathWorks License Center: deactivate the computer, re-activate with **Operating System User Name** = your exact Linux username, download the new licence, reactivate locally. [03](03-matlab.md)

### `error while loading shared libraries: libncurses.so.5`

Not packaged in Ubuntu 24.04. Install the 22.04 `.deb`s. [03](03-matlab.md)

### Segfault at `glViewport` in `virmenOpenGLRoutines.mexa64`

```
Software OpenGL : 1
[0] .../sys/opengl/lib/glnxa64/libGL.so.1 ... glViewport
[1] .../virmen/bin/engine/virmenOpenGLRoutines.mexa64
```

MATLAB was launched with **`-softwareopengl`**. ViRMEn's GLFW engine needs hardware libGL. Run experiments from the **hardware-GL** launcher. [03](03-matlab.md)

### ViRMEn design panels are blank

The opposite case — you need `-softwareopengl` for the editor. Use the **DESIGN** launcher. `opengl info` → `Software` should read `'true'`.

### `Switching to software OpenGL rendering at runtime on unix is not supported`

Correct — it must be a launch flag on Linux, which is why there are two launchers.

### The desktop icon behaves differently from the terminal

GNOME caches `.desktop` files. After editing one, **log out and back in**.

### `Open failed: Port: /dev/ttyACM0 is not available. Available ports: /dev/ttyS4`

MATLAB R2014b on Linux only recognises `/dev/ttyS*`. Symlink it and add the udev rule. [05](05-arduino-daq.md)

### `/dev/ttyS101` disappeared after a reboot

`/dev` is rebuilt at boot. That is what the udev rule is for. [05](05-arduino-daq.md)

### `Error using guidata — H must be the handle to a figure or figure descendent`

Stale ViRMEn state after a crash: a leftover figure's resize callback fires against a dead `guifig`.

```matlab
close all force
clear global guifig
clear all
clear functions
rehash
```

If it persists, restart MATLAB — after a segfault the Java/graphics state can be corrupted beyond what `clear` fixes.

### `Function definitions are not permitted in this context`

R2014b **scripts** cannot contain local functions (that arrived in R2016b). Inline the helpers or convert the file to a function.

### `Undefined function 'serialport'`

R2019b+ API. R2014b uses legacy `serial()` / `fopen` / `fgetl` / `fread`. Same for `configureTerminator`, `readline`, `yyaxis`, `isgraphics`, `datetime(...,'ConvertFrom','posixtime')`.

### An edit to a `.m` file has no effect

MATLAB caches functions in memory. `clear functions; rehash` — or restart. Verify what is actually on disk with `grep`, and what MATLAB resolves with `which <name>`.

### `Reference to non-existent field 'lastArduinoFrame'`

An old copy of a phase file is on the path. Confirm the installed file is the current one and `clear functions`.

---

## ViRMEn build

### `Unsupported compilation architecture. See ViRMEn manual`

No `GLNXA64` branch in `virmenMake.m`. Add it. [04](04-virmen.md)

### `error: C++ style comments are not allowed in ISO C90`

The non-GLFW `mex(f)` call compiles in C90. Add `CFLAGS="$CFLAGS -std=c99 -fPIC"`. [04](04-virmen.md)

### `Index exceeds matrix dimensions` in `updateFigures` line ~494

The transformation list is empty because `updateFigures.m` has no `GLNXA64` case, so it never sees your `.mexa64` files. Add the case in **both** the movements and transformations blocks. [04](04-virmen.md)

```bash
grep -c "GLNXA64" ~/Documents/MATLAB/virmen/bin/gui/updateFigures.m    # expect 2
```

### `cannot find -lglfw` / `-lGL`

Missing dev packages — the linker needs the bare `.so` symlinks:

```bash
sudo apt-get install -y libglfw3-dev libgl1-mesa-dev libglu1-mesa-dev
ls -l /usr/lib/x86_64-linux-gnu/libglfw.so /usr/lib/x86_64-linux-gnu/libGL.so
```

### gcc pointer-type warnings during `virmenMake`

Harmless. 2016 code, 2024 compiler.

---

## Arduino

### Port greyed out in the IDE / `avrdude: ser_open(): can't open device`

Not in the `dialout` group, or not logged out and back in since being added. [00](00-user-setup.md)

### Sketch will not compile

Missing libraries. Install **RTClib** (Adafruit) and **DHT sensor library** (Adafruit) — accept **Install All** for the Unified Sensor dependency. [05](05-arduino-daq.md)

### Humidity always `nan`

Fixed in v6. The DHT22 needs 2 s between samples; earlier versions forced two reads back to back, so the second always failed. Use `daq_frame_logger_v6.ino`.

### MATLAB cannot open the port while the IDE is open

Close the Arduino IDE **Serial Monitor**. One program per port.

### Zero frames captured, but no error

The port opened; the DAQ is not triggering. Check the 2P is scanning and the BNC reaches **D2**.

### Dropped frames / sketch-missed non-zero

- `dropped` (sequence gaps) → serial link losing lines. Reduce `PRINT_EVERY`, lower the panel refresh, close other applications.
- `missed` (sketch counter) → triggers arriving faster than 115200 baud can carry them.

---

## Display

### VR window is not fullscreen

`FULLSCREEN_VR = false` in the master script config. Note that on a **single** display, fullscreen hides the live monitor panel — that is expected. [06](06-experiment-workflow.md)

### Projector mirrors the laptop

X sees one display. Extend it:

```bash
xrandr --listmonitors
xrandr --output <PROJECTOR> --auto --right-of <LAPTOP>
```

then `VR_MONITOR = 2`. [06](06-experiment-workflow.md)

### The live monitor panel vanishes when the VR window opens

Fullscreen covers it. Either run windowed, or use the projector as a second display and keep the panel on the laptop screen. The console output (`PRINT_EVERY`) is never hidden.

---

## General principles

1. **One program per device** — camera and serial port both.
2. **Wait ~8 s** after killing a camera client.
3. **`clear functions`** after editing MATLAB code.
4. **Log out and back in** after changing groups or `.desktop` files.
5. **Check the actual file on disk** (`grep`) rather than assuming an edit was saved.
6. **Test each layer alone** before combining — camera in Pylon Viewer, then FicTrac; Arduino in Serial Monitor, then MATLAB; ViRMEn with tennisCourt, then your world.

---

*JC Lab, University of Groningen. Problems with this guide? Contact Vasilis Kapantaidakis — vaskapant@gmail.com or v.kapantaidakis@student.rug.nl*
