#!/usr/bin/env python3
from PIL import Image, ImageDraw

BG = (15, 23, 42, 255)  # #0F172A
FG = (248, 250, 252, 255)  # #F8FAFC


def draw_icon(size, background=True, fg=FG, bg=BG):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    if background:
        radius = int(size * 0.22)
        d.rounded_rectangle([0, 0, size, size], radius=radius, fill=bg)

    # Geometry
    mic_head_r = size * 0.13
    mic_head_cx = size * 0.40
    mic_head_cy = size * 0.40

    body_w = size * 0.16
    body_h = size * 0.24
    body_x = mic_head_cx - body_w / 2
    body_y = mic_head_cy + mic_head_r * 0.55

    stem_w = size * 0.06
    stem_h = size * 0.14
    stem_x = mic_head_cx - stem_w / 2
    stem_y = body_y + body_h * 0.92

    base_w = size * 0.24
    base_h = size * 0.06
    base_x = mic_head_cx - base_w / 2
    base_y = stem_y + stem_h * 0.75

    # Pause bars
    bar_w = size * 0.06
    bar_h = size * 0.22
    bar_gap = size * 0.05
    bar_x = size * 0.62
    bar_y = size * 0.31

    # Draw mic head
    d.ellipse(
        [
            mic_head_cx - mic_head_r,
            mic_head_cy - mic_head_r,
            mic_head_cx + mic_head_r,
            mic_head_cy + mic_head_r,
        ],
        fill=fg,
    )

    # Draw body (rounded)
    d.rounded_rectangle(
        [body_x, body_y, body_x + body_w, body_y + body_h],
        radius=int(body_w * 0.4),
        fill=fg,
    )

    # Stem
    d.rounded_rectangle(
        [stem_x, stem_y, stem_x + stem_w, stem_y + stem_h],
        radius=int(stem_w * 0.5),
        fill=fg,
    )

    # Base
    d.rounded_rectangle(
        [base_x, base_y, base_x + base_w, base_y + base_h],
        radius=int(base_h * 0.5),
        fill=fg,
    )

    # Pause bars
    d.rounded_rectangle(
        [bar_x, bar_y, bar_x + bar_w, bar_y + bar_h],
        radius=int(bar_w * 0.4),
        fill=fg,
    )
    d.rounded_rectangle(
        [bar_x + bar_w + bar_gap, bar_y, bar_x + bar_w * 2 + bar_gap, bar_y + bar_h],
        radius=int(bar_w * 0.4),
        fill=fg,
    )

    return img


def main():
    root = "/Users/ericwangzq/Library/Mobile Documents/com~apple~CloudDocs/Projects/auto-mute"
    app_png = f"{root}/assets/icon/app-icon.png"
    menu_png = f"{root}/assets/icon/menubar-icon.png"

    draw_icon(1024, background=True).save(app_png)
    # template icon: black on transparent
    draw_icon(32, background=False, fg=(0, 0, 0, 255)).save(menu_png)

    print("generated", app_png, menu_png)


if __name__ == "__main__":
    main()
