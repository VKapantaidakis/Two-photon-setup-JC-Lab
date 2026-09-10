# setup/

Configuration files referenced by the docs.

| File | Install |
|---|---|
| `99-arduino-matlab.rules` | `sudo cp 99-arduino-matlab.rules /etc/udev/rules.d/` then `sudo udevadm control --reload-rules && sudo udevadm trigger` |
| `matlab-2p-experiment.desktop` | `cp *.desktop ~/.local/share/applications/` then `update-desktop-database ~/.local/share/applications` and **log out / back in** |
| `matlab-virmen-design.desktop` | as above |

The two launchers are deliberately separate — see [docs/03-matlab.md](../docs/03-matlab.md).
Running an experiment from the software-GL launcher segfaults MATLAB.
