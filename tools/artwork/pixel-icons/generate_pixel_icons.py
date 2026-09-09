#!/usr/bin/env python3
"""Minecraft-style 32x32 fitness icons, nearest-neighbor scaled to 512 PNG."""

from __future__ import annotations

import struct
import zlib
import shutil
from pathlib import Path

SIZE = 32
SCALE = 16  # 32 * 16 = 512

PALETTE = {
    '.': None,
    'K': (0x2B, 0x2B, 0x2B, 255),
    'W': (0xF2, 0xF2, 0xF2, 255),
    'L': (0xD0, 0xD0, 0xD0, 255),
    'M': (0x96, 0x96, 0x96, 255),
    'D': (0x5A, 0x5A, 0x5A, 255),
    'N': (0x3A, 0x3A, 0x3A, 255),
    'H': (0xA8, 0xE8, 0xD4, 255),
    'G': (0x1F, 0x8A, 0x70, 255),
    'S': (0x14, 0x63, 0x53, 255),
}

OUT = Path(__file__).resolve().parent
ROOT = Path(__file__).resolve().parents[3]
APP_ICON_NAME = 'barbell'
APP_ICON_TARGETS = (
    ROOT / 'AppScope/resources/base/media/app_icon.png',
    ROOT / 'entry/src/main/resources/base/media/app_icon.png',
    ROOT / 'entry/src/main/resources/base/media/startIcon.png',
)


def new_grid() -> list[list[str]]:
    return [['.' for _ in range(SIZE)] for _ in range(SIZE)]


def setp(g: list[list[str]], x: int, y: int, c: str) -> None:
    if 0 <= x < SIZE and 0 <= y < SIZE:
        g[y][x] = c


def getp(g: list[list[str]], x: int, y: int) -> str:
    if 0 <= x < SIZE and 0 <= y < SIZE:
        return g[y][x]
    return '.'


def filled(c: str) -> bool:
    return c != '.'


def in_ellipse(x: float, y: float, cx: float, cy: float, rx: float, ry: float) -> bool:
    if rx <= 0 or ry <= 0:
        return False
    return ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0


def iron_from_light(t: float) -> str:
    if t > 0.55:
        return 'W'
    if t > 0.18:
        return 'L'
    if t > -0.22:
        return 'M'
    if t > -0.58:
        return 'D'
    return 'N'


def green_from_light(t: float) -> str:
    if t > 0.35:
        return 'H'
    if t > -0.2:
        return 'G'
    return 'S'


def add_outline(g: list[list[str]], color: str = 'K') -> None:
    extra: list[tuple[int, int]] = []
    for y in range(SIZE):
        for x in range(SIZE):
            if not filled(g[y][x]):
                continue
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, -1), (-1, 1), (1, 1)):
                nx, ny = x + dx, y + dy
                if getp(g, nx, ny) == '.':
                    extra.append((nx, ny))
    for x, y in extra:
        setp(g, x, y, color)


def fill_ellipse(g: list[list[str]], cx: float, cy: float, rx: float, ry: float, color_fn) -> None:
    for y in range(SIZE):
        for x in range(SIZE):
            if in_ellipse(x + 0.5, y + 0.5, cx, cy, rx, ry):
                setp(g, x, y, color_fn(x, y))


def punch_ellipse(g: list[list[str]], cx: float, cy: float, rx: float, ry: float) -> None:
    for y in range(SIZE):
        for x in range(SIZE):
            if in_ellipse(x + 0.5, y + 0.5, cx, cy, rx, ry):
                setp(g, x, y, '.')


def draw_iso_disc(
    g: list[list[str]],
    cx: float,
    cy: float,
    rx: float,
    ry: float,
    thick: int,
    hole_rx: float = 0,
    hole_ry: float = 0,
    ring: bool = False,
    ring_inner: float = 0.62,
) -> None:
    # Side / thickness, front half only.
    for y in range(SIZE):
        for x in range(SIZE):
            on_side = False
            for t in range(1, thick + 1):
                if in_ellipse(x + 0.5, y + 0.5, cx, cy + t, rx, ry):
                    on_side = True
                    break
            if on_side and not in_ellipse(x + 0.5, y + 0.5, cx, cy, rx, ry) and y >= cy:
                setp(g, x, y, 'N' if y >= cy + thick - 1 else 'D')

    def top_color(x: int, y: int) -> str:
        nx = (x - cx) / max(rx, 1)
        ny = (y - cy) / max(ry, 1)
        t = -nx * 0.5 - ny * 0.85
        r2 = ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2
        if ring and r2 >= ring_inner:
            return green_from_light(t)
        return iron_from_light(t)

    fill_ellipse(g, cx, cy, rx, ry, top_color)

    if hole_rx > 0 and hole_ry > 0:
        # Inner wall on the lower lip of the hole.
        for y in range(SIZE):
            for x in range(SIZE):
                in_top = in_ellipse(x + 0.5, y + 0.5, cx, cy, hole_rx, hole_ry)
                in_wall = in_ellipse(x + 0.5, y + 0.5, cx, cy + 1.2, hole_rx + 0.4, hole_ry + 0.35)
                if in_wall and not in_top and y >= cy and filled(getp(g, x, y)):
                    setp(g, x, y, 'N')
        punch_ellipse(g, cx, cy, hole_rx, hole_ry)


