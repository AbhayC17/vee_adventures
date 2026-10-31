#!/usr/bin/env python3
"""Turn raw AI pictures into the exact files the game expects.

Needs:  pip install pillow numpy scipy      (run from the project root)

  Scenes (full backgrounds):
    python tool/prepare_art.py scene raw_meadow.png assets/scenes/bg_meadow.webp

  Vee poses: a folder of pictures on a flat magenta background. All poses are
  cut out and placed on one shared canvas so Vee is the same size in every pose:
    python tool/prepare_art.py poses raw_poses/ assets/vee/

  Single cut-out on a magenta background (an item, a one-off picture):
    python tool/prepare_art.py cutout raw_item.png assets/items/apple.webp --size 512x512 --align center

  Doors and other pictures that are already transparent or on magenta:
    python tool/prepare_art.py trim raw_door.png assets/scenes/door_open.webp
"""
import argparse
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_common import fit_into, key_out_magenta  # noqa: E402


def _bbox(image: Image.Image):
    return image.getchannel('A').point(lambda v: 255 if v > 20 else 0).getbbox()


def scene(args) -> int:
    image = Image.open(args.input).convert('RGB')
    if image.width > 1920:  # never upscale; only shrink very large pictures
        scale = 1920 / image.width
        image = image.resize((1920, round(image.height * scale)), Image.LANCZOS)
    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    image.save(args.output, 'WEBP', quality=88, method=6)
    print(f'Saved {args.output} ({image.width}x{image.height})')
    return 0


def cutout(args) -> int:
    width, height = (int(v) for v in args.size.lower().split('x'))
    image = key_out_magenta(Image.open(args.input))
    result = fit_into(image, width, height, align=args.align)
    if result.getchannel('A').getbbox() is None:
        print('Nothing was left after removing the background. Is it flat magenta?',
              file=sys.stderr)
        return 2
    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    result.save(args.output, 'WEBP', quality=92, method=6)
    print(f'Saved {args.output} ({width}x{height}, transparent)')
    return 0


def trim(args) -> int:
    image = key_out_magenta(Image.open(args.input))
    box = _bbox(image)
    if box is None:
        print('Nothing visible in this picture.', file=sys.stderr)
        return 2
    image = image.crop(box)
    longest = max(image.size)
    if longest > args.max_side:
        scale = args.max_side / longest
        image = image.resize((round(image.width * scale), round(image.height * scale)),
                             Image.LANCZOS)
    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    image.save(args.output, 'WEBP', quality=92, method=6)
    print(f'Saved {args.output} ({image.width}x{image.height}, transparent)')
    return 0


def poses(args) -> int:
    src = Path(args.input)
    files = sorted(p for p in src.iterdir()
                   if p.suffix.lower() in ('.png', '.jpg', '.jpeg', '.webp'))
    if not files:
        print('No pictures found in that folder.', file=sys.stderr)
        return 2
    cut = {}
    for path in files:
        image = key_out_magenta(Image.open(path))
        box = _bbox(image)
        if box is None:
            print(f'Skipping {path.name}: nothing visible.', file=sys.stderr)
            continue
        cut[path] = image.crop(box)
    pad = 8
    canvas_w = max(i.width for i in cut.values()) + 2 * pad
    canvas_h = max(i.height for i in cut.values()) + 2 * pad
    scale = min(1.0, args.max_height / canvas_h)
    out_w, out_h = round(canvas_w * scale), round(canvas_h * scale)
    out = Path(args.output)
    out.mkdir(parents=True, exist_ok=True)
    for path, art in cut.items():
        canvas = Image.new('RGBA', (canvas_w, canvas_h), (0, 0, 0, 0))
        # Centred sideways, standing on the bottom edge, never rescaled
        # individually, so Vee keeps the same size in every pose.
        canvas.alpha_composite(art, ((canvas_w - art.width) // 2,
                                     canvas_h - art.height - pad))
        if scale < 1.0:
            canvas = canvas.resize((out_w, out_h), Image.LANCZOS)
        name = path.stem.replace(' ', '_')
        name = name.split('_(')[0]  # "vee_thinking_(2)" -> "vee_thinking"
        target = out / f'{name}.webp'
        canvas.save(target, 'WEBP', quality=90, method=6)
        print(f'Saved {target} ({out_w}x{out_h})')
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest='mode', required=True)
    s = sub.add_parser('scene', help='convert a background to WebP')
    s.add_argument('input'); s.add_argument('output'); s.set_defaults(run=scene)
    c = sub.add_parser('cutout', help='remove a magenta background and fit a canvas')
    c.add_argument('input'); c.add_argument('output')
    c.add_argument('--size', default='1000x1200')
    c.add_argument('--align', choices=['bottom', 'center'], default='bottom')
    c.set_defaults(run=cutout)
    t = sub.add_parser('trim', help='remove a magenta background and crop to the artwork')
    t.add_argument('input'); t.add_argument('output')
    t.add_argument('--max-side', type=int, default=1100); t.set_defaults(run=trim)
    p = sub.add_parser('poses', help='cut out a whole folder of Vee poses at one size')
    p.add_argument('input'); p.add_argument('output')
    p.add_argument('--max-height', type=int, default=1000); p.set_defaults(run=poses)
    args = parser.parse_args()
    return args.run(args)


if __name__ == '__main__':
    sys.exit(main())
