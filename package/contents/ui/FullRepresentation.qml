pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml
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

    // Shared width for left-side labels (column 1) across all sections
    property real leftLabelWidth: Math.max(
        rxLabelMetrics.width,
        mcsLabelMetrics.width,
        freqLabelMetrics.width,
        rxBytesLabelMetrics.width,
        rxPktsLabelMetrics.width,
        retriesLabelMetrics.width,
        droppedLabelMetrics.width,
        ackSigLabelMetrics.width,
        rxTimeLabelMetrics.width
    ) + Kirigami.Units.smallSpacing

    // Shared width for right-side labels (column 3) across all sections
    // This ensures all right-side labels align to the same centerline
    property real rightLabelWidth: Math.max(
        txLabelMetrics.width,
        mimoLabelMetrics.width,
        securityLabelMetrics.width,
        txBytesLabelMetrics.width,
        txPktsLabelMetrics.width,
        failedLabelMetrics.width,
        bcnLossLabelMetrics.width,
        ackAvgLabelMetrics.width,
        txTimeLabelMetrics.width
    ) + Kirigami.Units.smallSpacing

    // Fixed width for value columns (column 2 and 4) to ensure consistent centerline
    // Calculate available width after labels and spacing, then split evenly
    property real valueColumnWidth: {
        var totalWidth = fullRoot.width - 2 * Kirigami.Units.smallSpacing  // margins
        var labelsWidth = leftLabelWidth + rightLabelWidth
        var spacing = 3 * Kirigami.Units.largeSpacing  // 3 column gaps
        var availableForValues = totalWidth - labelsWidth - spacing
        return Math.max(availableForValues / 2, Kirigami.Units.gridUnit * 4)
    }

    // TextMetrics for all left-side labels (column 1)
    TextMetrics { id: rxLabelMetrics; text: i18nc("Receive rate label", "RX"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
    TextMetrics { id: mcsLabelMetrics; text: i18nc("Modulation coding scheme", "MCS"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
    TextMetrics { id: freqLabelMetrics; text: i18nc("Radio frequency", "Freq"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
    TextMetrics { id: rxBytesLabelMetrics; text: i18nc("Received bytes", "RX Bytes"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
    TextMetrics { id: rxPktsLabelMetrics; text: i18nc("Received packets", "RX Pkts"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
    TextMetrics { id: retriesLabelMetrics; text: i18nc("Transmission retries", "Retries"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
    TextMetrics { id: droppedLabelMetrics; text: i18nc("Dropped packets", "Dropped"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
    TextMetrics { id: ackSigLabelMetrics; text: i18nc("ACK signal strength", "ACK Sig"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
    TextMetrics { id: rxTimeLabelMetrics; text: i18nc("Receive duration", "RX Time"); font.pointSize: Kirigami.Theme.smallFont.pointSize }

    // TextMetrics for all right-side labels (column 3)
    TextMetrics { id: txLabelMetrics; text: i18nc("Transmit rate label", "TX"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
    TextMetrics { id: mimoLabelMetrics; text: i18nc("MIMO spatial streams", "MIMO"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
    TextMetrics { id: securityLabelMetrics; text: i18nc("Security protocol", "Security"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
    TextMetrics { id: txBytesLabelMetrics; text: i18nc("Transmitted bytes", "TX Bytes"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
    TextMetrics { id: txPktsLabelMetrics; text: i18nc("Transmitted packets", "TX Pkts"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
    TextMetrics { id: failedLabelMetrics; text: i18nc("Transmission failures", "Failed"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
    TextMetrics { id: bcnLossLabelMetrics; text: i18nc("Beacon loss count", "Bcn Loss"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
    TextMetrics { id: ackAvgLabelMetrics; text: i18nc("ACK signal average", "ACK Avg"); font.pointSize: Kirigami.Theme.smallFont.pointSize }
    TextMetrics { id: txTimeLabelMetrics; text: i18nc("Transmit duration", "TX Time"); font.pointSize: Kirigami.Theme.smallFont.pointSize }

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
        return "***.***.***.***";
    }

    function formatNumber(num: real): string {
        var n = num || 0;
        if (n >= 1000000000) return i18n("%1M", (n / 1000000).toLocaleString(Qt.locale(), 'f', 1));
        if (n >= 1000000) return i18n("%1K", (n / 1000).toLocaleString(Qt.locale(), 'f', 1));
        return Math.floor(n).toLocaleString(Qt.locale(), 'f', 0);
    }

    PlasmaComponents3.ScrollView {
        id: scrollView
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        contentWidth: availableWidth - contentItem.leftMargin - contentItem.rightMargin
        PlasmaComponents3.ScrollBar.horizontal.policy: PlasmaComponents3.ScrollBar.AlwaysOff

        ColumnLayout {
            id: mainColumn
            width: scrollView.availableWidth
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
                    textFormat: Text.PlainText
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
                Layout.preferredHeight: Kirigami.Units.gridUnit * Plasmoid.configuration.chartHeight
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

                // Row 1: RX / TX rates
                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showRxTxRate
                    text: i18nc("Receive rate label", "RX")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                    Layout.preferredWidth: fullRoot.leftLabelWidth
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showRxTxRate
                    text: i18n("%1 Mbps", WifiMonitor.rxRate.toFixed(1))
                    font.bold: true
                    Layout.preferredWidth: fullRoot.valueColumnWidth
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showRxTxRate
                    text: i18nc("Transmit rate label", "TX")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                    Layout.preferredWidth: fullRoot.rightLabelWidth
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showRxTxRate
                    text: i18n("%1 Mbps", WifiMonitor.txRate.toFixed(1))
                    font.bold: true
                    Layout.fillWidth: true
                }

                // Row 2: MCS / MIMO
                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showMcs
                    text: i18nc("Modulation coding scheme", "MCS")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                    Layout.preferredWidth: fullRoot.leftLabelWidth
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showMcs
                    text: WifiMonitor.mcsIndex.toString()
                    font.bold: true
                    Layout.preferredWidth: fullRoot.valueColumnWidth
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showMimo
                    text: i18nc("MIMO spatial streams", "MIMO")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                    Layout.preferredWidth: fullRoot.rightLabelWidth
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showMimo
                    text: WifiMonitor.mimoStreams > 0 ? i18n("%1x%1", WifiMonitor.mimoStreams) : "N/A"
                    font.bold: true
                    Layout.fillWidth: true
                }

                // Row 3: Freq / Security
                PlasmaComponents3.Label {
                    text: i18nc("Radio frequency", "Freq")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                    Layout.preferredWidth: fullRoot.leftLabelWidth
                }

                PlasmaComponents3.Label {
                    text: i18n("%1 MHz", WifiMonitor.frequency)
                    Layout.preferredWidth: fullRoot.valueColumnWidth
                }

                PlasmaComponents3.Label {
                    text: i18nc("Security protocol", "Security")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                    Layout.preferredWidth: fullRoot.rightLabelWidth
                }

                PlasmaComponents3.Label {
                    text: WifiMonitor.security
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
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

                // Row 1: RX Bytes / TX Bytes
                PlasmaComponents3.Label {
                    text: i18nc("Received bytes", "RX Bytes")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                    Layout.preferredWidth: fullRoot.leftLabelWidth
                }

                PlasmaComponents3.Label {
                    text: fullRoot.formatBytes(WifiMonitor.rxBytes)
                    Layout.preferredWidth: fullRoot.valueColumnWidth
                }

                PlasmaComponents3.Label {
                    text: i18nc("Transmitted bytes", "TX Bytes")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                    Layout.preferredWidth: fullRoot.rightLabelWidth
                }

                PlasmaComponents3.Label {
                    text: fullRoot.formatBytes(WifiMonitor.txBytes)
                    Layout.fillWidth: true
                }

                // Row 2: RX Pkts / TX Pkts
                PlasmaComponents3.Label {
                    text: i18nc("Received packets", "RX Pkts")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                    Layout.preferredWidth: fullRoot.leftLabelWidth
                }

                PlasmaComponents3.Label {
                    text: fullRoot.formatNumber(WifiMonitor.rxPackets)
                    Layout.preferredWidth: fullRoot.valueColumnWidth
                }

                PlasmaComponents3.Label {
                    text: i18nc("Transmitted packets", "TX Pkts")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                    Layout.preferredWidth: fullRoot.rightLabelWidth
                }

                PlasmaComponents3.Label {
                    text: fullRoot.formatNumber(WifiMonitor.txPackets)
                    Layout.fillWidth: true
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

                // Row 1: Retries / Failed
                PlasmaComponents3.Label {
                    text: i18nc("Transmission retries", "Retries")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                    Layout.preferredWidth: fullRoot.leftLabelWidth
                }

                PlasmaComponents3.Label {
                    text: fullRoot.formatNumber(WifiMonitor.txRetries)
                    Layout.preferredWidth: fullRoot.valueColumnWidth
                }

                PlasmaComponents3.Label {
                    text: i18nc("Transmission failures", "Failed")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                    Layout.preferredWidth: fullRoot.rightLabelWidth
                }

                PlasmaComponents3.Label {
                    text: fullRoot.formatNumber(WifiMonitor.txFailed)
                    color: (WifiMonitor.txFailed || 0) > 0 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                    Layout.fillWidth: true
                }

                // Row 2: Dropped / Bcn Loss
                PlasmaComponents3.Label {
                    text: i18nc("Dropped packets", "Dropped")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                    Layout.preferredWidth: fullRoot.leftLabelWidth
                }

                PlasmaComponents3.Label {
                    text: fullRoot.formatNumber(WifiMonitor.rxDropped)
                    color: (WifiMonitor.rxDropped || 0) > 0 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                    Layout.preferredWidth: fullRoot.valueColumnWidth
                }

                PlasmaComponents3.Label {
                    opacity: Plasmoid.configuration.showBeaconStats ? 0.6 : 0
                    text: i18nc("Beacon loss count", "Bcn Loss")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    Layout.preferredWidth: fullRoot.rightLabelWidth
                }

                PlasmaComponents3.Label {
                    opacity: Plasmoid.configuration.showBeaconStats ? 1 : 0
                    text: fullRoot.formatNumber(WifiMonitor.beaconLoss)
                    color: (WifiMonitor.beaconLoss || 0) > 0 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                    Layout.fillWidth: true
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
                    textFormat: Text.PlainText
                    font.family: "monospace"
                    font.features: { "liga": 0, "clig": 0, "dlig": 0, "hlig": 0, "calt": 0 }
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
                    textFormat: Text.PlainText
                    font.family: "monospace"
                    font.features: { "liga": 0, "clig": 0, "dlig": 0, "hlig": 0, "calt": 0 }

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
                    text: revealed ? WifiMonitor.bssid : "**:**:**:**:**:**"
                    textFormat: Text.PlainText
                    font.family: "monospace"
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.features: { "liga": 0, "clig": 0, "dlig": 0, "hlig": 0, "calt": 0 }

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

                // Row 1: ACK Sig / ACK Avg
                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showAckSignal && WifiMonitor.hasAckSignal
                    text: i18nc("ACK signal strength", "ACK Sig")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                    Layout.preferredWidth: fullRoot.leftLabelWidth
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showAckSignal && WifiMonitor.hasAckSignal
                    text: i18n("%1 dBm", WifiMonitor.ackSignal)
                    Layout.preferredWidth: fullRoot.valueColumnWidth
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showAckSignal && WifiMonitor.hasAckSignal
                    text: i18nc("ACK signal average", "ACK Avg")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                    Layout.preferredWidth: fullRoot.rightLabelWidth
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showAckSignal && WifiMonitor.hasAckSignal
                    text: i18n("%1 dBm", WifiMonitor.ackSignalAvg)
                    Layout.fillWidth: true
                }

                // Row 2: RX Time / TX Time (hidden if driver doesn't support)
                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showAirtime && (WifiMonitor.rxDuration > 0 || WifiMonitor.txDuration > 0)
                    text: i18nc("Receive duration", "RX Time")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                    Layout.preferredWidth: fullRoot.leftLabelWidth
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showAirtime && (WifiMonitor.rxDuration > 0 || WifiMonitor.txDuration > 0)
                    text: i18n("%1 ms", (WifiMonitor.rxDuration / 1000).toFixed(0))
                    Layout.preferredWidth: fullRoot.valueColumnWidth
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showAirtime && (WifiMonitor.rxDuration > 0 || WifiMonitor.txDuration > 0)
                    text: i18nc("Transmit duration", "TX Time")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                    Layout.preferredWidth: fullRoot.rightLabelWidth
                }

                PlasmaComponents3.Label {
                    visible: Plasmoid.configuration.showAirtime && (WifiMonitor.rxDuration > 0 || WifiMonitor.txDuration > 0)
                    text: i18n("%1 ms", (WifiMonitor.txDuration / 1000).toFixed(0))
                    Layout.fillWidth: true
                }
            }
        }
    }
}
