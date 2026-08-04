#!/usr/bin/env python3
"""Short space animation for interactive shell startup.

Draws orbiting planets around a sun over a starfield, then exits cleanly.
Runs for ~3 seconds and clears itself afterwards.

Skip via env var:  SKIP_BOOT_ANIM=1
Longer duration:   BOOT_ANIM_DURATION=6 (seconds, float ok)
"""
from __future__ import annotations

import math
import os
import random
import shutil
import signal
import sys
import time

# ANSI escape sequences
RESET = "\033[0m"
DIM = "\033[2m"
BOLD = "\033[1m"
HIDE_CURSOR = "\033[?25l"
SHOW_CURSOR = "\033[?25h"
CLEAR = "\033[2J\033[H"

# Colors (256-color palette for smoother look)
C_SUN = "\033[1;38;5;214m"      # bold amber
C_CORONA = "\033[38;5;208m"     # dim orange
C_PLANET_1 = "\033[38;5;220m"   # gold
C_PLANET_2 = "\033[38;5;51m"    # cyan
C_PLANET_3 = "\033[38;5;213m"   # pink
C_PLANET_4 = "\033[38;5;39m"    # blue
C_STAR_DIM = "\033[38;5;240m"   # grey
C_STAR_MID = "\033[38;5;250m"   # light grey
C_STAR_HI = "\033[1;38;5;255m"  # bold white


def restore_terminal() -> None:
    sys.stdout.write(SHOW_CURSOR + RESET)
    sys.stdout.flush()


def should_skip() -> bool:
    if os.environ.get("SKIP_BOOT_ANIM"):
        return True
    if not sys.stdout.isatty():
        return True
    return False


def main() -> int:
    if should_skip():
        return 0

    duration_env = os.environ.get("BOOT_ANIM_DURATION", "3")
    try:
        duration = max(0.5, float(duration_env))
    except ValueError:
        duration = 3.0

    cols, rows = shutil.get_terminal_size((80, 24))
    # Cap size so wide terminals don't get an oversized banner
    w = min(cols, 72)
    h = min(rows, 18)
    if w < 30 or h < 10:
        # Too small to be worth animating; bail silently
        return 0

    cx, cy = w // 2, h // 2

    # Planets: (radius_x, radius_y, angular_speed, phase, char, color)
    # rx/ry differ because terminal cells are ~2x taller than wide;
    # ry roughly half of rx keeps orbits looking circular.
    planets = [
        (5, 2, 3.2, 0.0, ".", C_PLANET_1),
        (10, 4, 2.1, 1.4, "o", C_PLANET_2),
        (16, 6, 1.3, 2.7, "O", C_PLANET_3),
        (22, 8, 0.8, 4.1, "*", C_PLANET_4),
    ]
    # Filter planets that won't fit in the drawing area
    planets = [p for p in planets if p[0] <= cx - 1 and p[1] <= cy - 1]

    # Starfield: random background stars at fixed positions
    random.seed(42)  # stable pattern each boot
    star_count = int(w * h * 0.06)
    stars: list[tuple[int, int, str, str]] = []
    for _ in range(star_count):
        x = random.randint(0, w - 1)
        y = random.randint(0, h - 1)
        # Skip the immediate sun area so it doesn't clash
        if abs(x - cx) <= 1 and abs(y - cy) <= 1:
            continue
        brightness = random.random()
        if brightness < 0.6:
            ch, color = ".", C_STAR_DIM
        elif brightness < 0.9:
            ch, color = "·", C_STAR_MID
        else:
            ch, color = "*", C_STAR_HI
        stars.append((x, y, ch, color))

    # SIGINT handler so Ctrl+C cleans up
    def on_sigint(_signum, _frame):
        restore_terminal()
        sys.exit(130)

    signal.signal(signal.SIGINT, on_sigint)

    sys.stdout.write(HIDE_CURSOR)
    sys.stdout.flush()

    fps = 30
    frame_dt = 1.0 / fps
    start = time.monotonic()

    try:
        while True:
            now = time.monotonic()
            t = now - start
            if t >= duration:
                break

            # Build blank grid
            grid: list[list[str]] = [[" "] * w for _ in range(h)]
            colors: list[list[str]] = [[""] * w for _ in range(h)]

            # Starfield (drawn first so planets/sun overwrite)
            for sx, sy, ch, color in stars:
                grid[sy][sx] = ch
                colors[sy][sx] = color

            # Sun corona (twinkles slightly)
            corona_pulse = 0.5 + 0.5 * math.sin(t * 4.0)
            if corona_pulse > 0.5:
                for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    yy, xx = cy + dy, cx + dx
                    if 0 <= xx < w and 0 <= yy < h:
                        grid[yy][xx] = "+"
                        colors[yy][xx] = C_CORONA

            # Sun core
            grid[cy][cx] = "@"
            colors[cy][cx] = C_SUN

            # Planets
            for rx, ry, speed, phase, ch, color in planets:
                angle = t * speed + phase
                x = int(round(cx + rx * math.cos(angle)))
                y = int(round(cy + ry * math.sin(angle)))
                if 0 <= x < w and 0 <= y < h:
                    grid[y][x] = ch
                    colors[y][x] = color

            # Render
            parts: list[str] = [CLEAR]
            for row_idx in range(h):
                for col_idx in range(w):
                    ch = grid[row_idx][col_idx]
                    color = colors[row_idx][col_idx]
                    if color and ch != " ":
                        parts.append(color + ch + RESET)
                    else:
                        parts.append(ch)
                parts.append("\n")
            sys.stdout.write("".join(parts))
            sys.stdout.flush()

            # Sleep until next frame
            elapsed = time.monotonic() - now
            if elapsed < frame_dt:
                time.sleep(frame_dt - elapsed)

        # Clear the animation area so the prompt starts on a clean screen
        sys.stdout.write(CLEAR)
    finally:
        restore_terminal()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
