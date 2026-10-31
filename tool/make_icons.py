#!/usr/bin/env python3
"""Build every app icon from one picture.

Usage (from the project root, after `bash tool/bootstrap_platforms.sh`):
    pip install pillow
    python tool/make_icons.py branding/app_icon_1024.png

Writes:
  * web/favicon.png and web/icons/*  (always)
  * android/app/src/main/res/mipmap-*/ic_launcher.png  (if the folder exists)
  * ios/Runner/Assets.xcassets/AppIcon.appiconset/*  (if the folder exists)

The source should be square, at least 1024x1024, with NO transparency
(Apple rejects icons with transparent corners) and the character well inside
the edges.
"""
import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def flat(image: Image.Image) -> Image.Image:
    """Icon with no transparency, as the app stores require."""
    background = Image.new('RGB', image.size, image.convert('RGB').getpixel((2, 2)))
    background.paste(image.convert('RGBA'), mask=image.convert('RGBA').getchannel('A'))
    return background


def save(source: Image.Image, path: Path, px: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    source.resize((px, px), Image.LANCZOS).save(path, 'PNG', optimize=True)


def maskable(source: Image.Image, px: int) -> Image.Image:
    """Android adaptive icons crop to a circle: shrink so nothing is cut off."""
    canvas = Image.new('RGB', (px, px), source.getpixel((2, 2)))
    inner = int(px * 0.68)
    small = source.resize((inner, inner), Image.LANCZOS)
    canvas.paste(small, ((px - inner) // 2, (px - inner) // 2))
    return canvas


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 1
    source = Image.open(sys.argv[1])
    if source.width != source.height or source.width < 512:
        print('The icon must be square and at least 512 px (1024 px is best).',
              file=sys.stderr)
        return 1
    icon = flat(source)
    made = 0

    save(icon, ROOT / 'web/favicon.png', 48)
    save(icon, ROOT / 'web/icons/Icon-192.png', 192)
    save(icon, ROOT / 'web/icons/Icon-512.png', 512)
    maskable(icon, 512).save(ROOT / 'web/icons/Icon-maskable-512.png', 'PNG', optimize=True)
    made += 4

    for folder, px in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96,
                       'xxhdpi': 144, 'xxxhdpi': 192}.items():
        res = ROOT / 'android/app/src/main/res'
        if res.exists():
            save(icon, res / f'mipmap-{folder}/ic_launcher.png', px)
            made += 1

    iconset = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    contents = iconset / 'Contents.json'
    if contents.exists():
        data = json.loads(contents.read_text(encoding='utf-8'))
        for entry in data.get('images', []):
            name = entry.get('filename')
            if not name:
                continue
            base = float(entry['size'].split('x')[0])
            scale = float(entry['scale'].rstrip('x'))
            save(icon, iconset / name, round(base * scale))
            made += 1

    print(f'Wrote {made} icon files.')
    if not (ROOT / 'android/app/src/main/res').exists():
        print('Android folder not found - run tool/bootstrap_platforms.sh first '
              'if you also need the Android icons.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
