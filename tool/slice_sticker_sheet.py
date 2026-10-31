#!/usr/bin/env python3
"""Cut an AI-generated sticker sheet into one tidy WebP per game item.

Usage (from the project root):
    pip install pillow numpy scipy
    python tool/slice_sticker_sheet.py path/to/sheet.png

The sheet must be a grid of 5 columns x 4 rows, read left to right, top to
bottom, in exactly this order:

    apple   banana   tomato   carrot   flower
    tree    leaf     butterfly bird    rock
    water   toothbrush soap    mirror   book
    lamp    balloon  plate    cup      toy

Each icon is trimmed, centred and saved as assets/items/<id>.webp (512x512,
transparent). If the sheet has a flat plain background instead of transparency
(white is fine), it is removed automatically.
"""
import argparse
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_common import (defringe, key_out_magenta,  # noqa: E402
                        remove_flat_background, split_icons)

ITEM_IDS = [
    'apple', 'banana', 'tomato', 'carrot', 'flower',
    'tree', 'leaf', 'butterfly', 'bird', 'rock',
    'water', 'toothbrush', 'soap', 'mirror', 'book',
    'lamp', 'balloon', 'plate', 'cup', 'toy',
]


def _pixels(image: Image.Image):
    """Pixel values of an image, working on old and new Pillow versions."""
    getter = getattr(image, 'get_flattened_data', None) or image.getdata
    return list(getter())


def _runs(profile, minimum=12):
    """Stretches of the profile where something is drawn (specks are ignored)."""
    found, start = [], None
    for i, value in enumerate(profile):
        if value > 0 and start is None:
            start = i
        elif value == 0 and start is not None:
            found.append((start, i))
            start = None
    if start is not None:
        found.append((start, len(profile)))
    return [r for r in found if r[1] - r[0] >= minimum]


def _merge_to_count(runs, count):
    """Join the closest neighbours until `count` stretches remain.

    This keeps one icon made of detached parts (for example soap with floating
    bubbles) together, while still separating neighbouring icons.
    """
    runs = list(runs)
    while len(runs) > count:
        gaps = [runs[i + 1][0] - runs[i][1] for i in range(len(runs) - 1)]
        i = gaps.index(min(gaps))
        runs[i:i + 2] = [(runs[i][0], runs[i + 1][1])]
    return runs if len(runs) == count else None


def detect_layout(sheet: Image.Image, cols: int, rows: int):
    """Find where each icon really is, even if the AI's grid is uneven.

    Returns one (left, top, right, bottom) box per icon in reading order, or
    None if the sheet does not split cleanly into rows x cols separate icons.
    `sheet` must already have a transparent background.
    """
    alpha = sheet.getchannel('A').point(lambda a: 255 if a > 12 else 0)
    width, height = alpha.size
    row_runs = _merge_to_count(
        _runs(_pixels(alpha.resize((1, height), Image.BOX))), rows)
    if row_runs is None:
        return None
    boxes = []
    for top, bottom in row_runs:
        band = alpha.crop((0, top, width, bottom))
        col_runs = _merge_to_count(
            _runs(_pixels(band.resize((width, 1), Image.BOX))), cols)
        if col_runs is None:
            return None
        boxes.extend((left, top, right, bottom) for left, right in col_runs)
    return boxes


def tidy(cell: Image.Image, size: int, padding: float) -> Image.Image:
    alpha = cell.getchannel('A').point(lambda a: 255 if a > 12 else 0)
    box = alpha.getbbox()
    if box is None:
        return Image.new('RGBA', (size, size), (0, 0, 0, 0))
    icon = cell.crop(box)
    inner = int(size * (1 - 2 * padding))
    icon.thumbnail((inner, inner), Image.LANCZOS)
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(
        icon, ((size - icon.width) // 2, (size - icon.height) // 2)
    )
    return canvas


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('sheet', help='the sticker sheet image (png/jpg/webp)')
    parser.add_argument('--cols', type=int, default=5)
    parser.add_argument('--rows', type=int, default=4)
    parser.add_argument('--out', default='assets/items')
    parser.add_argument('--size', type=int, default=512)
    parser.add_argument('--padding', type=float, default=0.06)
    parser.add_argument('--fixed-grid', action='store_true',
                        help='cut into equal cells instead of detecting icons')
    parser.add_argument('--tolerance', type=int, default=40,
                        help='how different from the background colour a pixel '
                             'may be and still be removed (default 40)')
    args = parser.parse_args()

    if args.cols * args.rows != len(ITEM_IDS):
        print(f'The grid must hold exactly {len(ITEM_IDS)} icons.', file=sys.stderr)
        return 1

    sheet = Image.open(args.sheet).convert('RGBA')
    has_transparency = sheet.getchannel('A').getextrema()[0] < 250
    if not has_transparency:
        # Remove the plain background once, from all four corners of the sheet.
        sheet = key_out_magenta(sheet)

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    icons = None if args.fixed_grid else split_icons(sheet, args.cols, args.rows)
    if icons is not None:
        boxes = None
    else:
        boxes = None if args.fixed_grid else detect_layout(sheet, args.cols, args.rows)
        if boxes is None:
            if not args.fixed_grid:
                print('Could not find a clean grid of separate icons, so the sheet '
                      'is being cut into equal cells instead. If icons look cut off, '
                      'regenerate the sheet with more space between icons.')
            cell_w = sheet.width // args.cols
            cell_h = sheet.height // args.rows
            boxes = [((i % args.cols) * cell_w, (i // args.cols) * cell_h,
                      (i % args.cols + 1) * cell_w, (i // args.cols + 1) * cell_h)
                     for i in range(len(ITEM_IDS))]
        icons = [sheet.crop(box) for box in boxes]

    empty = []
    for item_id, piece in zip(ITEM_IDS, icons):
        icon = tidy(piece, args.size, args.padding)
        if icon.getchannel('A').getbbox() is None:
            empty.append(item_id)
        icon.save(out / f'{item_id}.webp', 'WEBP', quality=92, method=6)

    print(f'Saved {len(ITEM_IDS)} icons to {out}/')
    if empty:
        print('WARNING: these cells looked empty - check the sheet layout: '
              + ', '.join(empty), file=sys.stderr)
        return 2
    return 0


if __name__ == '__main__':
    sys.exit(main())
