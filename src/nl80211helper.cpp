#include "nl80211helper.h"

#include <netlink/netlink.h>
#include <netlink/genl/genl.h>
#include <netlink/genl/ctrl.h>
#include <linux/nl80211.h>
#include <net/if.h>
#include <cstring>
#include <cerrno>
#include <QDebug>

namespace {

struct CallbackData {
    Nl80211StationInfo* info = nullptr;
    int errorCode = 0;
    bool partialParse = false;
};

int parseRateInfo(struct nlattr* rateAttr, uint32_t& bitrate, uint8_t& mcs, 
                  uint8_t& nss, uint8_t& width, Nl80211StationInfo::WifiMode& mode) {
    struct nlattr* rateInfo[NL80211_RATE_INFO_MAX + 1] = {};
    
    if (nla_parse_nested(rateInfo, NL80211_RATE_INFO_MAX, rateAttr, nullptr) < 0) {
        return -1;
    }
    
    if (rateInfo[NL80211_RATE_INFO_BITRATE32]) {
        bitrate = nla_get_u32(rateInfo[NL80211_RATE_INFO_BITRATE32]);
    } else if (rateInfo[NL80211_RATE_INFO_BITRATE]) {
        bitrate = nla_get_u16(rateInfo[NL80211_RATE_INFO_BITRATE]);
    }
    
    if (rateInfo[NL80211_RATE_INFO_EHT_MCS]) {
        mcs = nla_get_u8(rateInfo[NL80211_RATE_INFO_EHT_MCS]);
        mode = Nl80211StationInfo::WifiMode::EHT;
        if (rateInfo[NL80211_RATE_INFO_EHT_NSS]) {
            nss = nla_get_u8(rateInfo[NL80211_RATE_INFO_EHT_NSS]);
        }
    } else if (rateInfo[NL80211_RATE_INFO_HE_MCS]) {
        mcs = nla_get_u8(rateInfo[NL80211_RATE_INFO_HE_MCS]);
        mode = Nl80211StationInfo::WifiMode::HE;
        if (rateInfo[NL80211_RATE_INFO_HE_NSS]) {
            nss = nla_get_u8(rateInfo[NL80211_RATE_INFO_HE_NSS]);
        }
    } else if (rateInfo[NL80211_RATE_INFO_VHT_MCS]) {
        mcs = nla_get_u8(rateInfo[NL80211_RATE_INFO_VHT_MCS]);
        mode = Nl80211StationInfo::WifiMode::VHT;
        if (rateInfo[NL80211_RATE_INFO_VHT_NSS]) {
            nss = nla_get_u8(rateInfo[NL80211_RATE_INFO_VHT_NSS]);
        }
    } else if (rateInfo[NL80211_RATE_INFO_MCS]) {
        mcs = nla_get_u8(rateInfo[NL80211_RATE_INFO_MCS]);
        mode = Nl80211StationInfo::WifiMode::HT;
        nss = (mcs / 8) + 1;
    }
    
    if (rateInfo[NL80211_RATE_INFO_320_MHZ_WIDTH]) {
        width = 5;
    } else if (rateInfo[NL80211_RATE_INFO_160_MHZ_WIDTH]) {
        width = 3;
    } else if (rateInfo[NL80211_RATE_INFO_80P80_MHZ_WIDTH]) {
        width = 4;
    } else if (rateInfo[NL80211_RATE_INFO_80_MHZ_WIDTH]) {
        width = 2;
    } else if (rateInfo[NL80211_RATE_INFO_40_MHZ_WIDTH]) {
        width = 1;
    } else {
        width = 0;
    }
    
    return 0;
}

int stationInfoCallback(struct nl_msg* msg, void* arg) {
    auto* data = static_cast<CallbackData*>(arg);
    if (!data || !data->info) return NL_SKIP;
    
    struct nlattr* tb[NL80211_ATTR_MAX + 1] = {};
    struct genlmsghdr* gnlh = static_cast<genlmsghdr*>(nlmsg_data(nlmsg_hdr(msg)));
    
    if (nla_parse(tb, NL80211_ATTR_MAX, genlmsg_attrdata(gnlh, 0),
                  genlmsg_attrlen(gnlh, 0), nullptr) < 0) {
        return NL_SKIP;
    }
    
    if (!tb[NL80211_ATTR_STA_INFO]) {
        return NL_SKIP;
    }
    
    struct nlattr* sinfo[NL80211_STA_INFO_MAX + 1];
    if (nla_parse_nested(sinfo, NL80211_STA_INFO_MAX, tb[NL80211_ATTR_STA_INFO], nullptr) < 0) {
        return NL_SKIP;
    }
    
    auto& info = *data->info;
    info.valid = true;
    
    if (sinfo[NL80211_STA_INFO_SIGNAL]) {
        info.signalDbm = static_cast<int8_t>(nla_get_u8(sinfo[NL80211_STA_INFO_SIGNAL]));
    }
    
    if (sinfo[NL80211_STA_INFO_SIGNAL_AVG]) {
        info.signalAvgDbm = static_cast<int8_t>(nla_get_u8(sinfo[NL80211_STA_INFO_SIGNAL_AVG]));
    }
    
    if (sinfo[NL80211_STA_INFO_TX_BITRATE]) {
        if (parseRateInfo(sinfo[NL80211_STA_INFO_TX_BITRATE],
                          info.txBitrate, info.txMcs, info.txNss, info.txChannelWidth, info.txMode) < 0) {
            info.txBitrate = 0;
            info.txMcs = 0;
            info.txNss = 0;
            info.txChannelWidth = 0;
            info.txMode = Nl80211StationInfo::WifiMode::Unknown;
            data->partialParse = true;
        }
    }
    
    if (sinfo[NL80211_STA_INFO_RX_BITRATE]) {
        if (parseRateInfo(sinfo[NL80211_STA_INFO_RX_BITRATE],
                          info.rxBitrate, info.rxMcs, info.rxNss, info.rxChannelWidth, info.rxMode) < 0) {
            info.rxBitrate = 0;
            info.rxMcs = 0;
            info.rxNss = 0;
            info.rxChannelWidth = 0;
            info.rxMode = Nl80211StationInfo::WifiMode::Unknown;
            data->partialParse = true;
        }
    }
    
    return NL_OK;
}

}  // namespace

