#pragma once

#include <cstdint>
#include <QString>

struct Nl80211StationInfo {
    bool valid = false;
    
    int32_t signalDbm = 0;
    int32_t signalAvgDbm = 0;
    
    uint32_t txBitrate = 0;  // in 100 kbit/s
    uint32_t rxBitrate = 0;
    
    uint8_t txMcs = 0;
    uint8_t rxMcs = 0;
    
    uint8_t txNss = 0;  // MIMO spatial streams
    uint8_t rxNss = 0;
    
    uint8_t txChannelWidth = 0;  // 0=20, 1=40, 2=80, 3=160, 4=80+80
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
