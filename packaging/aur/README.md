# AUR packaging

This widget ships a Plasma 6 plasmoid package *and* a compiled Qt6 QML plugin
(`.so`). That means it cannot be installed via KNewStuff ("Download New
Widgets") alone; it must be installed by the system package manager.

This directory contains a ready-to-publish `PKGBUILD` for Arch Linux AUR.

## Publish to AUR (high level)

0) Prerequisite: ensure your AUR account has an SSH public key configured.

1) Create a release tag in this repo (recommended format: `vX.Y.Z`) and push it:

```bash
git tag v1.0.0
git push origin v1.0.0
```

2) The GitHub Actions `Release` workflow will create a GitHub Release and
   upload:

- `truelink-monitor-vX.Y.Z.tar.gz`
- `truelink-monitor-vX.Y.Z.tar.gz.sha256`

3) Update `pkgver` (numeric only, no leading `v`) and `sha256sums` in
   `PKGBUILD`.

   Note: this `PKGBUILD` downloads the tarball from GitHub Release assets.

4) Clone the AUR package repo (package name: `plasma6-applet-truelink-monitor`):

```bash
git clone ssh://aur@aur.archlinux.org/plasma6-applet-truelink-monitor.git
cd plasma6-applet-truelink-monitor
```

5) Copy `PKGBUILD` into the AUR repo and generate `.SRCINFO`:

```bash
cp /path/to/truelink-monitor/packaging/aur/PKGBUILD .
makepkg --printsrcinfo > .SRCINFO
```

6) Optionally verify locally:

```bash
makepkg -s
```

7) Commit `PKGBUILD` and `.SRCINFO` and push to AUR:

```bash
git add PKGBUILD .SRCINFO
git commit -m "Update to vX.Y.Z"
git push
```

## Notes

- `pkgver` should match the numeric version (without the leading `v`).
- The extracted source directory for a GitHub tag tarball is
  `truelink-monitor-v$pkgver`.