Nl80211Helper::Nl80211Helper() = default;

Nl80211Helper::~Nl80211Helper() {
    cleanup();
}

bool Nl80211Helper::init() {
    m_socket = nl_socket_alloc();
    if (!m_socket) {
        return false;
    }
    
    if (genl_connect(m_socket) < 0) {
        cleanup();
        return false;
    }
    
    m_nl80211Id = genl_ctrl_resolve(m_socket, "nl80211");
    if (m_nl80211Id < 0) {
        cleanup();
        return false;
    }
    
    // Disable sequence number checking to allow socket reuse across multiple queries.
    // Without this, residual messages in the socket buffer cause NLE_SEQ_MISMATCH errors.
    nl_socket_disable_seq_check(m_socket);
    
    return true;
}

void Nl80211Helper::cleanup() {
    if (m_socket) {
        nl_socket_free(m_socket);
        m_socket = nullptr;
    }
    m_nl80211Id = -1;
}

bool Nl80211Helper::isValid() const {
    return m_socket != nullptr && m_nl80211Id >= 0;
}

Nl80211StationInfo Nl80211Helper::getStationInfo(const char* ifname, const uint8_t* bssid) {
    static int queryCount = 0;
    ++queryCount;
    qDebug() << "[nl80211] getStationInfo called, query #" << queryCount 
             << "ifname:" << (ifname ? ifname : "null")
             << "bssid:" << (bssid ? "provided" : "null");
    
    Nl80211StationInfo result;
    m_lastError.clear();
    
    if (!ifname) {
        m_lastError = QStringLiteral("No interface name provided");
        qWarning() << "[nl80211] ERROR:" << m_lastError;
        return result;
    }
    
    unsigned int ifindex = if_nametoindex(ifname);
    if (ifindex == 0) {
        m_lastError = QStringLiteral("Interface not found: %1").arg(QString::fromUtf8(ifname));
        qWarning() << "[nl80211] ERROR:" << m_lastError;
        return result;
    }
    
    struct nl_sock* sock = nl_socket_alloc();
    if (!sock) {
        m_lastError = QStringLiteral("Failed to allocate netlink socket");
        qWarning() << "[nl80211] ERROR:" << m_lastError;
        return result;
    }
    
    if (genl_connect(sock) < 0) {
        m_lastError = QStringLiteral("Failed to connect netlink socket");
        qWarning() << "[nl80211] ERROR:" << m_lastError;
        nl_socket_free(sock);
        return result;
    }
    
    int nl80211Id = genl_ctrl_resolve(sock, "nl80211");
    if (nl80211Id < 0) {
        m_lastError = QStringLiteral("Failed to resolve nl80211");
        qWarning() << "[nl80211] ERROR:" << m_lastError;
        nl_socket_free(sock);
        return result;
    }
    
    struct nl_msg* msg = nlmsg_alloc();
    if (!msg) {
        m_lastError = QStringLiteral("Failed to allocate netlink message");
        qWarning() << "[nl80211] ERROR:" << m_lastError;
        nl_socket_free(sock);
        return result;
    }
    
    int flags = bssid ? 0 : NLM_F_DUMP;
    qDebug() << "[nl80211] Using flags:" << flags << (bssid ? "(single station)" : "(DUMP mode)");
    
    if (!genlmsg_put(msg, 0, 0, nl80211Id, 0, flags, NL80211_CMD_GET_STATION, 0)) {
        m_lastError = QStringLiteral("Failed to create netlink message");
        qWarning() << "[nl80211] ERROR:" << m_lastError;
        nlmsg_free(msg);
        nl_socket_free(sock);
        return result;
    }
    
    if (nla_put_u32(msg, NL80211_ATTR_IFINDEX, ifindex) < 0) {
        m_lastError = QStringLiteral("Failed to set interface index");
        qWarning() << "[nl80211] ERROR:" << m_lastError;
        nlmsg_free(msg);
        nl_socket_free(sock);
        return result;
    }
    
    if (bssid) {
        if (nla_put(msg, NL80211_ATTR_MAC, 6, bssid) < 0) {
            m_lastError = QStringLiteral("Failed to set BSSID");
            qWarning() << "[nl80211] ERROR:" << m_lastError;
            nlmsg_free(msg);
            nl_socket_free(sock);
            return result;
        }
    }
    
    CallbackData cbData;
    cbData.info = &result;
    cbData.errorCode = 0;
    
    struct nl_cb* cb = nl_cb_alloc(NL_CB_DEFAULT);
    if (!cb) {
        m_lastError = QStringLiteral("Failed to allocate callback");
        qWarning() << "[nl80211] ERROR:" << m_lastError;
        nlmsg_free(msg);
        nl_socket_free(sock);
        return result;
    }
    
    nl_cb_set(cb, NL_CB_VALID, NL_CB_CUSTOM, stationInfoCallback, &cbData);
    nl_cb_set(cb, NL_CB_ACK, NL_CB_CUSTOM, [](struct nl_msg*, void*) -> int { 
        return NL_STOP; 
    }, nullptr);
    nl_cb_set(cb, NL_CB_FINISH, NL_CB_CUSTOM, [](struct nl_msg*, void*) -> int { 
        return NL_STOP; 
    }, nullptr);
    nl_cb_err(cb, NL_CB_CUSTOM, [](struct sockaddr_nl*, struct nlmsgerr* err, void* arg) -> int {
        auto* data = static_cast<CallbackData*>(arg);
        if (data && err) {
            data->errorCode = err->error;
        }
        return NL_STOP;
    }, &cbData);
    
    qDebug() << "[nl80211] Sending netlink message...";
    int ret = nl_send_auto(sock, msg);
    if (ret < 0) {
        m_lastError = QStringLiteral("Failed to send netlink message: %1").arg(QString::fromUtf8(nl_geterror(ret)));
        qWarning() << "[nl80211] ERROR:" << m_lastError;
        nl_cb_put(cb);
        nlmsg_free(msg);
        nl_socket_free(sock);
        return result;
    }
    qDebug() << "[nl80211] Message sent, bytes:" << ret << "- waiting for response...";
    
    ret = nl_recvmsgs(sock, cb);
    qDebug() << "[nl80211] nl_recvmsgs returned:" << ret 
             << "cbData.errorCode:" << cbData.errorCode
             << "result.valid:" << result.valid;
    
    if (ret < 0) {
        if (ret == -NLE_PERM || cbData.errorCode == -EPERM) {
            m_lastError = QStringLiteral("Permission denied - may need CAP_NET_ADMIN");
        } else {
            m_lastError = QStringLiteral("Failed to receive netlink response: %1").arg(QString::fromUtf8(nl_geterror(ret)));
        }
        qWarning() << "[nl80211] ERROR:" << m_lastError;
    } else if (cbData.errorCode < 0) {
        if (cbData.errorCode == -EPERM) {
            m_lastError = QStringLiteral("Permission denied - may need CAP_NET_ADMIN");
        } else {
            m_lastError = QStringLiteral("Kernel error: %1").arg(cbData.errorCode);
        }
        qWarning() << "[nl80211] ERROR:" << m_lastError;
    }

    if (result.valid && cbData.partialParse && m_lastError.isEmpty()) {
        m_lastError = QStringLiteral("Incomplete station info (failed to parse rate fields)");
        qWarning() << "[nl80211] WARNING:" << m_lastError;
    }
    
    if (result.valid) {
        qDebug() << "[nl80211] SUCCESS - signal:" << result.signalDbm << "dBm"
                 << "rxBitrate:" << result.rxBitrate / 10.0 << "Mbps"
                 << "txBitrate:" << result.txBitrate / 10.0 << "Mbps";
    }
    
    nl_cb_put(cb);
    nlmsg_free(msg);
    nl_socket_free(sock);
    
    qDebug() << "[nl80211] getStationInfo completed, query #" << queryCount;
    return result;
}

