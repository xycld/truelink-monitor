#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QVariantList>

/**
 * @brief WiFi physical layer data exposed to QML
 *
 * This class aggregates data from NetworkManager-Qt (connection info)
 * and nl80211 (PHY layer details like dBm, MCS, MIMO).
 */
class WifiMonitor : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    // Connection state
    Q_PROPERTY(bool connected READ connected NOTIFY connectionChanged)
    Q_PROPERTY(bool available READ available NOTIFY availabilityChanged)
    Q_PROPERTY(QString ssid READ ssid NOTIFY connectionChanged)
    Q_PROPERTY(QString bssid READ bssid NOTIFY connectionChanged)

    // Signal strength
    Q_PROPERTY(int signalDbm READ signalDbm NOTIFY statsUpdated)
    Q_PROPERTY(int signalPercent READ signalPercent NOTIFY statsUpdated)
    Q_PROPERTY(QString signalQuality READ signalQuality NOTIFY statsUpdated)

    // PHY Rate
    Q_PROPERTY(double txRate READ txRate NOTIFY statsUpdated)
    Q_PROPERTY(double rxRate READ rxRate NOTIFY statsUpdated)

    // 802.11 Protocol details
    Q_PROPERTY(QString wifiGeneration READ wifiGeneration NOTIFY statsUpdated)
    Q_PROPERTY(int mcsIndex READ mcsIndex NOTIFY statsUpdated)
    Q_PROPERTY(int mimoStreams READ mimoStreams NOTIFY statsUpdated)
    Q_PROPERTY(int channelWidth READ channelWidth NOTIFY statsUpdated)

    // Frequency/Channel
    Q_PROPERTY(int frequency READ frequency NOTIFY connectionChanged)
    Q_PROPERTY(int channel READ channel NOTIFY connectionChanged)

    // Security
    Q_PROPERTY(QString security READ security NOTIFY connectionChanged)

    // IP Info
    Q_PROPERTY(QString ipAddress READ ipAddress NOTIFY connectionChanged)
    Q_PROPERTY(QString gateway READ gateway NOTIFY connectionChanged)

    Q_PROPERTY(QString statusColor READ statusColor NOTIFY statsUpdated)

    Q_PROPERTY(QVariantList rxHistory READ rxHistory NOTIFY statsUpdated)
    Q_PROPERTY(QVariantList txHistory READ txHistory NOTIFY statsUpdated)
    Q_PROPERTY(double maxHistoryRate READ maxHistoryRate NOTIFY statsUpdated)

    // Constants used by the UI.
    Q_PROPERTY(int historySize READ historySize CONSTANT)
    Q_PROPERTY(int updateIntervalMs READ updateIntervalMs CONSTANT)

    // Last nl80211-related error seen by the monitor (empty when healthy).
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

    Q_PROPERTY(qulonglong rxBytes READ rxBytes NOTIFY statsUpdated)
    Q_PROPERTY(qulonglong txBytes READ txBytes NOTIFY statsUpdated)
    Q_PROPERTY(quint32 rxPackets READ rxPackets NOTIFY statsUpdated)
    Q_PROPERTY(quint32 txPackets READ txPackets NOTIFY statsUpdated)

    Q_PROPERTY(quint32 txRetries READ txRetries NOTIFY statsUpdated)
    Q_PROPERTY(quint32 txFailed READ txFailed NOTIFY statsUpdated)
    Q_PROPERTY(quint32 rxDropped READ rxDropped NOTIFY statsUpdated)
    Q_PROPERTY(quint32 beaconLoss READ beaconLoss NOTIFY statsUpdated)
    Q_PROPERTY(qulonglong beaconRx READ beaconRx NOTIFY statsUpdated)
    Q_PROPERTY(int beaconSignalAvg READ beaconSignalAvg NOTIFY statsUpdated)

    Q_PROPERTY(quint32 connectedTime READ connectedTime NOTIFY statsUpdated)
    Q_PROPERTY(quint32 inactiveTime READ inactiveTime NOTIFY statsUpdated)
    Q_PROPERTY(quint32 expectedThroughput READ expectedThroughput NOTIFY statsUpdated)

    Q_PROPERTY(int ackSignal READ ackSignal NOTIFY statsUpdated)
    Q_PROPERTY(int ackSignalAvg READ ackSignalAvg NOTIFY statsUpdated)
    Q_PROPERTY(bool hasAckSignal READ hasAckSignal NOTIFY statsUpdated)

    Q_PROPERTY(qulonglong rxDuration READ rxDuration NOTIFY statsUpdated)
    Q_PROPERTY(qulonglong txDuration READ txDuration NOTIFY statsUpdated)

public:
    explicit WifiMonitor(QObject *parent = nullptr);
    ~WifiMonitor() override;

    // Connection state
    [[nodiscard]] bool connected() const;
    [[nodiscard]] bool available() const;
    [[nodiscard]] QString ssid() const;
    [[nodiscard]] QString bssid() const;

    // Signal
    [[nodiscard]] int signalDbm() const;
    [[nodiscard]] int signalPercent() const;
    [[nodiscard]] QString signalQuality() const;

    // PHY Rate
    [[nodiscard]] double txRate() const;
    [[nodiscard]] double rxRate() const;

    // Protocol
    [[nodiscard]] QString wifiGeneration() const;
    [[nodiscard]] int mcsIndex() const;
    [[nodiscard]] int mimoStreams() const;
    [[nodiscard]] int channelWidth() const;

    // Frequency
    [[nodiscard]] int frequency() const;
    [[nodiscard]] int channel() const;

    // Security & IP
    [[nodiscard]] QString security() const;
    [[nodiscard]] QString ipAddress() const;
    [[nodiscard]] QString gateway() const;

    // UI Helper
    [[nodiscard]] QString statusColor() const;

    [[nodiscard]] QVariantList rxHistory() const;
    [[nodiscard]] QVariantList txHistory() const;
    [[nodiscard]] double maxHistoryRate() const;

    [[nodiscard]] int historySize() const;
    [[nodiscard]] int updateIntervalMs() const;
    [[nodiscard]] QString lastError() const;

    [[nodiscard]] qulonglong rxBytes() const;
    [[nodiscard]] qulonglong txBytes() const;
    [[nodiscard]] quint32 rxPackets() const;
    [[nodiscard]] quint32 txPackets() const;

    [[nodiscard]] quint32 txRetries() const;
    [[nodiscard]] quint32 txFailed() const;
    [[nodiscard]] quint32 rxDropped() const;
    [[nodiscard]] quint32 beaconLoss() const;
    [[nodiscard]] qulonglong beaconRx() const;
    [[nodiscard]] int beaconSignalAvg() const;

    [[nodiscard]] quint32 connectedTime() const;
    [[nodiscard]] quint32 inactiveTime() const;
    [[nodiscard]] quint32 expectedThroughput() const;

    [[nodiscard]] int ackSignal() const;
    [[nodiscard]] int ackSignalAvg() const;
    [[nodiscard]] bool hasAckSignal() const;

    [[nodiscard]] qulonglong rxDuration() const;
    [[nodiscard]] qulonglong txDuration() const;

Q_SIGNALS:
    void connectionChanged();
    void availabilityChanged();
    void statsUpdated();
    void errorOccurred(const QString &message);
    void lastErrorChanged();

private Q_SLOTS:
    void onActiveConnectionChanged();
    void onDeviceStateChanged();
    void updateNl80211Stats();

private:
    void initNetworkManager();
    void initNl80211();
    void startStatsTimer();
    void stopStatsTimer();

    class Private;
    QScopedPointer<Private> d;
};