def draw_bar_x(g: list[list[str]], x0: int, x1: int, cy: int, r: int, grip: tuple[int, int] | None = None) -> None:
    for y in range(SIZE):
        for x in range(SIZE):
            inside = False
            if x0 <= x <= x1 and abs(y - cy) <= r:
                inside = True
            elif in_ellipse(x + 0.5, y + 0.5, x0, cy, r * 0.7, r + 0.2):
                inside = True
            elif in_ellipse(x + 0.5, y + 0.5, x1, cy, r * 0.7, r + 0.2):
                inside = True
            if not inside:
                continue
            t = (cy - y) / max(r, 1)
            if grip and grip[0] <= x <= grip[1]:
                setp(g, x, y, green_from_light(t))
            else:
                setp(g, x, y, iron_from_light(t))


def draw_hex_weight(g: list[list[str]], x0: int, x1: int, cy: int, r: int) -> None:
    """Hex dumbbell head with a 3/4 top face."""
    for y in range(SIZE):
        for x in range(SIZE):
            dx_left = x - x0
            dx_right = x1 - x
            taper = 0
            if dx_left == 0 or dx_right == 0:
                taper = 3
            elif dx_left == 1 or dx_right == 1:
                taper = 1
            rr = max(r - taper, 2)
            if x0 <= x <= x1 and abs(y - cy) <= rr:
                t = (cy - y) / max(rr, 1)
                if x <= x0 + 1:
                    t += 0.28
                if x >= x1 - 1:
                    t -= 0.22
                setp(g, x, y, iron_from_light(t))
    # Top face (one row of highlight, sheared right for 3/4).
    top = cy - r
    for x in range(x0 + 1, x1):
        setp(g, x + 1, top - 1, 'W')
        setp(g, x, top, 'L')


def draw_standing_plate(
    g: list[list[str]],
    cx: float,
    cy: float,
    rx: float,
    ry: float,
    thick: int,
    ring: bool = False,
) -> None:
    """Disc seen from 3/4: tall face + thickness to the right."""
    for t in range(thick, 0, -1):
        ox = cx + t

        def side_color(_x: int, y: int) -> str:
            return 'N' if t == thick else 'D'

        fill_ellipse(g, ox, cy, rx, ry, side_color)

    def face_color(x: int, y: int) -> str:
        tt = -(x - cx) * 0.25 / max(rx, 1) - (y - cy) * 0.9 / max(ry, 1)
        r2 = ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2
        if ring and r2 >= 0.5:
            return green_from_light(tt)
        return iron_from_light(tt)

    fill_ellipse(g, cx, cy, rx, ry, face_color)


def icon_dumbbell() -> list[list[str]]:
    g = new_grid()
    draw_hex_weight(g, 3, 9, 16, 7)
    draw_bar_x(g, 9, 22, 16, 2, grip=(13, 18))
    draw_hex_weight(g, 22, 28, 16, 7)
    add_outline(g)
    return g


def icon_kettlebell() -> list[list[str]]:
    g = new_grid()
    cx, cy, rx, ry = 16.0, 21.0, 10.0, 8.6

    def body_color(x: int, y: int) -> str:
        t = -(x - cx) * 0.4 / rx - (y - cy) * 0.85 / ry
        return iron_from_light(t)

    fill_ellipse(g, cx, cy, rx, ry, body_color)

    # Iron posts.
    for y in range(8, 15):
        t = (12 - y) / 8
        for x in (10, 11, 12):
            setp(g, x, y, iron_from_light(t + (11 - x) * 0.15))
        for x in (20, 21, 22):
            setp(g, x, y, iron_from_light(t - 0.15))

    # Solid handle crown + green tape. Do not punch the top.
    for x in range(10, 23):
        setp(g, x, 5, 'H' if 12 <= x <= 20 else 'G')
        setp(g, x, 6, 'G')
        setp(g, x, 7, 'S' if 12 <= x <= 20 else 'D')
    setp(g, 10, 5, '.')
    setp(g, 22, 5, '.')
    setp(g, 11, 5, 'G')
    setp(g, 21, 5, 'G')

    add_outline(g)
    return g


