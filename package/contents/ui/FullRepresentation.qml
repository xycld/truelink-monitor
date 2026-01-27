pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid
import org.kde.plasma.private.truelinkmonitor

PlasmaExtras.Representation {
    id: fullRoot

    Layout.preferredWidth: Kirigami.Units.gridUnit * 18
    Layout.preferredHeight: Kirigami.Units.gridUnit * 22
    Layout.minimumWidth: Kirigami.Units.gridUnit * 14
    Layout.minimumHeight: Kirigami.Units.gridUnit * 10
    Layout.maximumWidth: Kirigami.Units.gridUnit * 30
    Layout.maximumHeight: Kirigami.Units.gridUnit * 40

    collapseMarginsHint: true

    property bool isConnected: WifiMonitor.connected

    function formatBytes(bytes: real): string {
        var b = bytes || 0;
        if (b < 1024) return i18n("%1 B", b);
        if (b < 1048576) return i18n("%1 KB", (b / 1024).toFixed(1));
        if (b < 1073741824) return i18n("%1 MB", (b / 1048576).toFixed(1));
        return i18n("%1 GB", (b / 1073741824).toFixed(2));
    }

    function formatDuration(seconds: int): string {
        var s = seconds || 0;
        if (s < 60) return i18n("%1s", s);
        if (s < 3600) return i18n("%1m %2s", Math.floor(s / 60), s % 60);
        var h = Math.floor(s / 3600);
        var m = Math.floor((s % 3600) / 60);
        return i18n("%1h %2m", h, m);
    }

    function maskIp(ip: string): string {
        if (!ip) return i18n("N/A");
        return "XXX.XXX.XXX.XXX";
    }

    PlasmaComponents3.ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        PlasmaComponents3.ScrollBar.horizontal.policy: PlasmaComponents3.ScrollBar.AlwaysOff

        ColumnLayout {
            id: mainColumn
            width: parent.width
            spacing: Kirigami.Units.smallSpacing

            // Disconnected placeholder
            PlasmaExtras.PlaceholderMessage {
                visible: !fullRoot.isConnected
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Kirigami.Units.gridUnit * 8
                iconName: WifiMonitor.available ? "network-wireless-disconnected" : "network-wireless-off"
                text: WifiMonitor.available ? i18n("No WiFi connection") : i18n("No WiFi adapter found")
            }

            // SSID header with WiFi generation badge
            RowLayout {
                visible: fullRoot.isConnected
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Heading {
                    text: WifiMonitor.ssid
                    level: 4
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Rectangle {
                    color: Kirigami.Theme.highlightColor
                    radius: Kirigami.Units.smallSpacing
                    implicitWidth: genLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
                    implicitHeight: genLabel.implicitHeight + Kirigami.Units.smallSpacing

                    PlasmaComponents3.Label {
                        id: genLabel
                        anchors.centerIn: parent
                        text: WifiMonitor.wifiGeneration
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: Kirigami.Theme.highlightedTextColor
                    }
                }
            }

            // Signal info section
            ColumnLayout {
                visible: fullRoot.isConnected
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    visible: Plasmoid.configuration.showSignalInfo
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing

                    PlasmaComponents3.Label {
                        text: i18n("%1 dBm", WifiMonitor.signalDbm)
                        color: WifiMonitor.statusColor
                        font.bold: true
                    }

                    PlasmaComponents3.Label {
                        text: WifiMonitor.signalQuality
                        color: WifiMonitor.statusColor
                    }

                    Item { Layout.fillWidth: true }

                    PlasmaComponents3.Label {
                        visible: Plasmoid.configuration.showChannelInfo
                        text: i18n("%1 MHz", WifiMonitor.channelWidth)
                        opacity: 0.75
                    }

                    PlasmaComponents3.Label {
                        visible: Plasmoid.configuration.showChannelInfo
                        text: i18nc("WiFi channel number", "CH %1", WifiMonitor.channel)
                        opacity: 0.75
                    }
                }
            }

            // Link rate chart section
            Kirigami.Separator {
                visible: fullRoot.isConnected && Plasmoid.configuration.showLinkRateChart
                Layout.fillWidth: true
            }

            ColumnLayout {
                visible: fullRoot.isConnected && Plasmoid.configuration.showLinkRateChart
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                Layout.margins: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true

                    PlasmaComponents3.Label {
                        text: i18n("Link Rate (Mbps)")
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: Kirigami.Units.smallSpacing * 2
                        height: width
                        radius: width / 2
                        color: Kirigami.Theme.highlightColor
                    }

                    PlasmaComponents3.Label {
                        text: i18nc("Receive rate legend", "RX")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.75
                    }

                    Rectangle {
                        width: Kirigami.Units.smallSpacing * 2
                        height: width
                        radius: width / 2
                        color: Kirigami.Theme.neutralTextColor
                    }

                    PlasmaComponents3.Label {
                        text: i18nc("Transmit rate legend", "TX")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.75
                    }
                }

                Canvas {
                    id: rateChart

                    property var rxData: WifiMonitor.rxHistory
                    property var txData: WifiMonitor.txHistory
                    property real maxRate: WifiMonitor.maxHistoryRate
                    property bool paintScheduled: false

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    function schedulePaint(): void {
                        if (paintScheduled) return;
                        paintScheduled = true;
                        Qt.callLater(function() {
                            paintScheduled = false;
                            rateChart.requestPaint();
                        });
                    }

                    onRxDataChanged: schedulePaint()
                    onTxDataChanged: schedulePaint()
                    onMaxRateChanged: schedulePaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);

                        var leftPadding = 36;
                        var topPadding = 8;
                        var padding = 4;
                        var chartWidth = width - leftPadding - padding;
                        var chartHeight = height - topPadding - padding;

                        ctx.font = "9px sans-serif";
                        ctx.fillStyle = Kirigami.Theme.disabledTextColor;
                        ctx.textAlign = "right";
                        ctx.textBaseline = "middle";

                        var scaleMax = maxRate > 0 ? maxRate : 100;
                        for (var i = 0; i <= 4; i++) {
                            var y = topPadding + (chartHeight * i / 4);
                            var value = Math.round(scaleMax * (4 - i) / 4);
                            ctx.fillText(value.toString(), leftPadding - 4, y);
                        }

                        ctx.strokeStyle = Kirigami.Theme.separatorColor;
                        ctx.lineWidth = 0.5;
                        ctx.setLineDash([2, 2]);
                        for (var j = 0; j <= 4; j++) {
                            var yLine = topPadding + (chartHeight * j / 4);
                            ctx.beginPath();
                            ctx.moveTo(leftPadding, yLine);
                            ctx.lineTo(width - padding, yLine);
                            ctx.stroke();
                        }
                        ctx.setLineDash([]);

                        drawLine(ctx, txData, Kirigami.Theme.neutralTextColor, leftPadding, chartWidth, chartHeight, scaleMax, topPadding);
                        drawLine(ctx, rxData, Kirigami.Theme.highlightColor, leftPadding, chartWidth, chartHeight, scaleMax, topPadding);
                    }

                    function drawLine(ctx: var, data: var, color: color, leftPadding: real, chartWidth: real, chartHeight: real, maxRate: real, topPadding: real): void {
                        if (!data || data.length < 2 || !maxRate || maxRate <= 0) return;

                        ctx.strokeStyle = color;
                        ctx.lineWidth = 2;
                        ctx.lineJoin = "round";
                        ctx.lineCap = "round";
                        ctx.beginPath();
                        var denom = Math.max(1, data.length - 1);
                        var step = chartWidth / denom;
                        for (var j = 0; j < data.length; j++) {
                            var x = leftPadding + j * step;
                            var y = topPadding + chartHeight - (data[j] / maxRate) * chartHeight;
                            if (j === 0)
                                ctx.moveTo(x, y);
                            else
                                ctx.lineTo(x, y);
                        }
                        ctx.stroke();
                    }
                }
            }

            // Rate details section
            Kirigami.Separator {
                visible: fullRoot.isConnected && (Plasmoid.configuration.showRxTxRate || Plasmoid.configuration.showMcs || Plasmoid.configuration.showMimo)
                Layout.fillWidth: true
            }

            GridLayout {
                visible: fullRoot.isConnected && (Plasmoid.configuration.showRxTxRate || Plasmoid.configuration.showMcs || Plasmoid.configuration.showMimo)
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing
                columns: 4
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showRxTxRate
                    text: i18nc("Receive rate label", "RX")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showRxTxRate
                    text: i18n("%1 Mbps", WifiMonitor.rxRate.toFixed(1))
                    font.bold: true
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showRxTxRate
                    text: i18nc("Transmit rate label", "TX")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showRxTxRate
                    text: i18n("%1 Mbps", WifiMonitor.txRate.toFixed(1))
                    font.bold: true
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showMcs
                    text: i18nc("Modulation coding scheme", "MCS")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showMcs
                    text: WifiMonitor.mcsIndex.toString()
                    font.bold: true
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showMimo
                    text: i18nc("MIMO spatial streams", "MIMO")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showMimo
                    text: WifiMonitor.mimoStreams > 0 ? i18n("%1x%1", WifiMonitor.mimoStreams) : "N/A"
                    font.bold: true
                }

                PlasmaComponents3.Label {
                    text: i18nc("Radio frequency", "Freq")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    text: i18n("%1 MHz", WifiMonitor.frequency)
                }

                PlasmaComponents3.Label {
                    text: i18nc("Security protocol", "Security")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    text: WifiMonitor.security
                }
            }

            // Traffic stats section
            Kirigami.Separator {
                visible: fullRoot.isConnected && Plasmoid.configuration.showTrafficStats
                Layout.fillWidth: true
            }

            GridLayout {
                visible: fullRoot.isConnected && Plasmoid.configuration.showTrafficStats
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing
                columns: 4
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.Label {
                    text: i18nc("Received bytes", "RX Bytes")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    text: fullRoot.formatBytes(WifiMonitor.rxBytes)
                }

                PlasmaComponents3.Label {
                    text: i18nc("Transmitted bytes", "TX Bytes")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    text: fullRoot.formatBytes(WifiMonitor.txBytes)
                }

                PlasmaComponents3.Label {
                    text: i18nc("Received packets", "RX Pkts")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    text: (WifiMonitor.rxPackets || 0).toLocaleString()
                }

                PlasmaComponents3.Label {
                    text: i18nc("Transmitted packets", "TX Pkts")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    text: (WifiMonitor.txPackets || 0).toLocaleString()
                }
            }

            // Link quality section
            Kirigami.Separator {
                visible: fullRoot.isConnected && Plasmoid.configuration.showLinkQuality
                Layout.fillWidth: true
            }

            GridLayout {
                visible: fullRoot.isConnected && Plasmoid.configuration.showLinkQuality
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing
                columns: 4
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.Label {
                    text: i18nc("Transmission retries", "Retries")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    text: (WifiMonitor.txRetries || 0).toLocaleString()
                }

                PlasmaComponents3.Label {
                    text: i18nc("Transmission failures", "Failed")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    text: (WifiMonitor.txFailed || 0).toLocaleString()
                    color: (WifiMonitor.txFailed || 0) > 0 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                }

                PlasmaComponents3.Label {
                    text: i18nc("Dropped packets", "Dropped")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    text: (WifiMonitor.rxDropped || 0).toLocaleString()
                    color: (WifiMonitor.rxDropped || 0) > 0 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showBeaconStats
                    text: i18nc("Beacon loss count", "Bcn Loss")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showBeaconStats
                    text: (WifiMonitor.beaconLoss || 0).toLocaleString()
                    color: (WifiMonitor.beaconLoss || 0) > 0 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                }
            }

            // Connection info section
            Kirigami.Separator {
                visible: fullRoot.isConnected && (Plasmoid.configuration.showConnectedTime || Plasmoid.configuration.showExpectedThroughput || Plasmoid.configuration.showIpAddress || Plasmoid.configuration.showGateway || Plasmoid.configuration.showBssid)
                Layout.fillWidth: true
            }

            GridLayout {
                visible: fullRoot.isConnected
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing
                columns: 2
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showConnectedTime
                    text: i18n("Connected")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showConnectedTime
                    text: fullRoot.formatDuration(WifiMonitor.connectedTime)
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showExpectedThroughput && WifiMonitor.expectedThroughput > 0
                    text: i18n("Expected")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showExpectedThroughput && WifiMonitor.expectedThroughput > 0
                    text: i18n("%1 Mbps", (WifiMonitor.expectedThroughput / 1000).toFixed(1))
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showIpAddress
                    text: i18n("IP Address")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    id: ipLabel
                    visible: Plasmoid.configuration.showIpAddress
                    property bool revealed: false
                    text: revealed ? (WifiMonitor.ipAddress || i18n("N/A")) : fullRoot.maskIp(WifiMonitor.ipAddress)
                    font.family: "monospace"
                    Layout.fillWidth: true

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ipLabel.revealed = !ipLabel.revealed
                    }
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showGateway
                    text: i18n("Gateway")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    id: gatewayLabel
                    visible: Plasmoid.configuration.showGateway
                    property bool revealed: false
                    text: revealed ? (WifiMonitor.gateway || i18n("N/A")) : fullRoot.maskIp(WifiMonitor.gateway)
                    font.family: "monospace"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: gatewayLabel.revealed = !gatewayLabel.revealed
                    }
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showBssid
                    text: i18n("BSSID")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    id: bssidLabel
                    visible: Plasmoid.configuration.showBssid
                    property bool revealed: false
                    text: revealed ? WifiMonitor.bssid : "XX:XX:XX:XX:XX:XX"
                    font.family: "monospace"
                    font.pointSize: Kirigami.Theme.smallFont.pointSize

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bssidLabel.revealed = !bssidLabel.revealed
                    }
                }
            }

            // Advanced section
            Kirigami.Separator {
                visible: fullRoot.isConnected && (Plasmoid.configuration.showAckSignal || Plasmoid.configuration.showAirtime)
                Layout.fillWidth: true
            }

            GridLayout {
                visible: fullRoot.isConnected && (Plasmoid.configuration.showAckSignal || Plasmoid.configuration.showAirtime)
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing
                columns: 4
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showAckSignal && WifiMonitor.hasAckSignal
                    text: i18nc("ACK signal strength", "ACK Sig")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showAckSignal && WifiMonitor.hasAckSignal
                    text: i18n("%1 dBm", WifiMonitor.ackSignal)
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showAckSignal && WifiMonitor.hasAckSignal
                    text: i18nc("ACK signal average", "ACK Avg")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showAckSignal && WifiMonitor.hasAckSignal
                    text: i18n("%1 dBm", WifiMonitor.ackSignalAvg)
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showAirtime
                    text: i18nc("Receive duration", "RX Time")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showAirtime
                    text: i18n("%1 ms", (WifiMonitor.rxDuration / 1000).toFixed(0))
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showAirtime
                    text: i18nc("Transmit duration", "TX Time")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showAirtime
                    text: i18n("%1 ms", (WifiMonitor.txDuration / 1000).toFixed(0))
                }
            }
        }
    }
}
