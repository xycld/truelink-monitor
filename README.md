# TrueLink Monitor (Plasma 6)

TrueLink Monitor is a KDE Plasma 6 widget that shows Wi-Fi physical layer
information (RSSI dBm, PHY rate, MCS/NSS, channel width) in addition to basic
connection details.

## Requirements

- KDE Plasma 6
- Qt 6.6+
- KDE Frameworks 6 (KF6)
- NetworkManager + NetworkManagerQt (KF6)
- libnl (for nl80211 station statistics)

Note: advanced nl80211 station statistics can require elevated privileges on
some systems (e.g. CAP_NET_ADMIN), depending on kernel / distro policy.

## Build

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
```

## Install

User install (no sudo):

```bash
cmake --install build --prefix ~/.local
```

System install:

```bash
sudo cmake --install build
```

After installing, restart Plasma shell (or log out/in) and add the widget from
Edit Mode.

## License

MIT. See `LICENSE`.
