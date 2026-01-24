# Packaging / Distribution

This project contains a Plasma 6 widget plus a C++ QML plugin. Because it
includes a compiled `.so`, it cannot be distributed via KNewStuff (the
"Download New Widgets" flow in Edit Mode) as a standalone download.

Recommended distribution is via distro packaging (system install) so that both
the plasmoid package and the QML plugin are installed into the correct Qt/QML
paths.

## KDE Discover integration

To show up in Discover, the AppStream metainfo file
`org.kde.plasma.truelinkmonitor.metainfo.xml` must be installed to the system's
metainfo directory (usually `/usr/share/metainfo/`).

This is handled by CMake install:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
sudo cmake --install build
```

## Arch Linux (PKGBUILD)

The root `PKGBUILD` is a starting point for an AUR package.

Typical workflow:

1) Build a release tarball from a tag (e.g. `v1.0.0`)
2) Set `sha256sums` to the correct value
3) Upload to AUR

## Other distros

- openSUSE OBS: build a source package from a tagged GitHub release.
- Fedora COPR: build from a tagged GitHub release.
- Debian/Ubuntu: package the source and ensure the plugin installs under the
  Qt6 QML import directory.

Note: advanced nl80211 station statistics can require elevated privileges on
some systems. For broad distro support, consider a safe "degraded mode" when
those metrics are not available.
