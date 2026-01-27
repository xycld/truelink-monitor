#include "wifimonitor.h"
#include "nl80211helper.h"

#include <KLocalizedString>
#include <QByteArray>
#include <QTimer>
#include <QVector>
#include <QtGlobal>
#include <QStringList>
#include <NetworkManagerQt/Manager>
#include <NetworkManagerQt/WirelessDevice>
#include <NetworkManagerQt/AccessPoint>
#include <NetworkManagerQt/ActiveConnection>
#include <NetworkManagerQt/IpConfig>

namespace {
QByteArray parseBssidBytes(const QString &bssidText)
{
    if (bssidText.isEmpty()) {
        return {};
    }

    const QStringList parts = bssidText.split(QLatin1Char(':'));
    if (parts.size() != 6) {
        return {};
    }

    QByteArray out;
    out.reserve(6);

    for (const QString &part : parts) {
        bool ok = false;
        const int value = part.toInt(&ok, 16);
        if (!ok || value < 0 || value > 255) {
            return {};
        }

        const quint8 byte = static_cast<quint8>(value);
        out.append(static_cast<char>(byte));
    }

    return out;
}
} // namespace

class WifiMonitor::Private {
public:
    NetworkManager::WirelessDevice::Ptr wirelessDevice;
    NetworkManager::AccessPoint::Ptr accessPoint;
    NetworkManager::ActiveConnection::Ptr activeConnection;
    
    Nl80211Helper nl80211;
    Nl80211StationInfo stationInfo;
    
    QTimer* statsTimer = nullptr;
    QString interfaceName;
    
    bool isConnected = false;
    bool isAvailable = false;
    
    QString cachedSsid;
    QString cachedBssid;
    int cachedFrequency = 0;
    int cachedChannelWidth = 0;
    QString cachedSecurity;
    QString cachedIpAddress;
    QString cachedGateway;

    QString lastError;
    
    double smoothedTxRate = 0.0;
    double smoothedRxRate = 0.0;
    static constexpr double smoothingFactor = 0.3;

    static constexpr int updateIntervalMs = 1000;
    
    static constexpr int historySize = 60;
    QVector<double> rxHistoryBuffer;
    QVector<double> txHistoryBuffer;
    double maxRate = 100.0;
    
    void addToHistory(double rx, double tx) {
        rxHistoryBuffer.append(rx);
        txHistoryBuffer.append(tx);
        if (rxHistoryBuffer.size() > historySize) {
            rxHistoryBuffer.removeFirst();
            txHistoryBuffer.removeFirst();
        }
        maxRate = 100.0;
        for (double v : rxHistoryBuffer) maxRate = qMax(maxRate, v);
        for (double v : txHistoryBuffer) maxRate = qMax(maxRate, v);
    }

    void resetStats() {
        stationInfo = Nl80211StationInfo{};
        smoothedTxRate = 0.0;
        smoothedRxRate = 0.0;
        rxHistoryBuffer.clear();
        txHistoryBuffer.clear();
        maxRate = 100.0;
        lastError.clear();
    }
};

WifiMonitor::WifiMonitor(QObject *parent)
    : QObject(parent)
    , d(new Private)
{
    initNetworkManager();
    initNl80211();
}

WifiMonitor::~WifiMonitor() = default;

void WifiMonitor::initNetworkManager() {
    connect(NetworkManager::notifier(), &NetworkManager::Notifier::primaryConnectionChanged,
            this, &WifiMonitor::onActiveConnectionChanged);
    connect(NetworkManager::notifier(), &NetworkManager::Notifier::wirelessEnabledChanged,
            this, &WifiMonitor::onDeviceStateChanged);
    
    for (const auto& device : NetworkManager::networkInterfaces()) {
        if (device->type() == NetworkManager::Device::Wifi) {
            d->wirelessDevice = device.objectCast<NetworkManager::WirelessDevice>();
            d->interfaceName = device->interfaceName();
            d->isAvailable = true;
            
            connect(d->wirelessDevice.data(), &NetworkManager::WirelessDevice::activeAccessPointChanged,
                    this, &WifiMonitor::onActiveConnectionChanged);
            connect(d->wirelessDevice.data(), &NetworkManager::Device::stateChanged,
                    this, &WifiMonitor::onDeviceStateChanged);
            break;
        }
    }
    
    onActiveConnectionChanged();
}

