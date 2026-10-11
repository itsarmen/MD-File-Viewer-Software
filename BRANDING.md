<!--
MD File Viewer
Author:     Amiran Kimadze (itsarmen)
GitHub:     https://github.com/itsarmen
Email:      amoswaper@gmail.com
Web:        https://xrow.asia
-->

# MD File Viewer — Brand Guidelines

> Open and edit Markdown files with GitHub-style formatting.

This document defines how MD File Viewer looks, sounds and behaves on the
desktop. Follow it when you ship UI, packaging, screenshots, a website or a
README.

---

## 1. Brand at a glance

| | |
| --- | --- |
| **Name** | MD File Viewer |
| **Short name** | MD Viewer (only where space is tight) |
| **Command** | `md-file-viewer` |
| **App ID** | `dev.itsarmen.md_file_viewer` |
| **Tagline** | Open and edit Markdown files with GitHub-style formatting |
| **Platform** | Linux (GNOME / Ubuntu, Yaru) |
| **Personality** | Clear, quick, dependable, quietly technical |

**Positioning.** MD File Viewer is the native Linux app that makes `.md` files
look the way they do on GitHub, without a browser, without a project, without
setup. Double-click a file, read it, fix it, save it.

**The idea behind the mark.** The logo is the file extension itself: **.MD**.
Users already know what it means, and it is exactly what they double-click. The
brand says what the app does in three characters.

---

## 2. Logo

### 2.1 The app icon

A rounded square ("squircle") in RoyalBlue with the white **.MD** wordmark
centred on it.

| Property | Value |
| --- | --- |
| Canvas | 1024 × 1024 master |
| Outer margin | 5.5% of the canvas on every side |
| Corner radius | 22.5% of the canvas |
| Fill | Vertical gradient `#5C7CEB` (top) → `#4169E1` (bottom) |
| Depth | White highlight fading down from the top edge, about 27% opacity at the top, gone by 55% of the height |
| Wordmark | **.MD**, Poppins Bold, white, centred both ways |
| Wordmark width | About 69% of the canvas (710 of 1024) |
| Letter spacing | −1.5% of the em |
| Dot | The leading "." is white at about 62% opacity |
| Shadow | Soft black shadow under the wordmark: 8 px down, 10 px blur, about 28% opacity (values at 1024 px) |

The softer dot is deliberate. It marks ".MD" as a file extension and lets "MD"
carry the weight.

### 2.2 Files

```
icons/md-file-viewer.svg          vector master, use this first
icons/md-file-viewer.png          1024 × 1024 master
icons/md-file-viewer-16.png
icons/md-file-viewer-22.png
icons/md-file-viewer-24.png
icons/md-file-viewer-32.png
icons/md-file-viewer-48.png
icons/md-file-viewer-64.png
icons/md-file-viewer-128.png
icons/md-file-viewer-256.png
icons/md-file-viewer-512.png
```

The SVG has the letters converted to outlines, so it renders the same
everywhere and does not need the font installed.

### 2.3 Sizes and where they are used

| Size (px) | Typical use |
| --- | --- |
| 16 | Title bar, small menus, file list detail |
| 22 | Panel, toolbars |
| 24 | Taskbar / dock, list rows |
| 32 | Panel, application menus |
| 48 | App grid, desktop launcher, dock |
| 64 | File-manager icons, GNOME overview |
| 128 | GNOME Shell overview, About dialogs |
| 256 | Software centres, high-DPI grid |
| 512 | High-DPI displays, stores |
| Scalable SVG | Any other size, fallback |

### 2.4 Clear space

Keep empty space around the icon equal to **one quarter of its width** on every
side. Nothing (text, other logos, borders) enters that zone.

### 2.5 Minimum size

- App icon: **16 px**. The ".MD" stays legible down to this size.
- In print: **8 mm** wide.

### 2.6 Logo with name (lockup)

For websites, READMEs and stores, place the icon to the left of the name set in
**Poppins SemiBold**, vertically centred.

- Gap between icon and name: **½ of the icon's width**.
- Name height (cap height): about **40% of the icon's height**.
- Name colour: Ink on light backgrounds, white on dark.
- Never put the tagline inside the lockup. Set it on a separate line.

### 2.7 Do

- Use the supplied files unchanged.
- Place the icon on light, dark or photographic backgrounds. It carries its own
  background.
- Scale it proportionally.

### 2.8 Don't

- Don't recolour the gradient or the wordmark (the brief allows a recoloured
  wordmark only for special editions, and it must stay high contrast).
- Don't change the font, stretch, rotate or add outlines.
- Don't remove the shadow or the soft dot to "simplify".
- Don't add the app name or tagline inside the icon.
- Don't round the corners differently or crop the squircle.
- Don't place the icon on a background that is almost the same blue.

---

## 3. Colour

### 3.1 Brand colours

| Token | Hex | RGB | Use |
| --- | --- | --- | --- |
| `royalBlueLight` | `#5C7CEB` | 92, 124, 235 | Gradient top |
| `royalBlue` | `#4169E1` | 65, 105, 225 | **Primary.** Gradient bottom, buttons, links, highlights |
| `royalBlueDark` | `#3352C4` | 51, 82, 196 | Hover / pressed states |
| `onPrimary` | `#FFFFFF` | 255, 255, 255 | Text and marks on RoyalBlue |

