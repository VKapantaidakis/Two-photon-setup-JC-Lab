# 01 — Basler GigE camera (Pylon SDK)

Getting a **Basler acA1300-60gm** GigE camera streaming on Ubuntu 24.04.

Pylon is Basler's SDK — the equivalent of Spinnaker for FLIR cameras. If you are adapting a Spinnaker-based protocol, note that **none of the Spinnaker workarounds apply**: no spack, no ffmpeg 4, no `usbfs_memory` service (that is USB3-only), no `flirimaging` group.

---

## 1. Install the Pylon SDK

Download from the [Basler website](https://www.baslerweb.com/en/software/pylon/) (free account required). Install to **`/opt/pylon`** — the FicTrac build in [02](02-fictrac.md) expects that path.

```bash
# .deb package (installs to /opt/pylon by default)
sudo apt install ./pylon_*_amd64.deb

# or from the tarball
cd ~/Downloads
tar -xzf pylon_*_x86_64_setup.tar.gz
sudo mkdir -p /opt/pylon
sudo tar -C /opt/pylon -xzf pylon-*.tar.gz
```

Load the environment (add to `~/.bashrc` so it persists):

```bash
source /opt/pylon/bin/pylon-setup-env.sh /opt/pylon
echo 'source /opt/pylon/bin/pylon-setup-env.sh /opt/pylon' >> ~/.bashrc
echo $PYLON_ROOT          # expect: /opt/pylon
```

Verify the C++ SDK and the GigE transport layer are present — FicTrac links against these:

```bash
ls /opt/pylon/include/pylon/PylonBase.h
ls /opt/pylon/lib | grep libpylon_TL_gige
```

If Pylon Viewer later fails with an `xcb` plugin error, install the Qt runtime pieces:

```bash
sudo apt-get install -y libxcb-xinerama0 libxcb-xinput0 libxcb-cursor0 \
  libxkbcommon-x11-0 libqt5gui5 libqt5widgets5
```

> **Modern Pylon note.** Pylon 7/8 (`libpylonbase.so.12`) reorganised its headers: the transport-specific ones under `pylon/usb/` no longer exist. Use the transport-agnostic `pylon/InstantCameraArray.h` and `Pylon::CInstantCamera`, which drive **both** GigE and USB3. This is exactly the patch FicTrac needs — see [02](02-fictrac.md).

## 2. Network configuration

A GigE camera is a network device on a dedicated link. Reference configuration:

```
enx00e04c68131b   RTL8153 USB-Ethernet, 192.168.4.2/24, MTU 1500, 1000 Mbps  <- CAMERA
  camera:         192.168.4.3, MAC 00:30:53:2c:a0:de   (00:30:53 = Basler OUI)
enp0s31f6         onboard Ethernet, DOWN (unused)
wlp44s0f0         WiFi — the MATLAB licence is host-locked to this MAC. Never disable it.
```

Find your interfaces and which one has a link:

```bash
ip -br link show
ip addr show <camera-interface>
```

Set a static IP on the camera's interface (any private subnet; the camera must be on the same one):

```bash
nmcli con show                                    # find the connection name
nmcli con mod "<connection-name>" ipv4.method manual \
      ipv4.addresses 192.168.4.2/24
nmcli con up "<connection-name>"
```

Find the camera:

```bash
ip neigh show | grep 192.168.4        # look for a 00:30:53:* MAC
ping -c 2 192.168.4.3
```

If it does not appear, use Basler's IP tool — it detects cameras by MAC broadcast even when their IP is wrong for your subnet, and lets you assign one:

```bash
/opt/pylon/bin/ipconfigurator &
```

## 3. Do NOT enable jumbo frames on a USB-Ethernet adapter

Basler ships an optimiser:

```bash
sudo /opt/pylon/bin/PylonGigEConfigurator list      # shows adapters + settings
sudo /opt/pylon/bin/PylonGigEConfigurator auto-opt  # sets MTU 9000, buffers
```

**On the RTL8153 USB-Ethernet adapter this breaks streaming.** The adapter advertises MTU 9000 but cannot deliver it. Small packets (ping) still work, so the fault looks mysterious — video simply stops.

Test the jumbo path explicitly:

```bash
ping -M do -s 8972 -c 3 192.168.4.3    # 8972 + 28 header = 9000, don't-fragment
```

On the reference machine: **100% packet loss**. Revert to 1500 and pin it:

```bash
sudo ip link set <camera-interface> mtu 1500
nmcli con mod "<connection-name>" 802-3-ethernet.mtu 1500
nmcli con up "<connection-name>"
ip link show <camera-interface> | grep -o "mtu [0-9]*"
```

MTU 1500 costs some efficiency, not function. If you use a proper PCIe NIC rather than a USB adapter, re-test the jumbo path — it may work, and 9000 is preferable when it does.

Prefer `auto-opt` only after confirming jumbo frames actually pass. Use `auto-opt`, **not** `auto-all` — the latter also reassigns IPs, which you do not want once addressing works.

## 4. Verify with Pylon Viewer

```bash
source /opt/pylon/bin/pylon-setup-env.sh /opt/pylon
/opt/pylon/bin/pylonviewer &
```

The camera should appear in the device tree. Double-click it, then **Continuous Shot** for live video.

If streaming fails while ping succeeds, check the camera's own packet size: **Transport Layer → GevSCPSPacketSize** (needs Expert/Guru view). It must not exceed the host MTU — set it to 1500 if the host is at 1500.

> **Close Pylon Viewer before running FicTrac.** A GigE camera accepts one controlling application at a time; otherwise FicTrac reports
> `Failed to open ... The device is controlled by another application`.

## 5. Quick health check

```bash
echo "=== camera reachable? ==="
ping -c 2 192.168.4.3
echo "=== link + IP ==="
ip -br addr show <camera-interface>
echo "=== anything holding the camera? ==="
pgrep -a "pylonviewer|configGui|fictrac" || echo "camera is free"
```

---

## Checklist

- [ ] `/opt/pylon` installed, `$PYLON_ROOT` set
- [ ] Camera pings on the dedicated subnet
- [ ] **MTU 1500** confirmed and pinned
- [ ] Live image in Pylon Viewer
- [ ] Pylon Viewer closed again

Next: [02 — FicTrac](02-fictrac.md)

---

*JC Lab, University of Groningen. Problems with this guide? Contact Vasilis Kapantaidakis — vaskapant@gmail.com or v.kapantaidakis@student.rug.nl*
