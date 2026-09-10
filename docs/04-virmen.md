# 04 — ViRMEn compiled for Linux

[ViRMEn](https://pni.princeton.edu/pni-software-tools/virmen) (Virtual Reality MATLAB Engine) generates the virtual world. The distribution ships C/C++ code precompiled for **Windows and macOS only** — there are no Linux binaries, and the build script has no Linux branch. Two patches fix that.

These reproduce, on the public code, the same fixes other labs keep in private forks ("make compilation work on linux" and "enforce C99").

Prerequisite: [03 — MATLAB](03-matlab.md).

---

## 1. Download and lay out the source

The Tank Lab GitHub repo is an **archive of dated release zips**, not the code itself:

```bash
cd ~/Downloads
wget -O ViRMEn.zip https://github.com/Tank-Lab/ViRMEn/archive/refs/heads/master.zip
unzip ViRMEn.zip -d ~/Documents/MATLAB/
ls ~/Documents/MATLAB/ViRMEn-main/Software/       # 2013-02-27 ... 2016-02-12
```

Extract the newest release and flatten it so `virmen.m` sits at the top level:

```bash
mkdir -p ~/Documents/MATLAB/virmen
unzip "$HOME/Documents/MATLAB/ViRMEn-main/Software/ViRMEn 2016-02-12.zip" \
      -d "$HOME/Documents/MATLAB/virmen/"
mv "$HOME/Documents/MATLAB/virmen/ViRMEn 2016-02-12/"* "$HOME/Documents/MATLAB/virmen/"
rmdir "$HOME/Documents/MATLAB/virmen/ViRMEn 2016-02-12"
ls ~/Documents/MATLAB/virmen/          # virmen.m must be here
```

> Quote paths containing `$HOME` rather than using `~` inside quotes — `"~/..."` does not expand and `unzip` will not find the file.

Then clean up the archive you no longer need:

```bash
rm -rf ~/Documents/MATLAB/ViRMEn-main ~/Downloads/ViRMEn.zip
```

## 2. Extra libraries

```bash
sudo apt-get install -y libglfw3 libglfw3-dev libgl1-mesa-dev libglu1-mesa-dev
```

Confirm the **linker symlinks** exist (not just the versioned runtime files):

```bash
ls -l /usr/lib/x86_64-linux-gnu/libglfw.so /usr/lib/x86_64-linux-gnu/libGL.so
```

## 3. Patch 1 — `bin/virmenMake.m`

Two problems: no Linux branch for the GLFW files, and C files compiled in C90 mode, which rejects `//` comments.

**3a. Force C99 on the non-GLFW compile.** In the `if ~isGLFW` branch:

```diff
-            mex(f);
+            mex('CFLAGS="$CFLAGS -std=c99 -fPIC"',f);
```

Without this you get:

```
error: C++ style comments are not allowed in ISO C90
```

**3b. Add a Linux branch.** `computer` returns `GLNXA64` on Linux, which falls through to an error. Insert a case after the `MACI64` one:

```diff
                     elseif strcmp(computer, 'MACI64')
                         mex('-L./GLFW','-v','-lglfw.3', ... ,'-outdir',currentDir,f);
+                    elseif strcmp(computer, 'GLNXA64')
+                        mex('-lglfw','-lGL','CFLAGS="$CFLAGS -std=c99 -fPIC"','-outdir',currentDir,f);
                     else
```

Without it:

```
Error using virmenMake>compilationFunction
Unsupported compilation architecture.
```

See `patches/virmen-virmenMake.patch`.

## 4. Patch 2 — `bin/gui/updateFigures.m`

The GUI builds its movement and transformation menus from platform-specific mex files, with cases for `PCWIN`, `PCWIN64` and `MACI64` — but **not** `GLNXA64`. On Linux the list comes back empty and the GUI crashes on startup:

```
Index exceeds matrix dimensions.
Error in updateFigures (line 494)
        handles.exper.transformationFunction = str2func(str{1});
```

Add a Linux case in **both** blocks — movements (~line 455) and transformations (~line 480):

```diff
         case 'MACI64'
             mf = [mf; dir([path filesep '..' filesep '..' filesep 'movements' filesep '*.mexmaci64'])];
+        case 'GLNXA64'
+            mf = [mf; dir([path filesep '..' filesep '..' filesep 'movements' filesep '*.mexa64'])];
     end
```

```diff
         case 'MACI64'
             mf = [mf; dir([path filesep '..' filesep '..' filesep 'transformations' filesep '*.mexmaci64'])];
+        case 'GLNXA64'
+            mf = [mf; dir([path filesep '..' filesep '..' filesep 'transformations' filesep '*.mexa64'])];
     end
```

Verify both landed:

```bash
grep -c "GLNXA64" ~/Documents/MATLAB/virmen/bin/gui/updateFigures.m    # expect 2
```

See `patches/virmen-updateFigures.patch`.

> These are the only two places in the ViRMEn tree that branch on platform for mex files. Confirm with:
> ```bash
> grep -rn "mexmaci64\|MACI64" ~/Documents/MATLAB/virmen/bin/ | grep -v "_builtin"
> ```
> Everything else that looks Windows-specific (`ispc` guards on GUIDE background colours, `\t` in `textscan`) is harmless on Linux.

## 5. Set the MATLAB path

```bash
cat > ~/Documents/MATLAB/startup.m <<'EOF'
addpath(genpath(fullfile(getenv('HOME'),'Documents','MATLAB','virmen')))
cd(fullfile(getenv('HOME'),'Documents','MATLAB','virmen','experiments'))
EOF
```

## 6. Compile

Launch MATLAB, then in the Command Window:

```matlab
mex -setup
cd(fullfile(getenv('HOME'),'Documents','MATLAB','virmen','bin'))
virmenMake
virmenMake        % run twice - the second pass picks up files the first generated
```

Every file should report `Successfully compiled` and produce a `.mexa64`. Pointer-type warnings from gcc 13 (`assignment to 'mwSize *' from incompatible pointer type`) are **harmless** — that is 2016 code meeting a 2024 compiler.

Confirm the Linux binaries exist:

```bash
ls ~/Documents/MATLAB/virmen/transformations/*.mexa64
ls ~/Documents/MATLAB/virmen/bin/engine/*.mexa64
```

After editing any `.m`, MATLAB caches the old version — run `clear functions; rehash` or restart before testing.

## 7. Verify

From the **DESIGN** launcher (software GL — see [03](03-matlab.md)):

```matlab
virmen
```

The GUI should open with the design panels rendering. Open `experiments/tennisCourt.mat` and press **Run** — a 3D window appears and responds to movement.

> **Blank design panels?** MATLAB is not in software-GL mode. Check `opengl info` → `Software` should be `'true'`. If it says `false`, you launched from the EXPERIMENT icon.
>
> **Segfault on Run?** You are in software GL. Experiments must be run from the **EXPERIMENT** launcher. See [03](03-matlab.md) — this is the central quirk of the whole setup.

If a dirty relaunch after a crash throws:

```
Error using guidata (line 87)
H must be the handle to a figure or figure descendent.
```

clear the stale state:

```matlab
close all force
clear global guifig
clear all
clear functions
rehash
virmen
```

---

## Checklist

- [ ] `virmen.m` at the top level of `~/Documents/MATLAB/virmen/`
- [ ] Both patches applied (`grep -c GLNXA64 .../updateFigures.m` → 2)
- [ ] `virmenMake` completes twice with no errors
- [ ] `.mexa64` files present in `transformations/` and `bin/engine/`
- [ ] tennisCourt runs from the EXPERIMENT launcher

Next: [05 — Arduino / DAQ](05-arduino-daq.md)

---

*JC Lab, University of Groningen. Problems with this guide? Contact Vasilis Kapantaidakis — vaskapant@gmail.com or v.kapantaidakis@student.rug.nl*
