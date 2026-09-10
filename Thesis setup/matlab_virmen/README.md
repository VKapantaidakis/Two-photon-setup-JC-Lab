# MATLAB and ViRMEn files

Visual stimuli were generated and controlled using MATLAB 2018a and ViRMEn.

ViRMEn source: Tank-Lab/ViRMEn.

## Two-photon scripts

`twophoton/` contains the ViRMEn worlds and MATLAB scripts used for the two-photon visual-stimulation workflow.

Uploaded files that belong in `twophoton/`:

- `Behaviorarena.m`
- `Behaviorarena.mat`
- `cilinder.m`
- `cilinder.mat`
- `MasterSwitchByDAQ600.m`
- `MasterSwitchByDAQ600_LoadedWorlds.m`
- `whi.m`
- `whi.mat`
- `WhiteChamber.m`
- `WhiteChamber.mat`
- `WhiteChamberDots.m`
- `WhiteChamberDots.mat`

The final two-photon protocol used black and white visual stimulation. Each stimulus script lasted 1500 imaging frames followed by a 300-frame break.

## Behavioral scripts

Use `behavioral/` only for scripts that were specifically used for freely moving behavioral testing outside the two-photon setup.

## Important local settings

Before running on another computer, update local settings in the master scripts:

- ViRMEn root directory
- experiment directory
- serial port name
- saved ViRMEn `.mat` experiment file locations
- DAQ or Arduino trigger channel, if used

## Notes

Do not commit raw two-photon imaging data or behavioral videos here. Store raw data separately unless a data-release plan is approved.
