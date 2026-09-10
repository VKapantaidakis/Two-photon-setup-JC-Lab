# 00 — User and OS setup

Baseline configuration of the Ubuntu machine before any rig software is installed. Everything below was done on **Ubuntu 24.04.4 LTS**.

Reference machine: `flylab-Dell-Pro-14-PC14250`, user `flylab`.

---

## 1. Check the OS

```bash
lsb_release -d
gcc --version | head -1
```

Expected on the reference machine:

```
Description:	Ubuntu 24.04.4 LTS
gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0
```

gcc 13 matters later — ViRMEn's 2016-era C code needs a compiler flag to build against it ([04](04-virmen.md)).

## 2. Use an Xorg session, not Wayland

**This is not optional.** FicTrac's GUI is built on older OpenCV/Qt, which fails under Wayland:

```
The Wayland connection experienced a fatal error: Protocol error
```

Check which you are on:

```bash
echo $XDG_SESSION_TYPE
```

If it says `wayland`:

1. Log out.
2. On the login screen, click your username.
3. Click the **gear icon** at the bottom-right of the password field.
4. Select **"Ubuntu on Xorg"**.
5. Log in.

The choice persists for future logins. Re-check:

```bash
echo $XDG_SESSION_TYPE     # want: x11
```

Xorg suits the whole stack anyway — MATLAB R2014b, ViRMEn's GLFW rendering and FicTrac's OpenCV windows are all X11-era software.

## 3. Serial port access — the `dialout` group

The Arduino appears as a serial device owned by group `dialout`. Without membership, both the Arduino IDE and MATLAB fail to open it.

```bash
sudo usermod -aG dialout $USER
```

**Then log out and log back in** — group membership only applies to a new login session. Verify:

```bash
groups | tr ' ' '\n' | grep -x dialout && echo "OK: in dialout"
```

## 4. Folder layout

One real location per thing, no duplicates. MATLAB gets confused by two copies of a function on its path, so this matters.

```
~/Documents/MATLAB/virmen/              ViRMEn install (compiled .mexa64 live here)
~/Documents/MATLAB/virmen/experiments/  experiment .m and .mat files
~/Documents/MATLAB/arduino/             .ino sketch
~/Documents/MATLAB/ExperimentData/      session output folders (created per run)
~/Documents/fictrac-experiments/        FicTrac config + logs
~/fictrac/                              FicTrac source and build
/opt/pylon/                             Basler Pylon SDK
```

Create them:

```bash
mkdir -p ~/Documents/MATLAB/virmen/experiments
mkdir -p ~/Documents/MATLAB/arduino
mkdir -p ~/Documents/MATLAB/ExperimentData
mkdir -p ~/Documents/fictrac-experiments
```

## 5. Desktop launch pad (optional but convenient)

A single Desktop folder of **symlinks** into the real locations. Symlinks, not copies — there is still only one of each file, so nothing shadows anything.

```bash
mkdir -p ~/Desktop/2P-Rig
ln -sfn ~/Documents/MATLAB/virmen/experiments ~/Desktop/2P-Rig/experiments
ln -sfn ~/Documents/MATLAB/virmen             ~/Desktop/2P-Rig/virmen
ln -sfn ~/Documents/MATLAB/arduino            ~/Desktop/2P-Rig/arduino
ln -sfn ~/Documents/MATLAB/ExperimentData     ~/Desktop/2P-Rig/data
ln -sfn ~/fictrac                             ~/Desktop/2P-Rig/fictrac
ls -l ~/Desktop/2P-Rig/
```

**Do not copy ViRMEn to the Desktop.** Its compiled `.mexa64` files and the patches in [04](04-virmen.md) live at the real path; a second copy will be edited by mistake while MATLAB runs the other.

## 6. Useful packages

```bash
sudo apt-get update
sudo apt-get install -y git build-essential cmake pkg-config \
  ethtool network-manager net-tools
```

`ethtool` and `network-manager` are required by Basler's GigE configurator ([01](01-basler-camera.md)); `net-tools` is only for convenience (`arp`), since Ubuntu 24.04 ships `ip` instead.

---

## Checklist before moving on

- [ ] `echo $XDG_SESSION_TYPE` → `x11`
- [ ] `groups | grep dialout` → present
- [ ] Folder layout created
- [ ] Machine rebooted at least once since the `usermod`

Next: [01 — Basler camera](01-basler-camera.md)

---

*JC Lab, University of Groningen. Problems with this guide? Contact Vasilis Kapantaidakis — vaskapant@gmail.com or v.kapantaidakis@student.rug.nl*