### 3.2 Supporting neutrals (proposed)

| Token | Hex | Use |
| --- | --- | --- |
| `ink` | `#1F2A44` | Headings and text on light backgrounds |
| `slate` | `#5B6785` | Secondary text |
| `mist` | `#EEF2FD` | Tinted backgrounds, hover rows |
| `night` | `#0F1530` | Dark backgrounds (website, screenshots) |

These are suggestions to keep a consistent family with RoyalBlue. The in-app
UI keeps following the GitHub-flavoured light and dark themes.

### 3.3 Contrast

White on `#4169E1` is about **4.9 : 1**, and white on `#5C7CEB` is about
**3.8 : 1**. That passes WCAG AA for large text, which covers the wordmark. For
small body text on RoyalBlue, use the darker end (`#4169E1` or `#3352C4`).

---

## 4. Typography

| Role | Font | Weight | Licence |
| --- | --- | --- | --- |
| Logo wordmark | Poppins | Bold (700) | SIL Open Font Licence |
| Product name, headings | Poppins | SemiBold (600) | SIL Open Font Licence |
| Body text (website, docs) | Inter | Regular (400) | SIL Open Font Licence |
| Code and Markdown source | DejaVu Sans Mono (system) / JetBrains Mono | Regular | OFL / Bitstream |

Inside the app, keep the system fonts of GNOME / Yaru for UI controls. Poppins
is for brand surfaces only.

**Why Poppins for the logo.** Its geometric shapes (a perfectly round dot, a
clean round D, sharp M) feel modern and friendly, and they stay readable at
16 px.

---

## 5. Voice and tone

**We are:** clear, direct, helpful, a little understated.
**We are not:** hype, jargon, jokey.

| Instead of | Write |
| --- | --- |
| "Revolutionary Markdown experience" | "Open and edit Markdown files." |
| "Unleash your documentation" | "Read your README the way GitHub shows it." |
| "Oops! Something went wrong 😬" | "Couldn't open the file. Check that it exists and you can read it." |

Rules of thumb:

- Short sentences. Active verbs (Open, Save, Preview).
- Say what happened and what to do next in error messages.
- Use sentence case in UI text ("Save as", not "Save As").
- Write "Markdown" with a capital M; write "`.md`" in code style.

### Short descriptions

- **One line:** Open and edit Markdown files with GitHub-style formatting.
- **Short:** A fast, native Markdown viewer and editor for Linux that renders
  files the way GitHub does.
- **Long:** MD File Viewer renders GitHub Flavored Markdown (tables, task
  lists, footnotes, alerts, emoji, strikethrough and syntax-highlighted code)
  in a native GNOME app. Switch between Preview, Split and Edit, and use the
  light or dark GitHub-style theme.

---

## 6. Using the brand in the product

### 6.1 In the app

- The primary accent is RoyalBlue `#4169E1`. Hover and pressed states use
  `#3352C4`.
- Window title: **MD File Viewer**, followed by the file name when one is open.
- About dialog: 128 px icon, name, version, tagline.

### 6.2 Desktop integration

[`data/md-file-viewer.desktop`](data/md-file-viewer.desktop):

```ini
[Desktop Entry]
Type=Application
Name=MD File Viewer
GenericName=Markdown Viewer & Editor
Comment=Open and edit Markdown files with GitHub-style formatting
Exec=md-file-viewer %F
Icon=md-file-viewer
Terminal=false
Categories=Utility;TextEditor;Development;GTK;
Keywords=markdown;md;editor;viewer;github;readme;
MimeType=text/markdown;text/x-markdown;
StartupNotify=true
StartupWMClass=dev.itsarmen.md_file_viewer
```

`StartupWMClass` must match the GTK application ID so GNOME shows the right
icon in the dock and taskbar.

### 6.3 Icon install locations

| Item | Destination |
| --- | --- |
| Icons (all sizes) | `~/.local/share/icons/hicolor/<size>/apps/md-file-viewer.png` |
| Vector icon | `~/.local/share/icons/hicolor/scalable/apps/md-file-viewer.svg` |

After installing, refresh the icon cache if the new icon doesn't appear:

```bash
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor
```

### 6.4 Default app for Markdown

```bash
xdg-mime default md-file-viewer.desktop text/markdown
xdg-mime default md-file-viewer.desktop text/x-markdown
xdg-mime query default text/markdown      # -> md-file-viewer.desktop
```

---

## 7. Screenshots and marketing

- Show a real, good-looking README: headings, a table, a task list and a code
  block.
- Capture at 2× scale, with the window shadow on, on a plain `night` or `mist`
  background.
- Show Preview and Split modes, and one dark-theme shot.
- Put the 128 px or 256 px icon next to the name when introducing the app.
- Keep the app icon the same size and position across all promo images.

---

## 8. Quick reference

| Question | Answer |
| --- | --- |
| Brand colour | RoyalBlue `#4169E1` |
| Gradient | `#5C7CEB` → `#4169E1`, top to bottom |
| Logo | ".MD" in white on a RoyalBlue squircle |
| Logo font | Poppins Bold |
| Smallest icon | 16 px |
| Clear space | ¼ of icon width |
| Tone | Clear, direct, understated |
| Keyboard shortcuts | `Ctrl+O` Open · `Ctrl+S` Save · `Ctrl+Shift+S` Save as |