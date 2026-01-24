import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.truelinkmonitor

PlasmoidItem {
    id: root

    property bool isConnected: WifiMonitor.connected
    property bool isAvailable: WifiMonitor.available
    property bool isOnDesktop: Plasmoid.formFactor === PlasmaCore.Types.Planar

    preferredRepresentation: isOnDesktop ? fullRepresentation : compactRepresentation
    Plasmoid.status: {
        if (!root.isAvailable)
            return PlasmaCore.Types.HiddenStatus;

        return PlasmaCore.Types.ActiveStatus;
    }
    Plasmoid.icon: "network-wireless"
    Plasmoid.title: i18n("TrueLink Monitor")
    toolTipMainText: root.isConnected ? WifiMonitor.ssid : i18n("Not Connected")
    toolTipSubText: {
        if (!root.isConnected)
            return "";

        return i18n("%1 Mbps | %2 dBm | %3 | %4 MHz", WifiMonitor.rxRate.toFixed(0), WifiMonitor.signalDbm, WifiMonitor.wifiGeneration, WifiMonitor.channelWidth);
    }

    compactRepresentation: MouseArea {
        id: compactRoot

        Layout.minimumWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.minimumHeight: Kirigami.Units.iconSizes.small
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: row

            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                width: 4
                height: parent.height * 0.8
                radius: 2
                color: root.isConnected ? WifiMonitor.statusColor : Kirigami.Theme.disabledTextColor
                Layout.alignment: Qt.AlignVCenter
            }

            PlasmaComponents.Label {
                text: {
                    if (!root.isAvailable)
                        return i18n("No Adapter");

                    if (!root.isConnected)
                        return i18n("Disconnected");

                    return i18n("%1 Mbps", Math.round(WifiMonitor.rxRate));
                }
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                Layout.alignment: Qt.AlignVCenter
            }

            PlasmaComponents.Label {
                visible: root.isConnected
                text: i18n("%1 dBm", WifiMonitor.signalDbm)
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.8
                Layout.alignment: Qt.AlignVCenter
            }

        }

    }

    fullRepresentation: QQC2.ScrollView {
        id: fullRoot

        Layout.preferredWidth: Kirigami.Units.gridUnit * 18
        Layout.preferredHeight: Kirigami.Units.gridUnit * 18
        Layout.minimumWidth: Kirigami.Units.gridUnit * 14
        Layout.minimumHeight: Kirigami.Units.gridUnit * 10
        contentWidth: availableWidth

        ColumnLayout {
            id: mainColumn

            width: fullRoot.availableWidth
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                id: headerCard

                Layout.fillWidth: true
                Layout.preferredHeight: headerContent.implicitHeight + Kirigami.Units.smallSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Kirigami.Theme.backgroundColor
                border.color: Kirigami.Theme.separatorColor || Kirigami.Theme.disabledTextColor
                border.width: 1

                ColumnLayout {
                    id: headerContent

                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents.Label {
                            text: root.isConnected ? WifiMonitor.ssid : i18n("Not Connected")
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.3
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            visible: root.isConnected
                            width: genLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
                            height: genLabel.implicitHeight + Kirigami.Units.smallSpacing
                            radius: height / 2
                            color: Kirigami.Theme.highlightColor

                            PlasmaComponents.Label {
                                id: genLabel

                                anchors.centerIn: parent
                                text: WifiMonitor.wifiGeneration
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                font.bold: true
                                color: Kirigami.Theme.highlightedTextColor
                            }

                        }

                    }

                    RowLayout {
                        visible: root.isConnected
                        spacing: Kirigami.Units.largeSpacing

                        PlasmaComponents.Label {
                            text: i18n("%1 dBm", WifiMonitor.signalDbm)
                            color: WifiMonitor.statusColor
                            font.bold: true
                        }

                        PlasmaComponents.Label {
                            text: WifiMonitor.signalQuality
                            opacity: 0.8
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        PlasmaComponents.Label {
                            text: i18n("%1 MHz", WifiMonitor.channelWidth)
                            opacity: 0.8
                        }

                        PlasmaComponents.Label {
                            text: i18nc("WiFi channel number", "CH %1", WifiMonitor.channel)
                            opacity: 0.8
                        }

                    }

                }

            }

            Rectangle {
                id: chartCard

                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                radius: Kirigami.Units.smallSpacing
                color: Kirigami.Theme.backgroundColor
                border.color: Kirigami.Theme.separatorColor || Kirigami.Theme.disabledTextColor
                border.width: 1
                visible: root.isConnected

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: Kirigami.Units.smallSpacing
                        Layout.rightMargin: Kirigami.Units.smallSpacing

                        PlasmaComponents.Label {
                            text: i18n("Link Rate")
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            font.bold: true
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: Kirigami.Units.smallSpacing * 2
                            height: width
                            radius: width / 2
                            color: Kirigami.Theme.highlightColor
                        }

                        PlasmaComponents.Label {
                            text: i18nc("Receive rate", "RX %1", WifiMonitor.rxRate.toFixed(0))
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.8
                        }

                        Rectangle {
                            width: Kirigami.Units.smallSpacing * 2
                            height: width
                            radius: width / 2
                            color: Kirigami.Theme.neutralTextColor
                        }

                        PlasmaComponents.Label {
                            text: i18nc("Transmit rate", "TX %1", WifiMonitor.txRate.toFixed(0))
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.8
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

                        function schedulePaint() {
                            if (paintScheduled) {
                                return;
                            }
                            paintScheduled = true;
                            // Coalesce multiple property change notifications into a single repaint.
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
                            var padding = 4;
                            var chartWidth = width - padding * 2;
                            var chartHeight = height - padding * 2;
                            ctx.strokeStyle = Kirigami.Theme.separatorColor || Kirigami.Theme.disabledTextColor;
                            ctx.lineWidth = 0.5;
                            ctx.setLineDash([2, 2]);
                            for (var i = 0; i <= 4; i++) {
                                var y = padding + (chartHeight * i / 4);
                                ctx.beginPath();
                                ctx.moveTo(padding, y);
                                ctx.lineTo(width - padding, y);
                                ctx.stroke();
                            }
                            ctx.setLineDash([]);
                            drawLine(ctx, txData, Kirigami.Theme.neutralTextColor, padding, chartWidth, chartHeight, maxRate);
                            drawLine(ctx, rxData, Kirigami.Theme.highlightColor, padding, chartWidth, chartHeight, maxRate);
                        }

                        function drawLine(ctx, data, color, padding, chartWidth, chartHeight, maxRate) {
                            if (!data || data.length < 2 || !maxRate || maxRate <= 0)
                                return ;

                            ctx.strokeStyle = color;
                            ctx.lineWidth = 2;
                            ctx.lineJoin = "round";
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            var step = chartWidth / 59;
                            for (var j = 0; j < data.length; j++) {
                                var x = padding + j * step;
                                var y = padding + chartHeight - (data[j] / maxRate) * chartHeight;
                                if (j === 0)
                                    ctx.moveTo(x, y);
                                else
                                    ctx.lineTo(x, y);
                            }
                            ctx.stroke();
                        }

                    }

                }

            }

            Rectangle {
                id: statsCard

                Layout.fillWidth: true
                Layout.preferredHeight: statsGrid.implicitHeight + Kirigami.Units.smallSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Kirigami.Theme.backgroundColor
                border.color: Kirigami.Theme.separatorColor || Kirigami.Theme.disabledTextColor
                border.width: 1
                visible: root.isConnected

                GridLayout {
                    id: statsGrid

                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    columns: 4
                    columnSpacing: Kirigami.Units.smallSpacing
                    rowSpacing: 2

                    PlasmaComponents.Label {
                        text: i18nc("Receive rate label", "RX")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.6
                    }

                    PlasmaComponents.Label {
                        text: i18n("%1 Mbps", WifiMonitor.rxRate.toFixed(1))
                        font.bold: true
                    }

                    PlasmaComponents.Label {
                        text: i18nc("Transmit rate label", "TX")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.6
                    }

                    PlasmaComponents.Label {
                        text: i18n("%1 Mbps", WifiMonitor.txRate.toFixed(1))
                        font.bold: true
                    }

                    PlasmaComponents.Label {
                        text: i18nc("Modulation coding scheme", "MCS")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.6
                    }

                    PlasmaComponents.Label {
                        text: WifiMonitor.mcsIndex.toString()
                        font.bold: true
                    }

                    PlasmaComponents.Label {
                        text: i18nc("MIMO spatial streams", "MIMO")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.6
                    }

                    PlasmaComponents.Label {
                        text: WifiMonitor.mimoStreams > 0 ? i18n("%1x%1", WifiMonitor.mimoStreams) : "N/A"
                        font.bold: true
                    }

                    PlasmaComponents.Label {
                        text: i18nc("Radio frequency", "Freq")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.6
                    }

                    PlasmaComponents.Label {
                        text: i18n("%1 MHz", WifiMonitor.frequency)
                    }

                    PlasmaComponents.Label {
                        text: i18nc("Security protocol", "Security")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.6
                    }

                    PlasmaComponents.Label {
                        text: WifiMonitor.security
                    }

                }

            }

            Rectangle {
                id: connectionCard

                Layout.fillWidth: true
                Layout.preferredHeight: connGrid.implicitHeight + Kirigami.Units.smallSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Kirigami.Theme.backgroundColor
                border.color: Kirigami.Theme.separatorColor || Kirigami.Theme.disabledTextColor
                border.width: 1
                visible: root.isConnected

                GridLayout {
                    id: connGrid

                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    columns: 2
                    columnSpacing: Kirigami.Units.smallSpacing
                    rowSpacing: 2

                    PlasmaComponents.Label {
                        text: i18n("IP Address")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.6
                    }

                    PlasmaComponents.Label {
                        text: WifiMonitor.ipAddress || i18n("N/A")
                        font.family: "monospace"
                        Layout.fillWidth: true
                    }

                    PlasmaComponents.Label {
                        text: i18n("Gateway")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.6
                    }

                    PlasmaComponents.Label {
                        text: WifiMonitor.gateway || i18n("N/A")
                        font.family: "monospace"
                    }

                    PlasmaComponents.Label {
                        text: i18n("BSSID")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.6
                    }

                    PlasmaComponents.Label {
                        text: WifiMonitor.bssid
                        font.family: "monospace"
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }

                }

            }

            ColumnLayout {
                visible: !root.isConnected
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 8
                spacing: Kirigami.Units.largeSpacing

                Item {
                    Layout.fillHeight: true
                }

                Kirigami.Icon {
                    source: root.isAvailable ? "network-wireless-disconnected" : "network-wireless-off"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                    Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                    Layout.alignment: Qt.AlignHCenter
                    opacity: 0.5
                }

                PlasmaComponents.Label {
                    text: root.isAvailable ? i18n("No WiFi connection") : i18n("No WiFi adapter found")
                    opacity: 0.7
                    Layout.alignment: Qt.AlignHCenter
                }

                Item {
                    Layout.fillHeight: true
                }

            }

        }

    }

}
