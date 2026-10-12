<!--
MD File Viewer
Author:     Amiran Kimadze (itsarmen)
GitHub:     https://github.com/itsarmen
Email:      amoswaper@gmail.com
Web:        https://xrow.asia
-->

<p align="center">
  <img src="icons/md-file-viewer-banner.png" alt="MD File Viewer" width="820">
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://badgen.net/badge/Flutter/3.x/02569B?icon=flutter" alt="Flutter"></a>
  <a href="https://dart.dev"><img src="https://badgen.net/badge/Dart/3.x/0175C2?icon=dart" alt="Dart"></a>
  <img src="https://badgen.net/badge/Linux/platform/FCC624?icon=linux" alt="Linux">
  <img src="https://badgen.net/badge/Windows/platform/0078D6?icon=windows" alt="Windows">
  <img src="https://badgen.net/badge/Yaru/theme/77216F" alt="Yaru">
  <img src="https://badgen.net/badge/Markdown/GitHub-flavored/181717?icon=github" alt="GitHub-flavored Markdown">
  <a href="https://github.com/itsarmen/MD-File-Viewer-Software/blob/main/LICENSE"><img src="https://badgen.net/badge/License/MIT/green" alt="MIT License"></a>
</p>

<p align="center">
  <a href="https://github.com/itsarmen/MD-File-Viewer-Software/releases/latest"><img src="https://badgen.net/github/release/itsarmen/MD-File-Viewer-Software" alt="Latest release"></a>
  <a href="https://github.com/itsarmen/MD-File-Viewer-Software/releases/latest"><img src="https://badgen.net/badge/download/Windows/0078D6?icon=windows" alt="Download for Windows"></a>
  <a href="https://github.com/itsarmen/MD-File-Viewer-Software/releases/latest"><img src="https://badgen.net/badge/download/.deb/2ea44f?icon=package" alt="Download .deb"></a>
</p>

<p align="center">
  A native desktop app for <strong>Linux and Windows</strong> to
  <strong>view and edit Markdown</strong> files with <strong>GitHub-style formatting</strong>,
  built with Flutter and the Yaru (GNOME) theme.
</p>

---

## Download

