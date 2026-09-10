# 03 — MATLAB R2014b on Ubuntu 24.04

R2014b is a 2014 release running on a 2024 OS. It works, but needs four fixes: missing ncurses 5, a licence username mismatch, a library preload, and — the important one — **two separate launchers** because the OpenGL requirements of ViRMEn's editor and its runtime are mutually exclusive.

R2014b is required by ViRMEn ([04](04-virmen.md)); newer MATLAB releases break its GUIDE-era GUI.

---

## 1. Install from the ISO

```bash
cd ~/Downloads
mkdir -p matlab
sudo mount -o loop R2014b_glnxa64.iso ~/Downloads/matlab
cd matlab
sudo ./install
```

In the installer: choose **"Use a File Installation Key"**, enter your key, install to `/usr/local/MATLAB/R2014b`, then activate manually offline against your `license.lic`.

> The File Installation Key and the licence file are different things. The key unlocks *installation*; the licence file handles *activation*. Both come from the same page in the MathWorks License Center.

## 2. ncurses 5 (not packaged in 24.04)

R2014b links against `libncurses.so.5`, which Ubuntu 24.04 no longer provides:

```
error while loading shared libraries: libncurses.so.5: cannot open shared object file
```

Get the libraries from the Ubuntu 22.04 archive:

```bash
cd ~/Downloads
wget http://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.2_amd64.deb
wget http://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncurses5_6.3-2ubuntu0.2_amd64.deb
wget http://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncursesw5_6.3-2ubuntu0.2_amd64.deb

sudo apt-get install -y ./libtinfo5_6.3-2ubuntu0.2_amd64.deb \
                        ./libncurses5_6.3-2ubuntu0.2_amd64.deb \
                        ./libncursesw5_6.3-2ubuntu0.2_amd64.deb
```

The point version drifts. If those 404, list the directory and take the current `6.3-*` files:
http://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/

Verify:

```bash
find /lib /usr/lib -name "libncurses.so.5*"
```

## 3. OpenGL libraries (needed by ViRMEn later)

```bash
sudo apt-get install -y libglfw3 libglfw3-dev libgl1-mesa-dev libglu1-mesa-dev
```

These provide the `libglfw.so` and `libGL.so` **linker symlinks** that ViRMEn's mex build needs. The runtime `.so.N` files alone are not enough.

## 4. License Manager Error -9 (username mismatch)

```
License checkout failed. License Manager Error -9
Your username does not match the username in the license file.
```

A Designated Computer licence is bound to a specific **operating-system login name**. If the activation was created with a different name than your Linux user, MATLAB refuses to start — and no amount of local reactivation fixes it, because the binding is set server-side.

Fix in the MathWorks **License Center**:

1. Open the licence → **Install and Activate** tab.
2. Find the activation for this computer (matched by host ID / MAC).
3. **Deactivate** it.
4. **Activate a Computer** again, setting **Operating System User Name** to your exact Linux username (case-sensitive — `whoami`).
5. Download the new licence file.
6. Reactivate locally:

```bash
/usr/local/MATLAB/R2014b/bin/activate_matlab.sh
```

Choose "Activate manually without the Internet" and point it at the new file.

> **Note which NIC the licence is locked to.** On the reference machine the host ID is the **WiFi** adapter's MAC. Disabling WiFi would break activation. Check with `ip -br link` against the `HOSTID` in the licence file.

## 5. The two launchers — read this carefully

ViRMEn needs **opposite** OpenGL configurations for editing and for running:

| Launch mode | ViRMEn design panels | Running an experiment |
|---|---|---|
| `-softwareopengl` | ✅ render correctly | ❌ **segfault** |
| no flag (hardware GL) | ❌ blank | ✅ works |

The crash with `-softwareopengl` is a hard segmentation fault, and the dump names the cause:

```
Segmentation violation detected
Software OpenGL : 1
[0] /usr/local/MATLAB/R2014b/sys/opengl/lib/glnxa64/libGL.so.1 ... glViewport
[1] .../virmen/bin/engine/virmenOpenGLRoutines.mexa64 ... mexFunction
```

`-softwareopengl` makes MATLAB load its own bundled software libGL. ViRMEn's 3D engine goes through GLFW and needs the real hardware libGL to have a valid context; handed the software one, it dies inside `glViewport`.