QString Nl80211Helper::lastError() const {
    return m_lastError;
}

int Nl80211Helper::channelWidthToMhz(uint8_t width) {
    switch (width) {
        case 0: return 20;
        case 1: return 40;
        case 2: return 80;
        case 3: return 160;
        case 4: return 160;  // 80+80
        case 5: return 320;
        default: return 20;
    }
}

const char* Nl80211Helper::wifiModeToString(Nl80211StationInfo::WifiMode mode) {
    switch (mode) {
        case Nl80211StationInfo::WifiMode::HT:  return "HT";
        case Nl80211StationInfo::WifiMode::VHT: return "VHT";
        case Nl80211StationInfo::WifiMode::HE:  return "HE";
        case Nl80211StationInfo::WifiMode::EHT: return "EHT";
        default: return "Legacy";
    }
}

const char* Nl80211Helper::wifiModeToGeneration(Nl80211StationInfo::WifiMode mode) {
    switch (mode) {
        case Nl80211StationInfo::WifiMode::HT:  return "WiFi 4";
        case Nl80211StationInfo::WifiMode::VHT: return "WiFi 5";
        case Nl80211StationInfo::WifiMode::HE:  return "WiFi 6";
        case Nl80211StationInfo::WifiMode::EHT: return "WiFi 7";
        default: return "Legacy";
    }
}