void WifiMonitor::initNl80211() {
    if (!d->nl80211.init()) {
        d->lastError = i18n("Failed to initialize nl80211");
        Q_EMIT lastErrorChanged();
        Q_EMIT errorOccurred(d->lastError);
    }
}

void WifiMonitor::startStatsTimer() {
    if (!d->statsTimer) {
        d->statsTimer = new QTimer(this);
        d->statsTimer->setInterval(Private::updateIntervalMs);
        connect(d->statsTimer, &QTimer::timeout, this, &WifiMonitor::updateNl80211Stats);
    }
    d->statsTimer->start();
    updateNl80211Stats();
}

void WifiMonitor::stopStatsTimer() {
    if (d->statsTimer) {
        d->statsTimer->stop();
    }
}

void WifiMonitor::onActiveConnectionChanged() {
    if (!d->wirelessDevice) {
        d->isConnected = false;
        d->cachedSsid.clear();
        d->cachedBssid.clear();
        d->cachedSecurity.clear();
        d->cachedFrequency = 0;
        d->cachedChannelWidth = 0;
        d->cachedIpAddress.clear();
        d->cachedGateway.clear();
        const bool hadError = !d->lastError.isEmpty();
        d->resetStats();
        if (hadError) {
            Q_EMIT lastErrorChanged();
        }
        stopStatsTimer();
        Q_EMIT connectionChanged();
        return;
    }
    
    d->accessPoint = d->wirelessDevice->activeAccessPoint();
    
    if (!d->accessPoint) {
        d->isConnected = false;
        d->cachedSsid.clear();
        d->cachedBssid.clear();
        d->cachedSecurity.clear();
        d->cachedFrequency = 0;
        d->cachedChannelWidth = 0;
        d->cachedIpAddress.clear();
        d->cachedGateway.clear();
        const bool hadError = !d->lastError.isEmpty();
        d->resetStats();
        if (hadError) {
            Q_EMIT lastErrorChanged();
        }
        stopStatsTimer();
        Q_EMIT connectionChanged();
        return;
    }
    
    d->isConnected = true;
    d->cachedSsid = d->accessPoint->ssid();
    d->cachedBssid = d->accessPoint->hardwareAddress();
    d->cachedFrequency = d->accessPoint->frequency();
    d->cachedChannelWidth = d->accessPoint->bandwidth();
    
    auto flags = d->accessPoint->rsnFlags();
    if (flags & NetworkManager::AccessPoint::PairCcmp) {
        d->cachedSecurity = QStringLiteral("WPA2/WPA3");
    } else if (flags & NetworkManager::AccessPoint::PairTkip) {
        d->cachedSecurity = QStringLiteral("WPA");
    } else if (d->accessPoint->wpaFlags() != NetworkManager::AccessPoint::None) {
        d->cachedSecurity = QStringLiteral("WPA");
    } else {
        d->cachedSecurity = i18nc("WiFi security", "Open");
    }
    
    auto activeConn = d->wirelessDevice->activeConnection();
    if (activeConn) {
        auto devices = activeConn->devices();
        if (!devices.isEmpty()) {
            auto dev = NetworkManager::findNetworkInterface(devices.first());
            if (dev) {
                auto ipv4 = dev->ipV4Config();
                if (ipv4.isValid() && !ipv4.addresses().isEmpty()) {
                    d->cachedIpAddress = ipv4.addresses().first().ip().toString();
                    d->cachedGateway = ipv4.gateway();
                } else {
                    d->cachedIpAddress.clear();
                    d->cachedGateway.clear();
                }
            }
        }
    }
    
    startStatsTimer();
    Q_EMIT connectionChanged();
}

void WifiMonitor::onDeviceStateChanged() {
    bool wasAvailable = d->isAvailable;
    d->isAvailable = d->wirelessDevice && NetworkManager::isWirelessEnabled();
    
    if (wasAvailable != d->isAvailable) {
        Q_EMIT availabilityChanged();
    }
    
    onActiveConnectionChanged();
}

