pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.truelinkmonitor

PlasmoidItem {
    id: root

    readonly property bool isConnected: WifiMonitor.connected
    readonly property bool isAvailable: WifiMonitor.available
    readonly property bool isOnDesktop: Plasmoid.formFactor === PlasmaCore.Types.Planar

    preferredRepresentation: isOnDesktop ? fullRepresentation : compactRepresentation

    Plasmoid.status: {
        if (!root.isAvailable)
            return PlasmaCore.Types.HiddenStatus;
        return PlasmaCore.Types.ActiveStatus;
    }

    Plasmoid.icon: {
        if (!root.isAvailable)
            return "network-wireless-off";
        if (!root.isConnected)
            return "network-wireless-disconnected";

        // Dynamic icon based on signal strength
        var dbm = WifiMonitor.signalDbm;
        if (dbm >= -50)
            return "network-wireless-signal-excellent";
        if (dbm >= -60)
            return "network-wireless-signal-good";
        if (dbm >= -70)
            return "network-wireless-signal-ok";
        if (dbm >= -80)
            return "network-wireless-signal-low";
        return "network-wireless-signal-none";
    }

    Plasmoid.title: i18n("TrueLink Monitor")

    toolTipMainText: root.isConnected ? WifiMonitor.ssid : i18n("Not Connected")
    toolTipSubText: {
        if (!root.isConnected) {
            return WifiMonitor.lastError ? i18n("Error: %1", WifiMonitor.lastError) : "";
        }

        var base = i18n("%1 Mbps | %2 dBm | %3 | %4 MHz",
                        WifiMonitor.rxRate.toFixed(0),
                        WifiMonitor.signalDbm,
                        WifiMonitor.wifiGeneration,
                        WifiMonitor.channelWidth);

        if (WifiMonitor.lastError) {
            return base + "\n" + i18n("Error: %1", WifiMonitor.lastError);
        }

        return base;
    }

    // Context menu actions
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Open Network Settings")
            icon.name: "preferences-system-network"
            onTriggered: {
                Qt.openUrlExternally("kcm:kcm_networkmanagement");
            }
        },
        PlasmaCore.Action {
            text: i18n("Copy IP Address")
            icon.name: "edit-copy"
            enabled: root.isConnected && WifiMonitor.ipAddress
            onTriggered: {
                // Use clipboard
                if (WifiMonitor.ipAddress) {
                    clipboardHelper.text = WifiMonitor.ipAddress;
                    clipboardHelper.selectAll();
                    clipboardHelper.copy();
                }
            }
        }
    ]

    // Hidden TextEdit for clipboard operations
    TextEdit {
        id: clipboardHelper
        visible: false
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

            PlasmaComponents3.Label {
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

            PlasmaComponents3.Label {
                visible: root.isConnected
                text: i18n("%1 dBm", WifiMonitor.signalDbm)
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.75
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    fullRepresentation: FullRepresentation {}
}