On Linux this **cannot be switched at runtime** — `opengl('software')` errors with *"Switching to software OpenGL rendering at runtime on unix is not supported"*. It has to be a launch flag, hence two launchers.

Create both:

```bash
# EXPERIMENT launcher - hardware GL, no flag
cat > ~/.local/share/applications/matlab-2p-experiment.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=MATLAB 2P EXPERIMENT (hardware GL)
Comment=Run experiments - ViRMEn 3D rendering works, design panels blank
Exec=env LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libncurses.so.5:/usr/lib/x86_64-linux-gnu/libstdc++.so.6:/usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/local/MATLAB/R2014b/bin/matlab -desktop
Icon=/usr/local/MATLAB/R2014b/toolbox/shared/hwconnectinstaller/resources/MatlabIcon.png
Categories=Development;Science;
Terminal=false
StartupNotify=true
EOF

# DESIGN launcher - software GL
cat > ~/.local/share/applications/matlab-virmen-design.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=MATLAB ViRMEn DESIGN (software GL)
Comment=Build/edit worlds - design panels render, DO NOT run experiments
Exec=env LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libncurses.so.5:/usr/lib/x86_64-linux-gnu/libstdc++.so.6:/usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/local/MATLAB/R2014b/bin/matlab -softwareopengl -desktop
Icon=/usr/local/MATLAB/R2014b/toolbox/shared/hwconnectinstaller/resources/MatlabIcon.png
Categories=Development;Science;
Terminal=false
StartupNotify=true
EOF

update-desktop-database ~/.local/share/applications
```

Both files are also in `setup/` in this repo.

> **GNOME caches `.desktop` files.** After creating or editing them, **log out and back in** — otherwise the icon keeps launching the old command line. This is a real trap: the terminal launch works while the icon silently does something else.

Check which mode a running MATLAB is in:

```matlab
opengl info      % 'Software' field: 'true' or 'false'
```

### The `LD_PRELOAD` line

Both launchers force MATLAB to use the **system** libraries rather than its own outdated bundled copies:

```
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libncurses.so.5:/usr/lib/x86_64-linux-gnu/libstdc++.so.6:/usr/lib/x86_64-linux-gnu/libfreetype.so.6
```

Without it you get `CXXABI_1.3.8 not found` warnings from `libGLU`, and font/terminal problems.

For terminal use, the same as a shell alias:

```bash
echo "alias matlab='LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libncurses.so.5:/usr/lib/x86_64-linux-gnu/libstdc++.so.6:/usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/local/MATLAB/R2014b/bin/matlab'" >> ~/.bashrc
source ~/.bashrc
```

## 6. `startup.m`

```bash
cat > ~/Documents/MATLAB/startup.m <<'EOF'
addpath(genpath(fullfile(getenv('HOME'),'Documents','MATLAB','virmen')))
cd(fullfile(getenv('HOME'),'Documents','MATLAB','virmen','experiments'))
EOF
```

Use `fullfile(getenv('HOME'),...)` rather than `~` — MATLAB's `addpath` does not reliably expand `~`.

## 7. Two R2014b language limits worth knowing

Both bit us while porting code:

- **Scripts cannot define local functions.** That arrived in R2016b. Function *files* can. A script with helper functions at the bottom fails with *"Function definitions are not permitted in this context."* Inline the helpers, or make the file a function.
- **`serialport()` does not exist** — nor `configureTerminator`, `readline`. Use the legacy `serial()` / `fopen` / `fgetl` / `fread` API. See [05](05-arduino-daq.md).

Also: **MATLAB caches functions in memory.** After editing any `.m`, run `clear functions; rehash` or restart, otherwise you keep running the old version. This cost us time twice.

---

## Checklist

- [ ] MATLAB launches, licence activated (no Error -9)
- [ ] `libncurses.so.5` present
- [ ] Both launchers created, session restarted so GNOME sees them
- [ ] `opengl info` reports `Software: 'false'` from the EXPERIMENT launcher
- [ ] `startup.m` in place

Next: [04 — ViRMEn](04-virmen.md)

---

*JC Lab, University of Groningen. Problems with this guide? Contact Vasilis Kapantaidakis — vaskapant@gmail.com or v.kapantaidakis@student.rug.nl*
