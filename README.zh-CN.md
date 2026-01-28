# TrueLink Monitor (Plasma 6)

[English](README.md) | 简体中文

TrueLink Monitor 是一个 KDE Plasma 6 小部件，通过 nl80211/libnl 直接读取 WiFi 物理层信息，实时展示无线连接质量。

## 功能特性

- 实时信号强度 (dBm) 和质量百分比
- PHY 链路速率 (RX/TX Mbps) 及历史图表
- WiFi 代际检测 (WiFi 4/5/6/6E/7)
- MCS 索引和 MIMO 空间流数
- 信道号和带宽
- 流量统计和链路质量指标
- 根据信号强度动态变化的托盘图标
- 可配置的显示选项
- 多语言支持 (英文、简体中文)

## 系统要求

- KDE Plasma 6
- Qt 6.6+
- KDE Frameworks 6 (KF6)
- NetworkManager + NetworkManagerQt (KF6)
- libnl (用于 nl80211 站点统计)

注意：部分高级 nl80211 统计信息可能需要提升权限（如 CAP_NET_ADMIN），具体取决于内核/发行版策略。

## 安装

### Arch Linux (AUR)

```bash
paru -S plasma6-applet-truelink-monitor
```

### NixOS / Nix Flake

```bash
# 从 GitHub 直接安装
nix profile install github:xycld/truelink-monitor

# 或添加到 flake.nix inputs
{
  inputs.truelink-monitor.url = "github:xycld/truelink-monitor";
}

# 然后在 configuration.nix 中
environment.systemPackages = [
  inputs.truelink-monitor.packages.${pkgs.system}.default
];
```

### 手动编译

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
```

用户安装（无需 sudo）：

```bash
cmake --install build --prefix ~/.local
```

系统安装：

```bash
sudo cmake --install build
```

安装后，重启 Plasma shell（或注销/登录），然后在编辑模式中添加小部件。

## 配置选项

右键点击小部件，选择"配置..."来自定义显示内容。

### 显示

| 选项 | 说明 | 默认 |
|------|------|------|
| **速率图表** | 显示 RX/TX 速率历史图表，60 秒滚动窗口。图表使用平滑值 (EMA) 以提高可读性。 | 开 |
| **信号信息** | 显示信号强度 (dBm) 和质量百分比（优秀/良好/一般/较弱）。 | 开 |
| **信道信息** | 显示 WiFi 信道号和带宽 (20/40/80/160 MHz)。 | 开 |

### 速率详情

| 选项 | 说明 | 默认 |
|------|------|------|
| **收发速率** | 显示当前接收和发送链路速率 (Mbps)。这是原始 PHY 速率，非实际吞吐量。 | 开 |
| **MCS 索引** | 显示调制编码方案索引。MCS 越高 = 潜在速度越快，但需要更好的信号。 | 开 |
| **MIMO 流数** | 显示空间流数量（如 2x2）。流数越多 = 吞吐容量越大。 | 开 |

### 统计信息

| 选项 | 说明 | 默认 |
|------|------|------|
| **流量统计** | 显示自连接以来的累计 RX/TX 字节数和包数。 | 关 |
| **链路质量** | 显示 TX 重试、失败和 RX 丢包数。数值高表示存在干扰或信号弱。 | 关 |
| **信标统计** | 显示信标丢失计数。信标丢失表示 AP 可达性问题。 | 关 |

### 连接信息

| 选项 | 说明 | 默认 |
|------|------|------|
| **连接时长** | 显示当前连接已持续的时间。 | 开 |
| **预期吞吐量** | 显示内核根据当前条件估算的吞吐量。部分驱动可能不支持。 | 关 |
| **IP 地址** | 显示本地 IP 地址（点击显示，默认遮蔽以保护隐私）。 | 开 |
| **网关** | 显示网关 IP 地址（点击显示，默认遮蔽）。 | 开 |
| **BSSID** | 显示接入点 MAC 地址（点击显示，默认遮蔽）。 | 开 |

### 高级选项

| 选项 | 说明 | 默认 |
|------|------|------|
| **ACK 信号** | 显示来自 AP 的 ACK 信号强度，反映双向链路质量。部分驱动不支持。 | 关 |
| **空口时间** | 显示 RX/TX 持续时间（毫秒），反映信道占用情况。部分驱动不支持（可能显示 0）。 | 关 |

## 技术说明

### 数据来源

- **nl80211**：直接内核接口，获取 WiFi 统计信息（信号、速率、MCS 等）
- **NetworkManager**：连接元数据（SSID、IP、网关、安全协议）

### WiFi 代际

| 标识 | 标准 | 最大速率 | 频段 |
|------|------|----------|------|
| WiFi 4 | 802.11n (HT) | 600 Mbps | 2.4/5 GHz |
| WiFi 5 | 802.11ac (VHT) | 3.5 Gbps | 5 GHz |
| WiFi 6 | 802.11ax (HE) | 9.6 Gbps | 2.4/5 GHz |
| WiFi 6E | 802.11ax (HE) | 9.6 Gbps | 6 GHz |
| WiFi 7 | 802.11be (EHT) | 46 Gbps | 2.4/5/6 GHz |

### 信号质量阈值

| 质量 | dBm 范围 | 图标 |
|------|----------|------|
| 优秀 | ≥ -50 | 满格 |
| 良好 | -50 至 -60 | 3 格 |
| 一般 | -60 至 -70 | 2 格 |
| 较弱 | -70 至 -80 | 1 格 |
| 很差 | < -80 | 无信号 |

## 许可证

MIT。详见 `LICENSE`。
