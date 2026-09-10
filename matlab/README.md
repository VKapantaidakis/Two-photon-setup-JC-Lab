# matlab/

Install these into `~/Documents/MATLAB/virmen/experiments/`.

| File | Role |
|---|---|
| `MasterSwitchByDAQ_WhiteBack_BlackChamber.m` | main experiment script (WhiteBack -> BlackChamber) |
| `WhiteBack.m` / `BlackChamber.m` | phase logic; end after `vr.frameThreshold` frames |
| `WhiteBack.mat` / `BlackChamber.mat` | ViRMEn visual worlds |
| `arduinoFrameLog.m` | the single serial reader; logging, live panel, CSV export |
| `plotSession.m` | post-hoc plots + per-phase summary |
| `daq_frame_monitor_v2.m` | standalone DAQ tester (do NOT run alongside the master script) |

All are MATLAB **R2014b** compatible: legacy `serial()` API, no `serialport`,
no `datetime`, no `yyaxis`, and no local functions inside script files.

See [docs/06-experiment-workflow.md](../docs/06-experiment-workflow.md).
