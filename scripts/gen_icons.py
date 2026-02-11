#!/usr/bin/env python3
from PIL import Image, ImageFilter
from pathlib import Path

ROOT = Path('/Users/ericwangzq/Library/Mobile Documents/com~apple~CloudDocs/Projects/auto-mute')
SRC = ROOT / 'assets/icon/AutoMute.iconset/unnamed.jpg'
APP_PNG = ROOT / 'assets/icon/app-icon.png'
MENU_PNG = ROOT / 'assets/icon/menubar-icon.png'


def load_source():
    if not SRC.exists():
        raise FileNotFoundError(f"Source image not found: {SRC}")
    return Image.open(SRC).convert('RGBA')


def crop_outer_frame(img: Image.Image) -> Image.Image:
    # Remove the light-blue outer frame by trimming pixels similar to top-left color.
    w, h = img.size
    bg = img.getpixel((5, 5))[:3]

    def is_bg(px):
        r, g, b, a = px
        dr = r - bg[0]
        dg = g - bg[1]
        db = b - bg[2]
        return (dr*dr + dg*dg + db*db) < 900  # threshold

    ip = img.load()
    min_x, min_y = w, h
    max_x, max_y = 0, 0
    for y in range(h):
        for x in range(w):
            if not is_bg(ip[x, y]):
                if x < min_x: min_x = x
                if y < min_y: min_y = y
                if x > max_x: max_x = x
                if y > max_y: max_y = y

    if min_x >= max_x or min_y >= max_y:
        return img

    # Add small padding
    pad = int(min(w, h) * 0.01)
    min_x = max(0, min_x - pad)
    min_y = max(0, min_y - pad)
    max_x = min(w - 1, max_x + pad)
    max_y = min(h - 1, max_y + pad)
    return img.crop((min_x, min_y, max_x + 1, max_y + 1))


def save_app_icon(img: Image.Image):
    img = crop_outer_frame(img)
    # center-crop square if needed
    w, h = img.size
    s = min(w, h)
    left = (w - s) // 2
    top = (h - s) // 2
    img = img.crop((left, top, left + s, top + s))
    img = img.resize((1024, 1024), Image.LANCZOS)
    img.save(APP_PNG)


def build_menubar_icon(img: Image.Image):
    img = crop_outer_frame(img)
    w, h = img.size
    s = min(w, h)
    left = (w - s) // 2
    top = (h - s) // 2
    img = img.crop((left, top, left + s, top + s))

    # Build a clean mask from white glyphs
    ip = img.load()
    mask = Image.new('L', img.size, 0)
    mp = mask.load()
    for y in range(s):
        for x in range(s):
            r, g, b, a = ip[x, y]
            if a < 10:
                continue
            # white-ish: high brightness and low saturation
            mx = max(r, g, b)
            mn = min(r, g, b)
            if mx > 210 and (mx - mn) < 20:
                mp[x, y] = 255

    # Clean up: thicken slightly, then hard-threshold
    mask = mask.filter(ImageFilter.MaxFilter(3))
    mask = mask.resize((64, 64), Image.LANCZOS)
    mask = mask.point(lambda p: 255 if p > 128 else 0)

    icon = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    black = Image.new('RGBA', (64, 64), (0, 0, 0, 255))
    icon.paste(black, (0, 0), mask)
    icon.save(MENU_PNG)


def generate_iconset():
    app = Image.open(APP_PNG).convert('RGBA')
    iconset = ROOT / 'assets/icon/AutoMute.iconset'
    iconset.mkdir(parents=True, exist_ok=True)

    sizes = [16, 32, 128, 256, 512]
    for s in sizes:
        img = app.resize((s, s), Image.LANCZOS)
        img.save(iconset / f'icon_{s}x{s}.png')
        img2 = app.resize((s*2, s*2), Image.LANCZOS)
        img2.save(iconset / f'icon_{s}x{s}@2x.png')

    app.resize((1024, 1024), Image.LANCZOS).save(iconset / 'icon_1024x1024.png')


def main():
    src = load_source()
    save_app_icon(src)
    build_menubar_icon(src)
    generate_iconset()
    print(f"Generated {APP_PNG}")
    print(f"Generated {MENU_PNG}")


if __name__ == '__main__':
    main()
