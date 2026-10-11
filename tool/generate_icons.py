#!/usr/bin/env python3
# MD File Viewer
# Author:     Amiran Kimadze (itsarmen)
# GitHub:     https://github.com/itsarmen
# Email:      amoswaper@gmail.com
# Web:        https://xrow.asia
"""Generate the MD File Viewer app icon at every size Linux needs.

Outputs into <project>/icons:
  md-file-viewer.png          1024x1024 master
  md-file-viewer-<size>.png   16..512 for the hicolor icon theme
  md-file-viewer.svg          scalable master
"""

import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "icons")

NAME = "md-file-viewer"
MASTER = 1024
SIZES = [16, 22, 24, 32, 48, 64, 128, 256, 512]

FONT_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
# RoyalBlue gradient.
TOP = (92, 124, 235)
BOTTOM = (65, 105, 225)


def _lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def _gradient(size):
    grad = Image.new("RGB", (1, size))
    for y in range(size):
        grad.putpixel((0, y), _lerp(TOP, BOTTOM, y / (size - 1)))
    return grad.resize((size, size), Image.BILINEAR).convert("RGBA")


def _vertical_fade(size, top_alpha, power=2):
    fade = Image.new("L", (1, size))
    for y in range(size):
        t = y / (size - 1)
        fade.putpixel((0, y), int(top_alpha * (1 - t) ** power))
    return fade.resize((size, size))


def build_master():
    size = MASTER
    margin = round(size * 0.055)
    radius = round(size * 0.225)
    box = [margin, margin, size - margin, size - margin]

    tile = _gradient(size)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(box, radius=radius, fill=255)

    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    img.paste(tile, (0, 0), mask)

    # Soft highlight along the top edge for depth.
    highlight = Image.new("L", (size, size), 0)
    ImageDraw.Draw(highlight).rounded_rectangle(box, radius=radius, fill=255)
    highlight = ImageChops.multiply(highlight, _vertical_fade(size, 70))
    cap = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    cap.putalpha(highlight)
    img = Image.alpha_composite(img, cap)

    # Foreground mark: the classic Markdown "M" + down arrow.
    font = ImageFont.truetype(FONT_PATH, round(size * 0.5))
    text = "M\u2193"
    draw = ImageDraw.Draw(img)
    left, top, right, bottom = draw.textbbox((0, 0), text, font=font)
    x = (size - (right - left)) / 2 - left
    y = (size - (bottom - top)) / 2 - top

    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).text(
        (x, y + size * 0.012), text, font=font, fill=(0, 0, 0, 80)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(size * 0.012))
    img = Image.alpha_composite(img, shadow)
    ImageDraw.Draw(img).text((x, y), text, font=font, fill=(255, 255, 255, 255))

    return img


SVG = """<svg xmlns="http://www.w3.org/2000/svg" width="{s}" height="{s}" \
viewBox="0 0 1024 1024">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#5C7CEB"/>
      <stop offset="1" stop-color="#4169E1"/>
    </linearGradient>
  </defs>
  <rect x="56" y="56" width="912" height="912" rx="230" fill="url(#g)"/>
  <text x="512" y="536" text-anchor="middle" dominant-baseline="central"
        font-family="DejaVu Sans, Ubuntu, sans-serif" font-weight="bold"
        font-size="520" fill="#ffffff">M&#8595;</text>
</svg>
"""


def main():
    os.makedirs(OUT, exist_ok=True)
    master = build_master()
    for size in SIZES:
        icon = master.resize((size, size), Image.LANCZOS)
        icon.save(os.path.join(OUT, f"{NAME}-{size}.png"))
    master.save(os.path.join(OUT, f"{NAME}.png"))
    with open(os.path.join(OUT, f"{NAME}.svg"), "w", encoding="utf-8") as fh:
        fh.write(SVG.format(s=MASTER))
    print(f"Wrote {len(SIZES)} PNG sizes + SVG to {OUT}")


if __name__ == "__main__":
    main()
