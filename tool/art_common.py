"""Small helpers shared by the artwork scripts (needs: pip install pillow)."""
from PIL import Image, ImageDraw, ImageFilter


def remove_flat_background(image: Image.Image, tolerance: int = 40) -> Image.Image:
    """Make a flat background transparent by flooding in from the corners.

    Works for any single flat colour (magenta is best). Pixels trapped inside
    the artwork (for example a white highlight) are left alone.
    """
    image = image.convert('RGBA')
    w, h = image.size
    for seed in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]:
        if image.getpixel(seed)[3] == 0:
            continue
        ImageDraw.floodfill(image, seed, (255, 255, 255, 0), thresh=tolerance)
    return image


def defringe(image: Image.Image, amount: int = 1) -> Image.Image:
    """Trim the thin coloured halo left around cut-out edges."""
    if amount <= 0:
        return image
    r, g, b, a = image.split()
    for _ in range(amount):
        a = a.filter(ImageFilter.MinFilter(3))
    a = a.filter(ImageFilter.GaussianBlur(0.6))
    return Image.merge('RGBA', (r, g, b, a))


def fit_into(icon: Image.Image, width: int, height: int, padding: float = 0.04,
             align: str = 'center') -> Image.Image:
    """Trim transparent edges, scale to fit and place on a transparent canvas."""
    box = icon.getchannel('A').point(lambda v: 255 if v > 12 else 0).getbbox()
    canvas = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    if box is None:
        return canvas
    art = icon.crop(box)
    max_w = int(width * (1 - 2 * padding))
    max_h = int(height * (1 - 2 * padding))
    art.thumbnail((max_w, max_h), Image.LANCZOS)
    x = (width - art.width) // 2
    y = height - art.height - int(height * padding) if align == 'bottom' \
        else (height - art.height) // 2
    canvas.alpha_composite(art, (x, y))
    return canvas


def key_out_magenta(image: Image.Image, ramp=(55, 120), band: int = 2) -> Image.Image:
    """Clean removal of a flat magenta (#FF00FF) background.

    Better than flood filling because it also clears magenta trapped inside
    the picture (for example between an arm and the body) and replaces the
    pink halo around the edges with the colour of the artwork next to it.

    Needs numpy and scipy (pip install numpy scipy). If they are missing, or the
    background is not magenta, it falls back to :func:`remove_flat_background`.
    """
    try:
        import numpy as np
        from scipy import ndimage
    except ImportError:
        return defringe(remove_flat_background(image), 1)

    rgba = np.array(image.convert('RGBA')).astype(np.int16)
    rgb = rgba[..., :3]
    border = np.concatenate([rgb[0, :], rgb[-1, :], rgb[:, 0], rgb[:, -1]])
    key = np.median(border, axis=0)
    # Not magenta (or the picture is already transparent): use the old method.
    if not (key[0] > 200 and key[2] > 200 and key[1] < 90):
        if rgba[..., 3].min() < 250:
            return image.convert('RGBA')
        return defringe(remove_flat_background(image), 1)

    # "Magenta-ness": high red and blue with low green.
    score = np.minimum(rgb[..., 0], rgb[..., 2]) - rgb[..., 1]
    lo, hi = ramp
    alpha = 1.0 - np.clip((score - lo) / float(hi - lo), 0.0, 1.0)
    alpha *= rgba[..., 3] / 255.0

    solid = alpha >= 0.999
    interior = ndimage.binary_erosion(solid, iterations=band, border_value=1)
    # Near the edge, copy the colour of the closest clean pixel so no pink halo
    # is left behind.
    idx = ndimage.distance_transform_edt(~interior, return_distances=False,
                                         return_indices=True)
    cleaned = rgb[idx[0], idx[1]]
    out_rgb = np.where(interior[..., None], rgb, cleaned)

    alpha = ndimage.gaussian_filter(alpha, 0.6)
    alpha = np.clip(alpha, 0.0, 1.0)
    # Drop stray specks of leftover noise.
    labels, count = ndimage.label(alpha > 0.5)
    if count > 1:
        sizes = ndimage.sum(np.ones_like(labels), labels, range(1, count + 1))
        keep = np.isin(labels, [i + 1 for i, n in enumerate(sizes) if n >= 40])
        alpha = alpha * ndimage.binary_dilation(keep, iterations=2)

    result = np.dstack([np.clip(out_rgb, 0, 255), alpha * 255.0]).astype(np.uint8)
    return Image.fromarray(result, 'RGBA')


def split_icons(image: Image.Image, cols: int, rows: int, min_pixels: int = 60):
    """Find each icon on a keyed-out sheet, even if the grid is uneven or tight.

    Every connected shape is assigned to the grid cell that holds its centre, so
    an icon made of several pieces (for example soap with floating bubbles)
    stays together, and neighbours never leak into each other's picture.

    Returns a list of `cols * rows` transparent images in reading order, or None
    if the sheet does not contain exactly one group per cell.
    Needs numpy and scipy.
    """
    try:
        import numpy as np
        from scipy import ndimage
    except ImportError:
        return None

    rgba = np.array(image.convert('RGBA'))
    alpha = rgba[..., 3]
    labels, count = ndimage.label(alpha > 128, structure=np.ones((3, 3)))
    if count == 0:
        return None
    height, width = alpha.shape
    cell_w, cell_h = width / cols, height / rows
    groups = {}
    for lab, sl in enumerate(ndimage.find_objects(labels), start=1):
        size = int((labels[sl] == lab).sum())
        if size < min_pixels:
            continue
        ys, xs = np.nonzero(labels[sl] == lab)
        cx = xs.mean() + sl[1].start
        cy = ys.mean() + sl[0].start
        col = min(cols - 1, int(cx // cell_w))
        row = min(rows - 1, int(cy // cell_h))
        groups.setdefault(row * cols + col, []).append(lab)
    if len(groups) != cols * rows:
        return None

    icons = []
    for index in range(cols * rows):
        mask = np.isin(labels, groups[index])
        mask = ndimage.binary_dilation(mask, iterations=2)  # keep soft edges
        piece = rgba.copy()
        piece[..., 3] = np.where(mask, alpha, 0)
        ys, xs = np.nonzero(piece[..., 3] > 12)
        box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
        icons.append(Image.fromarray(piece, 'RGBA').crop(box))
    return icons
