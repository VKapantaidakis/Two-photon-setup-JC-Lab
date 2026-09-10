# Two-photon ViRMEn scripts

This folder contains the final ViRMEn worlds and MATLAB scripts used for the two-photon visual-stimulation workflow.

## Final scripts used in two-photon microscopy

The final two-photon calcium-imaging stimulation used separate black-background and white-background ViRMEn worlds/scripts:

| File | Role |
|---|---|
| `BlackChamber.m` | Final black-background stimulation script. Runs for a fixed duration, logs Arduino TTL frame timing, and ends automatically. |
| `BlackChamber.mat` | Saved ViRMEn world for the black-background condition. Upload manually. |
| `whi.m` | Final white-background stimulation script. |
| `whi.mat` | Saved ViRMEn world for the white-background condition. Upload manually. |

## Protocol used in the thesis

The two-photon visual stimulus consisted of black-background and white-background visual stimulation.

- stimulus control: MATLAB and ViRMEn
- synchronization: Arduino--DAQ interface
- Arduino serial format: `FRAME,<frame number>`
- black condition default duration in `BlackChamber.m`: 5 min, unless overwritten by `protocol.blackDurationSec` in the MATLAB base workspace

Earlier notes refer to 1500 imaging frames per script followed by a 300-frame break. Keep the final values in the master script/protocol file and update this README if the final timing differs.

## Supporting and development files

These files may also be kept in this folder as supporting or earlier ViRMEn worlds/scripts:

- `Behaviorarena.m`
- `Behaviorarena.mat`
- `cilinder.m`
- `cilinder.mat`
- `MasterSwitchByDAQ600.m`
- `MasterSwitchByDAQ600_LoadedWorlds.m`
- `WhiteChamber.m`
- `WhiteChamber.mat`
- `WhiteChamberDots.m`
- `WhiteChamberDots.mat`

## File roles

- `BlackChamber.m` / `BlackChamber.mat`: final black-background two-photon condition.
- `whi.m` / `whi.mat`: final white-background two-photon condition.
- `MasterSwitchByDAQ600_LoadedWorlds.m`: master workflow for loading saved ViRMEn worlds and switching conditions.
- `.mat` files: saved ViRMEn world files.
- `Behaviorarena` and `cilinder` files: arena/world geometry or setup files used during development and stimulation.

## Important local settings

Before running these scripts on another computer, update local paths, serial-port names, saved `.mat` locations, and DAQ/Arduino trigger settings.

## Important note

Do not commit raw two-photon imaging data here. Store raw imaging data separately unless a data-release plan is approved.
