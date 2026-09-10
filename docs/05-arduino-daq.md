# 05 — Arduino / DAQ frame logger

An Arduino Uno timestamps every two-photon frame trigger and streams the record to MATLAB, so imaging frames and behaviour can be aligned offline. It also logs two analog channels, temperature/humidity, and drives the IR illuminator.

Sketch: [`arduino/daq_frame_logger_v6/daq_frame_logger_v6.ino`](../arduino/daq_frame_logger_v6/daq_frame_logger_v6.ino)

---

## 1. Wiring

| Signal | Pin | Notes |
|---|---|---|
| DAQ frame trigger | **D2** (INT0) | BNC centre; shield → Arduino GND. Use `INPUT_PULLUP` if the DAQ output is open-collector |
| IR LED array gate | **D5** (PWM) | to WPM411 / IRF520 MOSFET `SIG`; V− is the switching leg |
| DHT22 data | **D7** | 10 kΩ pull-up to 5 V if using a bare 4-pin sensor |
| DS3231 RTC | **A4** SDA / **A5** SCL | I²C |
| DAQ analog in | **A0**, **A1** | 0–5 V, 10-bit |

## 2. Libraries

Arduino IDE → **Tools → Manage Libraries** (Ctrl+Shift+I), install:

1. **RTClib** by Adafruit
2. **DHT sensor library** by Adafruit — when prompted *"Install all dependencies?"* click **Install All** (it needs **Adafruit Unified Sensor**; the sketch will not compile without it)

`Wire` ships with the IDE.

Set **Tools → Board → Arduino Uno** and **Tools → Port → /dev/ttyACM0**.

> **Port greyed out, or `avrdude: ser_open(): can't open device`?** You are not in the `dialout` group, or you have not logged out and back in since being added. See [00](00-user-setup.md).

## 3. Upload and verify

Upload, then open **Tools → Serial Monitor at 115200 baud**. Expect a header and a heartbeat line once per second:

```
#fmt,seq,epoch_s,ms,micros,a0,a1,tempC,rh,missed
#pins,trig=D2,gate=D5,dht=D7,i2c=A4/A5,analog=A0/A1
#rtc,ok
#stat,frames=0,rate=0.0Hz,missed=0,dhtOk=1,dhtFail=0,T=23.4,RH=41.2,age=120ms,led=255,stream=0
```

**Close the Serial Monitor before using MATLAB.** One program per serial port.

## 4. Serial protocol

Single-character commands, 115200 baud:

| Cmd | Action |
|---|---|
| `S` | start streaming data lines |
| `X` | stop streaming |
| `Z` | zero the frame counter |
| `R` | print statistics now |
| `1` | LEDs full on |
| `0` | LEDs off |
| `B<n>` | LED brightness 0–255 (e.g. `B128`) |
| `T` | DHT self-test (5 reads, interrupt detached) |
| `H` | toggle the 1 Hz heartbeat |
| `?` | print the header block |

One data line per trigger:

```
D,seq,epoch_s,ms,micros,a0,a1,tempC,rh,missed
```

| Field | Meaning |
|---|---|
| `seq` | frame counter since last `Z` — gaps mean frames lost in transit |
| `epoch_s`, `ms` | absolute time from the DS3231 |
| `micros` | Arduino microsecond clock; the precise relative timebase |
| `a0`, `a1` | analog channels, raw 0–1023 |
| `tempC`, `rh` | DHT22 (`nan` until the first good read) |
| `missed` | triggers the sketch itself could not send in time |

Lines beginning `#` are status, not data.

> **v6 fixes a DHT22 bug.** The sensor needs 2 s between samples; v4/v5 forced both a temperature and a humidity read back to back, so humidity always returned NaN. v6 forces one read and takes the companion value from the same cached packet.

## 5. Make the port visible to MATLAB

**MATLAB R2014b on Linux only recognises ports named `/dev/ttyS*`.** Your Arduino on `/dev/ttyACM0` is invisible:

```
Open failed: Port: /dev/ttyACM0 is not available. Available ports: /dev/ttyS4.
```

Symlink it into a name MATLAB accepts:

```bash
sudo ln -sf /dev/ttyACM0 /dev/ttyS101
ls -l /dev/ttyS101
```

`/dev` is rebuilt at boot, so make it permanent with a udev rule (also in `setup/99-arduino-matlab.rules`):

