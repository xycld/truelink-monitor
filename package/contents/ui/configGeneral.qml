import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: root

    property alias cfg_showLinkRateChart: showLinkRateChart.checked
    property alias cfg_chartHeight: chartHeight.value
    property alias cfg_showSignalInfo: showSignalInfo.checked
    property alias cfg_showChannelInfo: showChannelInfo.checked

    property alias cfg_showRxTxRate: showRxTxRate.checked
    property alias cfg_showMcs: showMcs.checked
    property alias cfg_showMimo: showMimo.checked

    property alias cfg_showTrafficStats: showTrafficStats.checked
    property alias cfg_showLinkQuality: showLinkQuality.checked
    property alias cfg_showBeaconStats: showBeaconStats.checked

    property alias cfg_showConnectedTime: showConnectedTime.checked
    property alias cfg_showExpectedThroughput: showExpectedThroughput.checked
    property alias cfg_showIpAddress: showIpAddress.checked
    property alias cfg_showGateway: showGateway.checked
    property alias cfg_showBssid: showBssid.checked

    property alias cfg_showAckSignal: showAckSignal.checked
    property alias cfg_showAirtime: showAirtime.checked

    Kirigami.FormLayout {
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Display")
        }

        QQC2.CheckBox {
            id: showLinkRateChart
            Kirigami.FormData.label: i18n("Link rate chart:")
            text: i18n("Show RX/TX rate history graph")
        }

        QQC2.SpinBox {
            id: chartHeight
            Kirigami.FormData.label: i18n("Chart height:")
            from: 3
            to: 15
            enabled: showLinkRateChart.checked
        }

        QQC2.CheckBox {
            id: showSignalInfo
            Kirigami.FormData.label: i18n("Signal info:")
            text: i18n("Show dBm and signal quality")
        }

        QQC2.CheckBox {
            id: showChannelInfo
            Kirigami.FormData.label: i18n("Channel info:")
            text: i18n("Show channel number and width")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Rate Details")
        }

        QQC2.CheckBox {
            id: showRxTxRate
            Kirigami.FormData.label: i18n("RX/TX rate:")
            text: i18n("Show current link rates in Mbps")
        }

        QQC2.CheckBox {
            id: showMcs
            Kirigami.FormData.label: i18n("MCS index:")
            text: i18n("Show modulation coding scheme")
        }

        QQC2.CheckBox {
            id: showMimo
            Kirigami.FormData.label: i18n("MIMO streams:")
            text: i18n("Show spatial stream count")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Statistics")
        }

        QQC2.CheckBox {
            id: showTrafficStats
            Kirigami.FormData.label: i18n("Traffic stats:")
            text: i18n("Show RX/TX bytes and packets")
        }

        QQC2.CheckBox {
            id: showLinkQuality
            Kirigami.FormData.label: i18n("Link quality:")
            text: i18n("Show retries, failures, drops")
        }

        QQC2.CheckBox {
            id: showBeaconStats
            Kirigami.FormData.label: i18n("Beacon stats:")
            text: i18n("Show beacon loss and signal")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Connection")
        }

        QQC2.CheckBox {
            id: showConnectedTime
            Kirigami.FormData.label: i18n("Connected time:")
            text: i18n("Show connection duration")
        }

        QQC2.CheckBox {
            id: showExpectedThroughput
            Kirigami.FormData.label: i18n("Expected throughput:")
            text: i18n("Show estimated throughput")
        }

        QQC2.CheckBox {
            id: showIpAddress
            Kirigami.FormData.label: i18n("IP address:")
            text: i18n("Show local IP (masked by default)")
        }

        QQC2.CheckBox {
            id: showGateway
            Kirigami.FormData.label: i18n("Gateway:")
            text: i18n("Show gateway IP (masked by default)")
        }

        QQC2.CheckBox {
            id: showBssid
            Kirigami.FormData.label: i18n("BSSID:")
            text: i18n("Show AP MAC (masked by default)")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Advanced")
        }

        QQC2.CheckBox {
            id: showAckSignal
            Kirigami.FormData.label: i18n("ACK signal:")
            text: i18n("Show bidirectional link quality")
        }

        QQC2.CheckBox {
            id: showAirtime
            Kirigami.FormData.label: i18n("Airtime:")
            text: i18n("Show RX/TX duration")
        }
    }
}
