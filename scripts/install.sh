#!/usr/bin/env bash
# MD File Viewer
# Author:     Amiran Kimadze (itsarmen)
# GitHub:     https://github.com/itsarmen
# Email:      amoswaper@gmail.com
# Web:        https://xrow.asia
# Install MD File Viewer (binary, icons, .desktop) for the current user.
set -euo pipefail

APP="md-file-viewer"
BIN_NAME="md_file_viewer"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE="$ROOT/build/linux/x64/release/bundle"

PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="$PREFIX/bin"
APP_DIR="$PREFIX/share/$APP"
ICON_ROOT="$PREFIX/share/icons/hicolor"
DESKTOP_DIR="$PREFIX/share/applications"

if [ ! -x "$BUNDLE/$BIN_NAME" ]; then
  echo "Release bundle not found at $BUNDLE" >&2
  echo "Build it first:  flutter build linux --release" >&2
  exit 1
fi

echo "Installing to $PREFIX"
mkdir -p "$BIN_DIR" "$DESKTOP_DIR" "$APP_DIR"
rm -rf "$APP_DIR"
cp -r "$BUNDLE/." "$APP_DIR/"

# Wrapper so the bundle's lib/ and data/ resolve correctly.
cat > "$BIN_DIR/$APP" <<EOF
#!/usr/bin/env bash
exec "$APP_DIR/$BIN_NAME" "\$@"
EOF
chmod +x "$BIN_DIR/$APP"

# Icons for every size used by the app grid, dock/taskbar and desktop.
for size in 16 22 24 32 48 64 128 256 512; do
  dir="$ICON_ROOT/${size}x${size}/apps"
  mkdir -p "$dir"
  cp "$ROOT/icons/$APP-$size.png" "$dir/$APP.png"
done
mkdir -p "$ICON_ROOT/scalable/apps"
cp "$ROOT/icons/$APP.svg" "$ICON_ROOT/scalable/apps/$APP.svg"

# Desktop entry (app list, dock, desktop shortcut).
install -m644 "$ROOT/data/$APP.desktop" "$DESKTOP_DIR/$APP.desktop"
# Absolute Exec path so launching works even when ~/.local/bin isn't on PATH.
sed -i "s|^Exec=.*|Exec=$BIN_DIR/$APP %F|" "$DESKTOP_DIR/$APP.desktop"
chmod +x "$DESKTOP_DIR/$APP.desktop"

# Refresh caches so the entry and icons show up immediately.
command -v update-desktop-database >/dev/null 2>&1 &&
  update-desktop-database "$DESKTOP_DIR" || true
command -v gtk-update-icon-cache >/dev/null 2>&1 &&
  gtk-update-icon-cache -f -t "$ICON_ROOT" >/dev/null 2>&1 || true

# Make MD File Viewer the default app for Markdown (double-click opens it).
if command -v xdg-mime >/dev/null 2>&1; then
  for mime in text/markdown text/x-markdown; do
    xdg-mime default "$APP.desktop" "$mime" || true
  done
fi

# Nautilus / GNOME Files right-click entry (appears under "Scripts").
SCRIPT_DIR="$HOME/.local/share/nautilus/scripts"
mkdir -p "$SCRIPT_DIR"
cat > "$SCRIPT_DIR/Open in MD File Viewer" <<EOF
#!/usr/bin/env bash
while IFS= read -r f; do
  [ -n "\$f" ] && nohup "$BIN_DIR/$APP" "\$f" >/dev/null 2>&1 &
done <<< "\$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"
EOF
chmod +x "$SCRIPT_DIR/Open in MD File Viewer"

echo "Done. Look for 'MD File Viewer' in your applications list."
