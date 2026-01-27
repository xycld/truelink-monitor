# TrueLink Monitor (Plasma 6)

[简体中文](README.zh-CN.md) | English

TrueLink Monitor is a KDE Plasma 6 widget that displays WiFi physical layer
information directly from nl80211/libnl, providing real-time insight into your
wireless connection quality.

## Features

- Real-time signal strength (dBm) and quality percentage
- PHY link rates (RX/TX Mbps) with history chart
- WiFi generation detection (WiFi 4/5/6/6E/7)
- MCS index and MIMO spatial streams
- Channel number and bandwidth
- Traffic statistics and link quality metrics
- Dynamic tray icon based on signal strength
- Configurable display options
- i18n support (English, Simplified Chinese)

## Requirements

- KDE Plasma 6
- Qt 6.6+
- KDE Frameworks 6 (KF6)
- NetworkManager + NetworkManagerQt (KF6)
- libnl (for nl80211 station statistics)

Note: Advanced nl80211 station statistics may require elevated privileges on
some systems (e.g. CAP_NET_ADMIN), depending on kernel/distro policy.

## Installation

### Arch Linux (AUR)

```bash
paru -S plasma6-applet-truelink-monitor
```

### Manual Build

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
```

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

## Configuration Options

Right-click the widget and select "Configure..." to customize the display.

### Display

| Option | Description | Default |
|--------|-------------|---------|
| **Link rate chart** | Show RX/TX rate history graph with 60-second rolling window. The chart uses smoothed values (EMA) for visual clarity. | On |
| **Signal info** | Show signal strength in dBm and quality percentage (Excellent/Good/Fair/Weak). | On |
| **Channel info** | Show WiFi channel number and bandwidth (20/40/80/160 MHz). | On |

### Rate Details

| Option | Description | Default |
|--------|-------------|---------|
| **RX/TX rate** | Show current receive and transmit link rates in Mbps. These are raw PHY rates, not actual throughput. | On |
| **MCS index** | Show Modulation and Coding Scheme index. Higher MCS = faster potential speed but requires better signal. | On |
| **MIMO streams** | Show number of spatial streams (e.g., 2x2). More streams = higher throughput capacity. | On |

### Statistics

| Option | Description | Default |
|--------|-------------|---------|
| **Traffic stats** | Show cumulative RX/TX bytes and packet counts since connection. | Off |
| **Link quality** | Show TX retries, failures, and RX dropped packets. High values indicate interference or weak signal. | Off |
| **Beacon stats** | Show beacon loss count. Beacon loss indicates AP reachability issues. | Off |

### Connection

| Option | Description | Default |
|--------|-------------|---------|
| **Connected time** | Show how long the current connection has been active. | On |
| **Expected throughput** | Show kernel-estimated throughput based on current conditions. May not be available on all drivers. | Off |
| **IP address** | Show local IP address (click to reveal, masked by default for privacy). | On |
| **Gateway** | Show gateway IP address (click to reveal, masked by default). | On |
| **BSSID** | Show Access Point MAC address (click to reveal, masked by default). | On |

### Advanced

| Option | Description | Default |
|--------|-------------|---------|
| **ACK signal** | Show ACK signal strength from the AP. Indicates bidirectional link quality. Not supported by all drivers. | Off |
| **Airtime** | Show RX/TX duration in milliseconds. Indicates channel utilization. Not supported by all drivers (may show 0). | Off |

## Technical Notes

### Data Sources

- **nl80211**: Direct kernel interface for WiFi statistics (signal, rates, MCS, etc.)
- **NetworkManager**: Connection metadata (SSID, IP, gateway, security)

### WiFi Generations

| Badge | Standard | Max Rate | Frequency |
|-------|----------|----------|-----------|
| WiFi 4 | 802.11n (HT) | 600 Mbps | 2.4/5 GHz |
| WiFi 5 | 802.11ac (VHT) | 3.5 Gbps | 5 GHz |
| WiFi 6 | 802.11ax (HE) | 9.6 Gbps | 2.4/5 GHz |
| WiFi 6E | 802.11ax (HE) | 9.6 Gbps | 6 GHz |
| WiFi 7 | 802.11be (EHT) | 46 Gbps | 2.4/5/6 GHz |

### Signal Quality Thresholds

| Quality | dBm Range | Icon |
|---------|-----------|------|
| Excellent | ≥ -50 | Full bars |
| Good | -50 to -60 | 3 bars |
| Fair | -60 to -70 | 2 bars |
| Weak | -70 to -80 | 1 bar |
| Poor | < -80 | No bars |

## License

MIT. See `LICENSE`.
