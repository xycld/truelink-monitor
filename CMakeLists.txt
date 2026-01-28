cmake_minimum_required(VERSION 3.16)
project(truelink-monitor VERSION 1.0.10 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# KDE/Qt dependencies
find_package(ECM 6.0.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(ECMQmlModule)
include(ECMPoQmTools)

find_package(Qt6 6.6 REQUIRED COMPONENTS
    Core
    Quick
    Qml
    DBus
    Network
)

find_package(KF6 6.0 REQUIRED COMPONENTS
    Config
    I18n
    NetworkManagerQt
)

find_package(Plasma 6.0 REQUIRED)

find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBNL REQUIRED libnl-3.0 libnl-genl-3.0)

# Plugin library
add_library(truelinkmonitorplugin SHARED
    src/truelinkplugin.cpp
    src/wifimonitor.cpp
    src/nl80211helper.cpp
)

target_include_directories(truelinkmonitorplugin PRIVATE
    ${LIBNL_INCLUDE_DIRS}
)

target_link_libraries(truelinkmonitorplugin PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::Qml
    Qt6::DBus
    Plasma::Plasma
    KF6::I18n
    KF6::NetworkManagerQt
    ${LIBNL_LIBRARIES}
)

# Install plugin
install(TARGETS truelinkmonitorplugin
    DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/plasma/private/truelinkmonitor
)

# Install QML module
install(FILES src/qmldir
    DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/plasma/private/truelinkmonitor
)

# Install plasmoid package
plasma_install_package(package org.kde.plasma.truelinkmonitor)

# Install AppStream metainfo for KDE Discover.
install(FILES org.kde.plasma.truelinkmonitor.metainfo.xml
    DESTINATION ${KDE_INSTALL_METAINFODIR}
)

# Install translations
ki18n_install(po)

# CPack configuration for DEB package
set(CPACK_PACKAGE_NAME "truelink-monitor")
set(CPACK_PACKAGE_VERSION "1.1.11")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Advanced WiFi monitor plasmoid for KDE Plasma 6")
set(CPACK_PACKAGE_DESCRIPTION "A feature-rich WiFi monitoring widget that displays detailed wireless connection information including signal strength, link rates, traffic statistics, and more.")
set(CPACK_PACKAGE_CONTACT "xycld <xycld@example.com>")
set(CPACK_PACKAGE_HOMEPAGE_URL "https://github.com/xycld/truelink-monitor")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE")

# DEB specific
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "xycld")
set(CPACK_DEBIAN_PACKAGE_SECTION "kde")
set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "plasma-workspace (>= 6.0), libkf6networkmanagerqt6, libnl-3-200, libnl-genl-3-200, qml6-module-org-kde-kirigami")
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)

# RPM specific (bonus)
set(CPACK_RPM_PACKAGE_LICENSE "GPL-3.0")
set(CPACK_RPM_PACKAGE_GROUP "System Environment/Libraries")
set(CPACK_RPM_PACKAGE_REQUIRES "plasma-workspace >= 6.0, kf6-networkmanager-qt, libnl3")
set(CPACK_RPM_FILE_NAME RPM-DEFAULT)

include(CPack)
