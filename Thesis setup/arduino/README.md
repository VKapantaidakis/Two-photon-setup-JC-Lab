# Arduino synchronization

The Arduino Uno was used only for the two-photon calcium-imaging workflow, not for the freely moving behavioral experiment.

## Frame counter

File: `frame_counter/frame_counter.ino`

Logic:

- TTL input is connected to digital pin 2.
- Each rising edge triggers an interrupt.
- The frame counter is incremented for each detected pulse.
- Serial communication runs at 115200 baud.
- MATLAB receives frame messages in the format `FRAME,<frame number>`.

## Purpose in the two-photon workflow

The Arduino was used to count or relay TTL timing pulses so that MATLAB/ViRMEn stimulus timing could be aligned with two-photon calcium-imaging acquisition.

## Wiring

| Signal | Arduino connection | Purpose |
|---|---|---|
| Imaging/DAQ TTL output | Digital pin 2 | Frame or trigger counting |
| Ground | Arduino GND | Common reference |
| USB serial | USB port | MATLAB communication |
| DAQ/imaging trigger | Add final pin/channel | Two-photon stimulus triggering |

## Not used for behavioral experiment

The freely moving behavioral experiment was camera-based. The Arduino frame counter documented here was not part of that behavioral acquisition workflow.