void WifiMonitor::updateNl80211Stats() {
    if (!d->isConnected || d->interfaceName.isEmpty()) {
        return;
    }
    
    const QByteArray bssidBytes = parseBssidBytes(d->cachedBssid);
    if (!d->cachedBssid.isEmpty() && bssidBytes.isEmpty()) {
        const QString error = i18n("Invalid BSSID format: %1", d->cachedBssid);
        if (error != d->lastError) {
            d->lastError = error;
            Q_EMIT lastErrorChanged();
            Q_EMIT errorOccurred(error);
        }
        return;
    }
    
    const uint8_t* bssidPtr = bssidBytes.size() == 6 
        ? reinterpret_cast<const uint8_t*>(bssidBytes.constData()) 
        : nullptr;
    
    Nl80211StationInfo newInfo = d->nl80211.getStationInfo(d->interfaceName.toUtf8().constData(), bssidPtr);
    
    if (newInfo.valid) {
        if (!d->lastError.isEmpty()) {
            d->lastError.clear();
            Q_EMIT lastErrorChanged();
        }

        d->stationInfo = newInfo;
        
        double newTx = newInfo.txBitrate / 10.0;
        double newRx = newInfo.rxBitrate / 10.0;
        
        if (d->smoothedTxRate == 0.0) {
            d->smoothedTxRate = newTx;
            d->smoothedRxRate = newRx;
        } else {
            d->smoothedTxRate = d->smoothingFactor * newTx + (1.0 - d->smoothingFactor) * d->smoothedTxRate;
            d->smoothedRxRate = d->smoothingFactor * newRx + (1.0 - d->smoothingFactor) * d->smoothedRxRate;
        }
        d->addToHistory(d->smoothedRxRate, d->smoothedTxRate);
    } else {
        const QString error = d->nl80211.lastError();
        if (error != d->lastError) {
            d->lastError = error;
            Q_EMIT lastErrorChanged();

            if (!error.isEmpty()) {
                Q_EMIT errorOccurred(error);
            }
        }
    }
    
    Q_EMIT statsUpdated();
}

bool WifiMonitor::connected() const { return d->isConnected; }
bool WifiMonitor::available() const { return d->isAvailable; }
QString WifiMonitor::ssid() const { return d->cachedSsid; }
QString WifiMonitor::bssid() const { return d->cachedBssid; }

int WifiMonitor::signalDbm() const {
    return d->stationInfo.signalDbm;
}

int WifiMonitor::signalPercent() const {
    if (!d->stationInfo.valid) return 0;
    int dbm = d->stationInfo.signalDbm;
    if (dbm >= -50) return 100;
    if (dbm <= -100) return 0;
    return 2 * (dbm + 100);
}

QString WifiMonitor::signalQuality() const {
    int dbm = signalDbm();
    if (dbm >= -50) return i18nc("WiFi signal quality", "Excellent");
    if (dbm >= -60) return i18nc("WiFi signal quality", "Good");
    if (dbm >= -70) return i18nc("WiFi signal quality", "Fair");
    if (dbm >= -80) return i18nc("WiFi signal quality", "Weak");
    return i18nc("WiFi signal quality", "Poor");
}

double WifiMonitor::txRate() const {
    return d->stationInfo.txBitrate / 10.0;
}

double WifiMonitor::rxRate() const {
    return d->stationInfo.rxBitrate / 10.0;
}

QString WifiMonitor::wifiGeneration() const {
    if (!d->stationInfo.valid) {
        return i18nc("WiFi generation", "Unknown");
    }

    const auto mode = d->stationInfo.rxMode != Nl80211StationInfo::WifiMode::Unknown
        ? d->stationInfo.rxMode
        : d->stationInfo.txMode;

    switch (mode) {
        case Nl80211StationInfo::WifiMode::HT:  return i18nc("WiFi generation", "WiFi 4");
        case Nl80211StationInfo::WifiMode::VHT: return i18nc("WiFi generation", "WiFi 5");
        case Nl80211StationInfo::WifiMode::HE:  return i18nc("WiFi generation", "WiFi 6");
        case Nl80211StationInfo::WifiMode::EHT: return i18nc("WiFi generation", "WiFi 7");
        default:                                return i18nc("WiFi generation", "Legacy");
    }
}

int WifiMonitor::mcsIndex() const {
    return d->stationInfo.valid ? d->stationInfo.rxMcs : 0;
}

int WifiMonitor::mimoStreams() const {
    return d->stationInfo.valid ? d->stationInfo.rxNss : 0;
}

