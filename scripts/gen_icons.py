#!/usr/bin/env python3
from PIL import Image, ImageDraw

# Base colors
BG_TOP = (20, 32, 56, 255)   # slightly lighter top
BG_BOT = (12, 18, 34, 255)   # darker bottom
FG_BASE = (245, 247, 250, 255)
FG_SHADE = (220, 225, 232, 255)
FG_HIGHLIGHT = (255, 255, 255, 255)
FG_DARK = (180, 188, 198, 255)


def lerp(a, b, t):
    return int(a + (b - a) * t)


def draw_linear_gradient(size, top, bottom):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    for y in range(size):
        t = y / (size - 1)
        r = lerp(top[0], bottom[0], t)
        g = lerp(top[1], bottom[1], t)
        b = lerp(top[2], bottom[2], t)
        a = lerp(top[3], bottom[3], t)
        for x in range(size):
            px[x, y] = (r, g, b, a)
    return img


def draw_icon(size, background=True, fg=FG_BASE, template=False):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    if background:
        radius = int(size * 0.22)
        bg = draw_linear_gradient(size, BG_TOP, BG_BOT)
        mask = Image.new("L", (size, size), 0)
        md = ImageDraw.Draw(mask)
        md.rounded_rectangle([0, 0, size, size], radius=radius, fill=255)
        img.paste(bg, (0, 0), mask)

        # subtle top-left highlight
        hl = Image.new("RGBA", (size, size), (255, 255, 255, 0))
        hld = ImageDraw.Draw(hl)
        hld.ellipse([
            -size * 0.15,
            -size * 0.20,
            size * 0.85,
            size * 0.75,
        ], fill=(255, 255, 255, 28))
        img = Image.alpha_composite(img, hl)
        d = ImageDraw.Draw(img)

    # Layout
    mic_center_x = size * 0.36
    mic_center_y = size * 0.42

    capsule_w = size * 0.22
    capsule_h = size * 0.32
    capsule_x = mic_center_x - capsule_w / 2
    capsule_y = mic_center_y - capsule_h / 2

    stem_w = size * 0.06
    stem_h = size * 0.16
    stem_x = mic_center_x - stem_w / 2
    stem_y = capsule_y + capsule_h

    base_w = size * 0.26
    base_h = size * 0.06
    base_x = mic_center_x - base_w / 2
    base_y = stem_y + stem_h * 0.75

    # Pause bars
    bar_w = size * 0.06
    bar_h = size * 0.24
    bar_gap = size * 0.05
    bar_x = size * 0.64
    bar_y = size * 0.32

    # Colors for template or app icon
    base = fg if template else FG_BASE
    shade = fg if template else FG_SHADE
    highlight = fg if template else FG_HIGHLIGHT
    dark = fg if template else FG_DARK

    # Mic capsule
    capsule_radius = int(capsule_w * 0.55)
    d.rounded_rectangle(
        [capsule_x, capsule_y, capsule_x + capsule_w, capsule_y + capsule_h],
        radius=capsule_radius,
        fill=base,
    )

    # Capsule shading (bottom)
    d.rounded_rectangle(
        [
            capsule_x,
            capsule_y + capsule_h * 0.52,
            capsule_x + capsule_w,
            capsule_y + capsule_h,
        ],
        radius=capsule_radius,
        fill=shade,
    )

    # Capsule highlight
    d.ellipse([
        capsule_x + capsule_w * 0.10,
        capsule_y + capsule_h * 0.08,
        capsule_x + capsule_w * 0.55,
        capsule_y + capsule_h * 0.35,
    ], fill=highlight)

    # Grill lines
    line_y1 = capsule_y + capsule_h * 0.38
    line_y2 = capsule_y + capsule_h * 0.48
    line_y3 = capsule_y + capsule_h * 0.58
    line_pad = capsule_w * 0.22
    d.line([(capsule_x + line_pad, line_y1), (capsule_x + capsule_w - line_pad, line_y1)], fill=dark, width=max(1, int(size * 0.01)))
    d.line([(capsule_x + line_pad, line_y2), (capsule_x + capsule_w - line_pad, line_y2)], fill=dark, width=max(1, int(size * 0.01)))
    d.line([(capsule_x + line_pad, line_y3), (capsule_x + capsule_w - line_pad, line_y3)], fill=dark, width=max(1, int(size * 0.01)))

    # Stem
    d.rounded_rectangle(
        [stem_x, stem_y, stem_x + stem_w, stem_y + stem_h],
        radius=int(stem_w * 0.5),
        fill=base,
    )

    # Base
    d.rounded_rectangle(
        [base_x, base_y, base_x + base_w, base_y + base_h],
        radius=int(base_h * 0.5),
        fill=shade,
    )

    # Pause bars (right)
    d.rounded_rectangle(
        [bar_x, bar_y, bar_x + bar_w, bar_y + bar_h],
        radius=int(bar_w * 0.4),
        fill=base,
    )
    d.rounded_rectangle(
        [bar_x + bar_w + bar_gap, bar_y, bar_x + bar_w * 2 + bar_gap, bar_y + bar_h],
        radius=int(bar_w * 0.4),
        fill=base,
    )

    return img


def main():
    root = "/Users/ericwangzq/Library/Mobile Documents/com~apple~CloudDocs/Projects/auto-mute"
    app_png = f"{root}/assets/icon/app-icon.png"
    menu_png = f"{root}/assets/icon/menubar-icon.png"

    draw_icon(1024, background=True).save(app_png)
    # template icon: black on transparent
    draw_icon(64, background=False, fg=(0, 0, 0, 255), template=True).save(menu_png)

    print("generated", app_png, menu_png)


if __name__ == "__main__":
    main()
