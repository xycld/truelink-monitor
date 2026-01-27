#pragma once

#include <cstdint>
#include <QString>

struct Nl80211StationInfo {
    bool valid = false;
    
    // Signal strength
    int32_t signalDbm = 0;
    int32_t signalAvgDbm = 0;
    
    // Bitrate (in 100 kbit/s)
    uint32_t txBitrate = 0;
    uint32_t rxBitrate = 0;
    
    // MCS index
    uint8_t txMcs = 0;
    uint8_t rxMcs = 0;
    
    // MIMO spatial streams
    uint8_t txNss = 0;
    uint8_t rxNss = 0;
    
    // Channel width: 0=20, 1=40, 2=80, 3=160, 4=80+80, 5=320
    uint8_t txChannelWidth = 0;
    uint8_t rxChannelWidth = 0;
    
    enum class WifiMode : uint8_t {
        Unknown = 0,
        HT,      // WiFi 4 (802.11n)
        VHT,     // WiFi 5 (802.11ac)
        HE,      // WiFi 6 (802.11ax)
        EHT      // WiFi 7 (802.11be)
    };
    
    WifiMode txMode = WifiMode::Unknown;
    WifiMode rxMode = WifiMode::Unknown;
    
    // Traffic statistics
    uint64_t rxBytes = 0;
    uint64_t txBytes = 0;
    uint32_t rxPackets = 0;
    uint32_t txPackets = 0;
    
    // Link quality indicators
    uint32_t txRetries = 0;
    uint32_t txFailed = 0;
    uint32_t rxDropMisc = 0;
    uint32_t beaconLoss = 0;
    uint64_t beaconRx = 0;
    int32_t beaconSignalAvg = 0;
    uint32_t fcsErrorCount = 0;
    
    // Connection info
    uint32_t connectedTime = 0;    // seconds
    uint32_t inactiveTime = 0;     // milliseconds
    uint32_t expectedThroughput = 0;  // kbps
    
    // ACK signal (bidirectional link quality)
    int32_t ackSignal = 0;
    int32_t ackSignalAvg = 0;
    bool hasAckSignal = false;
    
    // Airtime
    uint64_t rxDuration = 0;  // microseconds
    uint64_t txDuration = 0;
};

class Nl80211Helper {
public:
    Nl80211Helper();
    ~Nl80211Helper();
    
    Nl80211Helper(const Nl80211Helper&) = delete;
    Nl80211Helper& operator=(const Nl80211Helper&) = delete;
    
    bool init();
    void cleanup();
    
    [[nodiscard]] bool isValid() const;
    [[nodiscard]] Nl80211StationInfo getStationInfo(const char* ifname, const uint8_t* bssid = nullptr);
    [[nodiscard]] QString lastError() const;
    
    static int channelWidthToMhz(uint8_t width);
    static const char* wifiModeToString(Nl80211StationInfo::WifiMode mode);
    static const char* wifiModeToGeneration(Nl80211StationInfo::WifiMode mode);

private:
    struct nl_sock* m_socket = nullptr;
    int m_nl80211Id = -1;
    QString m_lastError;
};
