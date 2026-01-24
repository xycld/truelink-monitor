# Maintainer: xycld
pkgname=plasma6-applet-truelink-monitor
pkgver=1.0.0
pkgrel=1
pkgdesc="Real WiFi physical layer monitor for KDE Plasma 6 - shows RSSI dBm, PHY Rate, MCS, MIMO"
arch=('x86_64')
url="https://github.com/xycld/truelink-monitor"
license=('MIT')
depends=(
    'plasma-workspace>=6.0'
    'networkmanager-qt>=6.0'
    'libnl'
)
makedepends=(
    'cmake'
    'extra-cmake-modules>=6.0'
    'qt6-base'
    'qt6-declarative'
    'kf6-ki18n'
    'kf6-plasma'
    'kf6-networkmanager-qt'
)
source=("$pkgname-$pkgver.tar.gz")
sha256sums=('SKIP')

build() {
    local srcdir_name="truelink-monitor-$pkgver"
    cmake -B build -S "$srcdir_name" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DBUILD_TESTING=OFF
    cmake --build build
}

package() {
    DESTDIR="$pkgdir" cmake --install build
}