int WifiMonitor::channelWidth() const {
    if (d->stationInfo.valid && d->stationInfo.rxChannelWidth > 0) {
        return Nl80211Helper::channelWidthToMhz(d->stationInfo.rxChannelWidth);
    }
    return d->cachedChannelWidth;
}

int WifiMonitor::frequency() const { return d->cachedFrequency; }

int WifiMonitor::channel() const {
    int freq = d->cachedFrequency;
    if (freq >= 2412 && freq <= 2484) {
        if (freq == 2484) return 14;
        return (freq - 2412) / 5 + 1;
    }
    if (freq >= 5170 && freq <= 5825) {
        return (freq - 5170) / 5 + 34;
    }
    if (freq >= 5955 && freq <= 7115) {
        return (freq - 5955) / 5 + 1;
    }
    return 0;
}

QString WifiMonitor::security() const { return d->cachedSecurity; }
QString WifiMonitor::ipAddress() const { return d->cachedIpAddress; }
QString WifiMonitor::gateway() const { return d->cachedGateway; }

QString WifiMonitor::statusColor() const {
    if (!d->isConnected) return QStringLiteral("#808080");
    
    auto mode = d->stationInfo.rxMode;
    int width = channelWidth();
    int dbm = signalDbm();
    
    bool isHE = (mode == Nl80211StationInfo::WifiMode::HE || 
                 mode == Nl80211StationInfo::WifiMode::EHT);
    bool isWide = (width >= 160);
    bool strongSignal = (dbm > -60);
    
    if (isHE && isWide && strongSignal) {
        return QStringLiteral("#4CAF50");
    }
    
    bool isVHT = (mode == Nl80211StationInfo::WifiMode::VHT);
    bool mediumSignal = (dbm > -70);
    
    if ((isVHT || isHE) && mediumSignal) {
        return QStringLiteral("#FFC107");
    }
    
    return QStringLiteral("#F44336");
}

QVariantList WifiMonitor::rxHistory() const {
    QVariantList list;
    for (double v : d->rxHistoryBuffer) {
        list.append(v);
    }
    return list;
}

QVariantList WifiMonitor::txHistory() const {
    QVariantList list;
    for (double v : d->txHistoryBuffer) {
        list.append(v);
    }
    return list;
}

double WifiMonitor::maxHistoryRate() const {
    return d->maxRate;
}

int WifiMonitor::historySize() const {
    return Private::historySize;
}

int WifiMonitor::updateIntervalMs() const {
    return Private::updateIntervalMs;
}

QString WifiMonitor::lastError() const {
    return d->lastError;
}

qulonglong WifiMonitor::rxBytes() const {
    return d->stationInfo.rxBytes;
}

qulonglong WifiMonitor::txBytes() const {
    return d->stationInfo.txBytes;
}

quint32 WifiMonitor::rxPackets() const {
    return d->stationInfo.rxPackets;
}

quint32 WifiMonitor::txPackets() const {
    return d->stationInfo.txPackets;
}

quint32 WifiMonitor::txRetries() const {
    return d->stationInfo.txRetries;
}

quint32 WifiMonitor::txFailed() const {
    return d->stationInfo.txFailed;
}

quint32 WifiMonitor::rxDropped() const {
    return d->stationInfo.rxDropMisc;
}

quint32 WifiMonitor::beaconLoss() const {
    return d->stationInfo.beaconLoss;
}

qulonglong WifiMonitor::beaconRx() const {
    return d->stationInfo.beaconRx;
}

int WifiMonitor::beaconSignalAvg() const {
    return d->stationInfo.beaconSignalAvg;
}

quint32 WifiMonitor::connectedTime() const {
    return d->stationInfo.connectedTime;
}

quint32 WifiMonitor::inactiveTime() const {
    return d->stationInfo.inactiveTime;
}

quint32 WifiMonitor::expectedThroughput() const {
    return d->stationInfo.expectedThroughput;
}

int WifiMonitor::ackSignal() const {
    return d->stationInfo.ackSignal;
}

int WifiMonitor::ackSignalAvg() const {
    return d->stationInfo.ackSignalAvg;
}

bool WifiMonitor::hasAckSignal() const {
    return d->stationInfo.hasAckSignal;
}

qulonglong WifiMonitor::rxDuration() const {
    return d->stationInfo.rxDuration;
}

qulonglong WifiMonitor::txDuration() const {
    return d->stationInfo.txDuration;
}
