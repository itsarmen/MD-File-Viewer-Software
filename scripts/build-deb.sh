#!/usr/bin/env bash
# MD File Viewer
# Author:     Amiran Kimadze (itsarmen)
# GitHub:     https://github.com/itsarmen
# Email:      amoswaper@gmail.com
# Web:        https://xrow.asia
# Build a Debian (.deb) package from the Flutter Linux release bundle.
#
# Usage:
#   flutter build linux --release
#   ./scripts/build-deb.sh [--version X.Y.Z] [--arch amd64]
#
# Output: dist/<app>_<version>_<arch>.deb
set -euo pipefail

APP="md-file-viewer"
BIN_NAME="md_file_viewer"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE="$ROOT/build/linux/x64/release/bundle"

# --- Options ---------------------------------------------------------------
VERSION=""
ARCH=""
while [ $# -gt 0 ]; do
  case "$1" in
    --version) VERSION="${2:-}"; shift 2 ;;
    --arch)    ARCH="${2:-}";    shift 2 ;;
    -h|--help)
      grep '^# ' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

# Version falls back to pubspec.yaml (strip Flutter's "+build" suffix).
if [ -z "$VERSION" ]; then
  VERSION="$(awk '/^version:/{print $2}' "$ROOT/pubspec.yaml" | cut -d+ -f1)"
fi
if [ -z "$ARCH" ]; then
  ARCH="$(dpkg --print-architecture 2>/dev/null || echo amd64)"
fi

PKG="${APP}_${VERSION}_${ARCH}"
DIST="$ROOT/dist"
STAGE="$ROOT/build/deb/$PKG"

# --- Checks ----------------------------------------------------------------
if ! command -v dpkg-deb >/dev/null 2>&1; then
  echo "dpkg-deb not found. Install the 'dpkg' package." >&2
  exit 1
fi
if [ ! -x "$BUNDLE/$BIN_NAME" ]; then
  echo "Release bundle not found at $BUNDLE" >&2
  echo "Build it first:  flutter build linux --release" >&2
  exit 1
fi

echo "Packaging $APP $VERSION ($ARCH)"

# --- Layout ----------------------------------------------------------------
rm -rf "$STAGE"
mkdir -p "$STAGE/DEBIAN"
mkdir -p "$STAGE/usr/lib/$APP"
mkdir -p "$STAGE/usr/bin"
mkdir -p "$STAGE/usr/share/applications"
mkdir -p "$STAGE/usr/share/doc/$APP"

# Application bundle (binary resolves lib/ and data/ via RPATH $ORIGIN).
cp -r "$BUNDLE/." "$STAGE/usr/lib/$APP/"

# Launcher on PATH.
cat > "$STAGE/usr/bin/$APP" <<EOF
#!/usr/bin/env bash
exec "/usr/lib/$APP/$BIN_NAME" "\$@"
EOF
chmod 755 "$STAGE/usr/bin/$APP"

# Icons for every size used by the app grid, dock and desktop.
for size in 16 22 24 32 48 64 128 256 512; do
  dir="$STAGE/usr/share/icons/hicolor/${size}x${size}/apps"
  mkdir -p "$dir"
  cp "$ROOT/icons/$APP-$size.png" "$dir/$APP.png"
done
mkdir -p "$STAGE/usr/share/icons/hicolor/scalable/apps"
cp "$ROOT/icons/$APP.svg" "$STAGE/usr/share/icons/hicolor/scalable/apps/$APP.svg"

# Desktop entry (resolve via PATH so any prefix works).
install -m644 "$ROOT/data/$APP.desktop" "$STAGE/usr/share/applications/$APP.desktop"
sed -i "s|^Exec=.*|Exec=$APP %F|" "$STAGE/usr/share/applications/$APP.desktop"

# --- Documentation ---------------------------------------------------------
cat > "$STAGE/usr/share/doc/$APP/copyright" <<EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: MD File Viewer
Source: https://github.com/itsarmen/MD-File-Viewer-Software

Files: *
Copyright: 2026 Amiran Kimadze (itsarmen) <amoswaper@gmail.com>
License: MIT
 MD File Viewer is free and open-source software. The original author and
 copyright holder is Amiran Kimadze (itsarmen). Anyone is welcome to use,
 study, modify and improve this software provided the original author
 remains credited.
 .
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
EOF

{
  echo "$APP ($VERSION) unstable; urgency=medium"
  echo
  echo "  * Package MD File Viewer $VERSION."
  echo
  echo " -- Amiran Kimadze (itsarmen) <amoswaper@gmail.com>  $(date -R)"
} | gzip -9n > "$STAGE/usr/share/doc/$APP/changelog.Debian.gz"
chmod 644 "$STAGE/usr/share/doc/$APP/changelog.Debian.gz"

# --- Control scripts -------------------------------------------------------
cat > "$STAGE/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database -q /usr/share/applications || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t /usr/share/icons/hicolor >/dev/null 2>&1 || true
fi
EOF

cat > "$STAGE/DEBIAN/postrm" <<'EOF'
#!/bin/sh
set -e
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database -q /usr/share/applications || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t /usr/share/icons/hicolor >/dev/null 2>&1 || true
fi
EOF
chmod 755 "$STAGE/DEBIAN/postinst" "$STAGE/DEBIAN/postrm"

# --- Control file ----------------------------------------------------------
INSTALLED_SIZE="$(du -sk "$STAGE" | cut -f1)"
cat > "$STAGE/DEBIAN/control" <<EOF
Package: $APP
Version: $VERSION
Section: editors
Priority: optional
Architecture: $ARCH
Depends: libgtk-3-0, libglib2.0-0, libstdc++6
Installed-Size: $INSTALLED_SIZE
Maintainer: Amiran Kimadze (itsarmen) <amoswaper@gmail.com>
Homepage: https://github.com/itsarmen/MD-File-Viewer-Software
Description: View and edit Markdown files with GitHub-style formatting
 MD File Viewer is a native Linux desktop application built with Flutter and
 the Yaru (GNOME) theme. It renders GitHub-flavored Markdown with support for
 preview, split and edit modes, folder browsing, recent files, selectable and
 copyable text, smart link handling, and desktop integration as the default
 Markdown handler.
EOF
chmod 644 "$STAGE/DEBIAN/control"

# --- Build -----------------------------------------------------------------
mkdir -p "$DIST"
dpkg-deb --root-owner-group --build "$STAGE" "$DIST/$PKG.deb"

echo
echo "Built: $DIST/$PKG.deb"
echo "Install with:  sudo dpkg -i \"$DIST/$PKG.deb\""
echo "Or:            sudo apt install \"$DIST/$PKG.deb\""
