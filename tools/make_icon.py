"""Генератор иконки EndoGram (без внешних зависимостей).

Рисует градиентный фон в стиле Telegram и белый бумажный самолётик,
сохраняет PNG 1024×1024 в Resources/Assets.xcassets/AppIcon.appiconset.

Запуск: python tools/make_icon.py
"""

from __future__ import annotations

import math
import os
import struct
import zlib

SIZE = 1024
OUT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "Resources",
    "Assets.xcassets",
    "AppIcon.appiconset",
    "AppIcon1024.png",
)

TOP = (0x2A, 0xAB, 0xEE)
BOTTOM = (0x1A, 0x76, 0xC2)


def lerp(a: int, b: int, t: float) -> int:
    return int(round(a + (b - a) * t))


def in_polygon(x: float, y: float, points: list[tuple[float, float]]) -> bool:
    inside = False
    count = len(points)
    for i in range(count):
        x1, y1 = points[i]
        x2, y2 = points[(i + 1) % count]
        if (y1 > y) != (y2 > y):
            xcross = x1 + (y - y1) * (x2 - x1) / (y2 - y1)
            if x < xcross:
                inside = not inside
    return inside


def rotate(points: list[tuple[float, float]], degrees: float, cx: float, cy: float):
    rad = math.radians(degrees)
    cos, sin = math.cos(rad), math.sin(rad)
    out = []
    for x, y in points:
        dx, dy = x - cx, y - cy
        out.append((cx + dx * cos - dy * sin, cy + dx * sin + dy * cos))
    return out


def plane_polygons():
    """Два полигона: корпус самолётика и «срез» крыла (тёмная складка)."""
    body = [(150, 500), (880, 210), (640, 830), (505, 640), (415, 760), (400, 590)]
    notch = [(150, 500), (520, 596), (880, 210)]
    return body, notch


def build_pixels() -> bytearray:
    body, notch = plane_polygons()
    body = rotate(body, -8, 512, 512)
    notch = rotate(notch, -8, 512, 512)

    rows = bytearray()
    for y in range(SIZE):
        rows.append(0)  # PNG-фильтр None
        t = y / (SIZE - 1)
        base = (lerp(TOP[0], BOTTOM[0], t), lerp(TOP[1], BOTTOM[1], t), lerp(TOP[2], BOTTOM[2], t))
        for x in range(SIZE):
            if in_polygon(x + 0.5, y + 0.5, body):
                if in_polygon(x + 0.5, y + 0.5, notch):
                    shade = 0.82
                else:
                    shade = 1.0
                r, g, b = (int(255 * shade), int(255 * shade), int(255 * shade))
            else:
                # мягкий диагональный блик
                glow = max(0.0, 1.0 - math.hypot(x - 300, y - 240) / 900.0) * 0.12
                r = min(255, int(base[0] + 255 * glow))
                g = min(255, int(base[1] + 255 * glow))
                b = min(255, int(base[2] + 255 * glow))
            rows += bytes((r, g, b, 255))
    return rows


def chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def main() -> None:
    raw = build_pixels()
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "wb") as handle:
        handle.write(png)
    print(f"Готово: {OUT} ({len(png)} байт)")


if __name__ == "__main__":
    main()
