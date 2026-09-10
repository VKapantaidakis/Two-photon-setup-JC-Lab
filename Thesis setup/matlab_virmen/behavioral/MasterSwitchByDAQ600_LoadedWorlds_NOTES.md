# MasterSwitchByDAQ600_LoadedWorlds

The master script controls the behavioral ViRMEn workflow.

## Function

It performs the following steps:

1. Opens MATLAB and ViRMEn.
2. Adds the ViRMEn root directory and experiment directory to the MATLAB path.
3. Opens a shared Arduino serial connection.
4. Loads the saved WhiteChamber ViRMEn experiment.
5. Runs WhiteChamber until it terminates after 600 Arduino TTL pulses.
6. Checks that WhiteChamber ended by frame threshold.
7. Loads the saved WhiteChamberDots ViRMEn experiment.
8. Runs WhiteChamberDots until it terminates after 600 Arduino TTL pulses.
9. Saves timing information to the MATLAB base workspace.

## Local settings to update

The original script contained local computer paths and serial-port settings. Before reuse, update:

- ViRMEn root directory
- experiments directory
- serial port name
- baud rate, normally 115200
- saved WhiteChamber.mat path
- saved WhiteChamberDots.mat path

## Required companion files

- WhiteChamber.m
- WhiteChamberDots.m
- WhiteChamber.mat
- WhiteChamberDots.mat
- Arduino frame counter sketch

The full original script can be added here after checking local paths and personal computer identifiers.