Get the latest version from the
[releases page](https://github.com/itsarmen/MD-File-Viewer-Software/releases/latest):

### Windows (x64)

| Asset | Description |
| --- | --- |
| `md-file-viewer_1.0.0_windows-x64-setup.exe` | Single-file installer (no administrator rights required). |
| `md-file-viewer_1.0.0_windows-x64.zip` | Portable bundle — extract anywhere and run `md_file_viewer.exe`. |

### Debian / Ubuntu (amd64)

```bash
curl -LO https://github.com/itsarmen/MD-File-Viewer-Software/releases/latest/download/md-file-viewer_1.0.0_amd64.deb
sudo apt install ./md-file-viewer_1.0.0_amd64.deb
```

Asset names embed the version; open the releases page if a newer version is available.
See [Build a Windows installer](#build-a-windows-installer) and
[Build a Debian package](#build-a-debian-package-deb) to produce your own.

## Features

- **GitHub-flavored preview** — headings, tables, task lists, blockquotes, fenced code
  blocks with syntax highlighting, and images rendered the way GitHub shows them.
- **Three view modes** — `Preview`, `Split` (editor + preview side by side), and `Edit`.
- **Fast editing** — monospaced editor with live dirty-state tracking and `Ctrl+S` saving.
- **Folder browsing** — open a whole folder and switch between its Markdown files from the sidebar.
- **Recent files** — remembers your recent documents and last opened folder between sessions.
- **Selectable text** — the entire UI is a `SelectionArea`, so any text can be selected and
  copied, with a native right-click context menu.
- **Smart links** — left-click a link to open it; external links open in your default browser,
  while links to local Markdown files open right inside the app.
- **Link right-click menu** — *Open link in browser*, *Copy link address*, and *Copy link text*.
- **Copy button on code blocks** — one click to copy a fenced code block to the clipboard.
- **Default `.md` handler** — opt in from *Quick Settings* to make double-clicking a Markdown
  file open this app.
- **GNOME / Nautilus integration** — adds an *“Open in MD File Viewer”* right-click entry.
- **Native look & feel** — Yaru theme with automatic light/dark following the system.
- **Keyboard scrolling** — arrows, Page Up/Down and Home/End scroll the preview instantly.

## Screenshot

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/f8d4f184-c6a0-44c8-9601-581d09b50edd" />


## Requirements

- **Linux** (developed on GNOME / Wayland; works on X11 too) or **Windows 10/11 (x64)**
- [Flutter](https://docs.flutter.dev/get-started/install) 3.x with desktop support for your platform
- Linux: a C++ toolchain and GTK 3 development headers (`clang`, `cmake`, `ninja-build`,
  `pkg-config`, `libgtk-3-dev`) — see Flutter’s Linux setup guide.
- Windows: Visual Studio 2022 with the *Desktop development with C++* workload — see
  Flutter’s Windows setup guide.

## Build from source

```bash
git clone https://github.com/itsarmen/MD-File-Viewer-Software.git
cd MD-File-Viewer-Software

flutter pub get

flutter build linux --release    # Linux bundle
flutter build windows --release  # Windows bundle
```

The release bundles are produced under `build/linux/x64/release/bundle/` and
`build/windows/x64/runner/Release/` respectively.

## Install

### Windows

Run the single-file installer from the releases page, or build it yourself:

```powershell
flutter build windows --release
scripts\build-installer.ps1   # dist\md-file-viewer_<version>_windows-x64-setup.exe
```

The installer is per-user — no administrator rights required — and places the app in
`%LOCALAPPDATA%\Programs\MD File Viewer` with a Start Menu shortcut and an uninstaller.
For a portable copy, `scripts\build-windows.ps1` packages the release bundle as a ZIP
that runs from anywhere.

After installing, launch **MD File Viewer** from the Start Menu, or:

```powershell
& "$env:LOCALAPPDATA\Programs\MD File Viewer\md_file_viewer.exe" path\to\README.md
```

### Linux

A helper script installs the binary, icons and desktop entry into `~/.local` for the
current user, then registers the app as a Markdown handler:

```bash
./scripts/install.sh
```

It will:

- copy the release bundle to `~/.local/share/md-file-viewer/`;
- install a launcher at `~/.local/bin/md-file-viewer`;
- install icons for every standard size (`16`–`512`) plus a scalable SVG;
- install `~/.local/share/applications/md-file-viewer.desktop`;
- add a **Nautilus “Scripts”** entry to open selected files;
- refresh the desktop database and icon cache.

Set `PREFIX=...` to install somewhere else, e.g. `PREFIX=/usr/local ./scripts/install.sh`.

After installing, launch it from your applications list, or:

```bash
md-file-viewer path/to/README.md
```

## Build a Debian package (.deb)

To build a distributable Debian/Ubuntu package (requires the release bundle and `dpkg-deb`):

```bash
flutter build linux --release
./scripts/build-deb.sh
```

This produces `dist/md-file-viewer_<version>_<arch>.deb`, containing the app bundle under
`/usr/lib/md-file-viewer/`, a launcher at `/usr/bin/md-file-viewer`, icons, the desktop entry
and documentation. The version is read from `pubspec.yaml` and the architecture from the host.

Install it with:

```bash
sudo dpkg -i dist/md-file-viewer_*.deb
# or, to pull in any missing dependencies automatically:
sudo apt install ./dist/md-file-viewer_*.deb
```

Options: `--version X.Y.Z` to override the version, `--arch amd64` to target another
architecture.

## Build a Windows installer

To build the Windows artifacts (requires the release bundle and PowerShell):

```powershell
flutter build windows --release
scripts\build-windows.ps1     # dist\md-file-viewer_<version>_windows-x64.zip
scripts\build-installer.ps1   # dist\md-file-viewer_<version>_windows-x64-setup.exe
```

`build-installer.ps1` uses [Inno Setup](https://jrsoftware.org/isinfo.php) — install it with
`winget install JRSoftware.InnoSetup`. The resulting setup EXE installs per-user into
`%LOCALAPPDATA%\Programs\MD File Viewer` and registers the app under
**Settings → Default apps**, where you confirm it for `.md` files (also reachable from the
app's *Quick Settings*).

The installer Authenticode-signs the app and itself when a code-signing certificate is
available: by default it looks for one named *MD File Viewer Code Signing* in the current
user's certificate store; pass `-SignPfx cert.pfx [-SignPfxPassword pw]` or
`-SignThumbprint <thumbprint>` to use another certificate, or `-NoSign` to skip. Windows
SmartScreen still warns with “Unknown publisher” for unsigned installers — clearing that on
other machines requires a trusted (purchased) code-signing certificate.

Both scripts read the version from `pubspec.yaml`; pass `-Version X.Y.Z` to override it.

## Usage

### Opening files

- **Open file** (`Ctrl+O`, or the toolbar button) — pick a `.md` file.
- **Open folder** — load a directory and navigate its Markdown files from the sidebar.
- Launching from the terminal with a path opens that file directly.

Supported extensions: `md`, `markdown`, `mdx`, `mdown`, `mkd`, `txt`.

### View modes

Use the segmented control in the toolbar to switch between:

| Mode | Description |
| --- | --- |
| **Preview** | Rendered GitHub-style view. |
| **Split** | Editor on the left, live preview on the right. |
| **Edit** | Raw Markdown editor only. |

### Keyboard shortcuts

| Shortcut | Action |
| --- | --- |
| `Ctrl+O` | Open file |
| `Ctrl+S` | Save |
| `Ctrl+Shift+S` | Save as… |
| `↑` / `↓` | Scroll preview by one line |
| `Page Up` / `Page Down` | Scroll preview by one page |
| `Home` / `End` | Jump to top / bottom of preview |

### Links

- **Left-click** a link: external URLs open in your browser; local `.md` links open in the app.
- **Right-click** a link: *Open link in browser*, *Copy link address*, *Copy link text*.
- **Select text** anywhere and use the native context menu to copy it.

### Desktop integration

Open **Quick Settings** (gear icon) to check whether the app is registered and whether it is the
default Markdown handler. On Linux **Set as default** registers it directly; on Windows it opens
**Settings → Default apps**, where you confirm **MD File Viewer** for `.md` files.

## Project structure

```
lib/
  main.dart                     # entry point
  src/
    app.dart                    # MaterialApp + YaruTheme
    home_page.dart              # main UI: sidebar, editor, preview, status bar
    github_markdown.dart        # GitHub-flavored Markdown renderer
    settings_dialog.dart        # Quick Settings dialog
    desktop_integration.dart    # xdg-mime (Linux) / registry (Windows) handler helpers
    recent_store.dart           # recent files / last folder persistence
    toast.dart                  # centered transient messages
windows/                        # Windows runner (incl. installer/md-file-viewer.iss)
data/
  md-file-viewer.desktop        # desktop entry
icons/                          # app icons + README banner
scripts/
  install.sh                    # user-level installer (Linux)
  build-deb.sh                  # Debian (.deb) package builder
  build-windows.ps1             # Windows portable ZIP builder
  build-installer.ps1           # Windows setup EXE builder (Inno Setup)
test/                           # widget & scroll tests
```

## Built with

- [Flutter](https://flutter.dev) & [Yaru](https://pub.dev/packages/yaru) — UI and GNOME theming
- [`flutter_markdown`](https://pub.dev/packages/flutter_markdown) & [`markdown`](https://pub.dev/packages/markdown) — rendering
- [`flutter_highlight`](https://pub.dev/packages/flutter_highlight) / [`highlight`](https://pub.dev/packages/highlight) — code syntax highlighting
- [`file_picker`](https://pub.dev/packages/file_picker) — native file & folder dialogs
- [`url_launcher`](https://pub.dev/packages/url_launcher) — link handling

## Author

**Amiran Kimadze** (*itsarmen*)

- GitHub: [@itsarmen](https://github.com/itsarmen)
- Email: [amoswaper@gmail.com](mailto:amoswaper@gmail.com)
- Web: [https://xrow.asia](https://xrow.asia)

## License

MD File Viewer is **free and open-source software** released under the
[MIT License](LICENSE). Anyone is welcome to use, study, modify, and improve it —
forks and contributions are encouraged. The original author and copyright holder is
**Amiran Kimadze (itsarmen)**, who must remain credited in all copies and derivative
works. See [LICENSE](LICENSE) for the full text.