```bash
sudo bash -c 'echo "KERNEL==\"ttyACM[0-9]*\", SYMLINK+=\"ttyS101\"" > /etc/udev/rules.d/99-arduino-matlab.rules'
sudo udevadm control --reload-rules
sudo udevadm trigger
ls -l /dev/ttyS101
```

Now the symlink is recreated automatically whenever an Arduino is plugged in.

## 6. `arduinoFrameLog.m` — the single reader

[`matlab/arduinoFrameLog.m`](../matlab/arduinoFrameLog.m) is the **only** code permitted to open the serial port.

**Why this matters:** a serial line can be read exactly once. If both a logger and the experiment code read the port, they steal lines from each other and both get corrupted data. So `arduinoFrameLog` owns the port and republishes the current frame number to the base-workspace variable `latestArduinoFrame`; everything else reads that variable.

It reads with `fread()` on exactly the bytes available and reassembles lines itself, rather than `fgetl()`, which blocks the ViRMEn render loop when a partial line is in the buffer.

| Command | Action |
|---|---|
| `arduinoFrameLog('init', port, baud)` | open and register the port |
| `arduinoFrameLog('attach', s)` | adopt an existing serial object |
| `arduinoFrameLog('start' / 'stop' / 'zero')` | sketch control |
| `arduinoFrameLog('ledson' / 'ledsoff')` | illuminator |
| `arduinoFrameLog('waitfirst')` | block until the first frame → `[frame, clock]` |
| `arduinoFrameLog('phase', name)` | tag subsequent frames with an experiment phase |
| `n = arduinoFrameLog('poll')` | drain the buffer (non-blocking), returns new frame count |
| `arduinoFrameLog('monitor', N)` | open the live panel, refresh every N frames |
| `arduinoFrameLog('verbose', N)` | console line every N frames (0 = off) |
| `T = arduinoFrameLog('table')` | everything captured so far |
| `arduinoFrameLog('save', dir, tag)` | write CSVs (all frames, per phase, and a clock-sync record) |
| `arduinoFrameLog('stats')` | print a summary |
| `arduinoFrameLog('close')` | stop, close, reset |

Uses the legacy `serial()` API throughout — R2014b has no `serialport()`.

## 7. Test the chain, no ViRMEn

Standalone monitor with live plots ([`matlab/daq_frame_monitor_v2.m`](../matlab/daq_frame_monitor_v2.m)) — set `PORT` at the top, then:

```matlab
clear all
instrreset
daq_frame_monitor_v2
```

Three panels appear: analog channels, temp/humidity, frame timing. **Close the figure to stop** — it then writes a CSV and prints a summary.

`PLOT_EVERY = 10` throttles the *graphics*, not the capture: every frame is still read and stored. Redrawing at 60 Hz would stall the read loop and cause genuine drops. For per-frame visibility use `PRINT_EVERY = 1` (text is far cheaper than graphics).

Or exercise `arduinoFrameLog` directly:

```matlab
instrreset
clear functions
arduinoFrameLog('init','/dev/ttyS101',115200);
arduinoFrameLog('zero'); arduinoFrameLog('start');
arduinoFrameLog('verbose', 1);      % one console line per frame
arduinoFrameLog('monitor', 5);      % live panel
t0 = tic; while toc(t0) < 20, arduinoFrameLog('poll'); pause(0.02); end
arduinoFrameLog('stats');
arduinoFrameLog('close');
```

> **`daq_frame_monitor_v2` and the experiment script cannot run at the same time** — they would both open the port. During experiments use the built-in monitor and console output instead ([06](06-experiment-workflow.md)).

Zero frames but no error means the port opened fine and the DAQ simply is not triggering — check the 2P is scanning and the BNC reaches D2.

---

## Checklist

- [ ] Sketch compiles and uploads; Serial Monitor shows `#fmt` and `#stat` lines
- [ ] Serial Monitor **closed**
- [ ] `/dev/ttyS101` exists, udev rule installed
- [ ] `daq_frame_monitor_v2` captures frames with `dropped 0`

Next: [06 — Experiment workflow](06-experiment-workflow.md)

---

*JC Lab, University of Groningen. Problems with this guide? Contact Vasilis Kapantaidakis — vaskapant@gmail.com or v.kapantaidakis@student.rug.nl*