def icon_barbell() -> list[list[str]]:
    g = new_grid()
    draw_bar_x(g, 2, 29, 16, 1)
    draw_standing_plate(g, 3.5, 16.0, 1.8, 8.0, 2, ring=False)
    draw_standing_plate(g, 7.5, 16.0, 1.6, 6.8, 2, ring=True)
    draw_standing_plate(g, 23.5, 16.0, 1.6, 6.8, 2, ring=True)
    draw_standing_plate(g, 27.0, 16.0, 1.8, 8.0, 2, ring=False)
    for x in (10, 21):
        for y in range(14, 19):
            setp(g, x, y, green_from_light((16 - y) / 2))
    add_outline(g)
    return g


def icon_weight_plate() -> list[list[str]]:
    g = new_grid()
    draw_iso_disc(g, 16.0, 14.0, 13.0, 7.4, 5, hole_rx=4.0, hole_ry=2.4, ring=True, ring_inner=0.58)
    add_outline(g)
    return g


def grid_to_rgba(g: list[list[str]], scale: int) -> tuple[bytes, int, int]:
    w = SIZE * scale
    h = SIZE * scale
    out = bytearray(w * h * 4)
    for y in range(SIZE):
        for x in range(SIZE):
            px = PALETTE[g[y][x]]
            if px is None:
                rgba = (0, 0, 0, 0)
            else:
                rgba = px
            for sy in range(scale):
                for sx in range(scale):
                    i = ((y * scale + sy) * w + (x * scale + sx)) * 4
                    out[i:i + 4] = bytes(rgba)
    return bytes(out), w, h


def write_png(path: Path, rgba: bytes, w: int, h: int) -> None:
    def chunk(tag: bytes, data: bytes) -> bytes:
        crc = zlib.crc32(tag + data) & 0xFFFFFFFF
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', crc)

    raw = b''.join(b'\x00' + rgba[y * w * 4:(y + 1) * w * 4] for y in range(h))
    png = (
        b'\x89PNG\r\n\x1a\n'
        + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0))
        + chunk(b'IDAT', zlib.compress(raw, 9))
        + chunk(b'IEND', b'')
    )
    path.write_bytes(png)


def write_preview(icons: list[tuple[str, list[list[str]]]]) -> None:
    tile = 160
    gap = 16
    cols = 2
    rows = 2
    w = cols * tile + (cols + 1) * gap
    h = rows * tile + (rows + 1) * gap
    rgba = bytearray(w * h * 4)
    # Dark checkerboard so transparency is visible.
    for y in range(h):
        for x in range(w):
            cell = ((x // 8) + (y // 8)) & 1
            c = 36 if cell else 28
            i = (y * w + x) * 4
            rgba[i:i + 4] = bytes((c, c, c, 255))

    for idx, (_name, g) in enumerate(icons):
        col, row = idx % cols, idx // cols
        ox = gap + col * (tile + gap)
        oy = gap + row * (tile + gap)
        img, iw, ih = grid_to_rgba(g, 5)  # 160
        for y in range(ih):
            for x in range(iw):
                src = (y * iw + x) * 4
                a = img[src + 3]
                if a == 0:
                    continue
                dx, dy = ox + x, oy + y
                dst = (dy * w + dx) * 4
                rgba[dst:dst + 4] = img[src:src + 4]
    write_png(OUT / 'preview.png', bytes(rgba), w, h)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    icons = [
        ('dumbbell', icon_dumbbell()),
        ('kettlebell', icon_kettlebell()),
        ('barbell', icon_barbell()),
        ('weight_plate', icon_weight_plate()),
    ]
    for name, g in icons:
        rgba, w, h = grid_to_rgba(g, SCALE)
        write_png(OUT / f'{name}.png', rgba, w, h)
        native, nw, nh = grid_to_rgba(g, 1)
        write_png(OUT / f'{name}_32.png', native, nw, nh)
    write_preview(icons)
    source = OUT / f'{APP_ICON_NAME}.png'
    for dest in APP_ICON_TARGETS:
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, dest)
    print(f'wrote {len(icons)} icons + preview to {OUT}')
    print(f'installed {APP_ICON_NAME} as app_icon / startIcon')


if __name__ == '__main__':
    main()
