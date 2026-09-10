#!/usr/bin/env python3
"""Procedural SFX + ambient loop for Hop. Run: python3 tool/generate_audio.py"""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio"
SR = 44100


def write_wav(path: Path, samples: list[float], sr: int = SR) -> None:
    data = bytearray()
    for s in samples:
        v = max(-1.0, min(1.0, s))
        data += struct.pack("<h", int(v * 32767))
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data)
    print(f"wrote {path.relative_to(ROOT)} ({len(samples) / sr:.3f}s)")


def env(i: int, n: int, a=0.01, d=0.08, s=0.6, r=0.2) -> float:
    t = i / n
    if t < a:
        return t / a
    if t < a + d:
        return 1.0 - (1.0 - s) * ((t - a) / d)
    if t < 1.0 - r:
        return s
    return s * max(0.0, (1.0 - t) / r)


def tone(freq, dur, vol=0.5, kind="sine", a=0.01, d=0.08, s=0.55, r=0.25, slide=0.0):
    n = int(SR * dur)
    out = []
    ph = 0.0
    for i in range(n):
        f = freq * (1.0 + slide * (i / max(1, n - 1)))
        ph += 2 * math.pi * f / SR
        if kind == "tri":
            v = 2 * abs(2 * ((ph / (2 * math.pi)) % 1) - 1) - 1
        elif kind == "square":
            v = 1.0 if math.sin(ph) > 0 else -1.0
        else:
            v = math.sin(ph)
        out.append(v * vol * env(i, n, a, d, s, r))
    return out


def noise(dur, vol=0.3, a=0.005, d=0.05, s=0.4, r=0.4, tint=8000.0, seed=42):
    n = int(SR * dur)
    out = []
    y = 0.0
    alpha = math.exp(-2 * math.pi * tint / SR)
    rng = random.Random(seed)
    for i in range(n):
        x = rng.uniform(-1, 1)
        y = alpha * y + (1 - alpha) * x
        out.append(y * vol * env(i, n, a, d, s, r))
    return out


def mix(*tracks: list[float]) -> list[float]:
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    peak = max(1e-9, max(abs(x) for x in out))
    if peak > 0.95:
        scale = 0.95 / peak
        out = [x * scale for x in out]
    return out


def add_at(base: list[float], clip: list[float], at_sec: float) -> list[float]:
    start = int(at_sec * SR)
    out = list(base)
    end = start + len(clip)
    if end > len(out):
        out.extend([0.0] * (end - len(out)))
    for i, v in enumerate(clip):
        out[start + i] += v
    return out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    write_wav(
        OUT / "hop.wav",
        mix(
            tone(880, 0.07, 0.28, a=0.004, d=0.03, s=0.4, r=0.45, slide=0.18),
            tone(1320, 0.05, 0.12, a=0.004, d=0.02, s=0.3, r=0.5, slide=0.1),
        ),
    )
    write_wav(
        OUT / "step.wav",
        mix(
            tone(620, 0.045, 0.18, a=0.003, d=0.02, s=0.35, r=0.5),
            noise(0.04, 0.08, a=0.002, d=0.01, s=0.3, r=0.6, tint=3000),
        ),
    )
    write_wav(
        OUT / "leap.wav",
        mix(
            tone(660, 0.09, 0.22, a=0.005, d=0.04, s=0.45, r=0.4, slide=0.35),
            tone(990, 0.11, 0.2, a=0.01, d=0.05, s=0.35, r=0.45, slide=0.25),
            tone(1480, 0.07, 0.1, a=0.02, d=0.03, s=0.25, r=0.5),
        ),
    )
    write_wav(
        OUT / "pad.wav",
        mix(
            tone(740, 0.1, 0.2, a=0.008, d=0.04, s=0.4, r=0.5, slide=0.2),
            noise(0.12, 0.14, a=0.005, d=0.03, s=0.35, r=0.55, tint=2200),
            tone(1180, 0.08, 0.1, a=0.02, d=0.03, s=0.3, r=0.5),
        ),
    )
    write_wav(
        OUT / "land.wav",
        mix(
            tone(180, 0.08, 0.32, a=0.002, d=0.04, s=0.35, r=0.55, slide=-0.25),
            tone(320, 0.05, 0.12, a=0.002, d=0.02, s=0.25, r=0.6),
            noise(0.05, 0.1, a=0.001, d=0.015, s=0.25, r=0.6, tint=1800),
        ),
    )
    write_wav(
        OUT / "bonk.wav",
        mix(
            tone(140, 0.09, 0.35, a=0.001, d=0.03, s=0.3, r=0.55, slide=-0.2),
            tone(210, 0.07, 0.18, a=0.001, d=0.025, s=0.25, r=0.55),
            noise(0.06, 0.12, a=0.001, d=0.02, s=0.25, r=0.55, tint=1200),
        ),
    )
    write_wav(
        OUT / "collect.wav",
        mix(
            tone(1046.5, 0.12, 0.22, a=0.002, d=0.05, s=0.45, r=0.55),
            tone(1568, 0.16, 0.18, a=0.01, d=0.06, s=0.4, r=0.55),
            tone(2093, 0.2, 0.12, a=0.02, d=0.07, s=0.35, r=0.6),
        ),
    )
    write_wav(
        OUT / "near.wav",
        mix(
            tone(420, 0.14, 0.12, a=0.01, d=0.05, s=0.3, r=0.55, slide=-0.45),
            noise(0.16, 0.18, a=0.01, d=0.04, s=0.35, r=0.55, tint=3500),
        ),
    )
    write_wav(
        OUT / "splash.wav",
        mix(
            noise(0.35, 0.35, a=0.005, d=0.08, s=0.45, r=0.55, tint=1600),
            noise(0.28, 0.22, a=0.02, d=0.1, s=0.35, r=0.55, tint=900, seed=9),
            tone(220, 0.22, 0.15, a=0.01, d=0.08, s=0.3, r=0.55, slide=-0.4),
        ),
    )
    write_wav(
        OUT / "flatten.wav",
        mix(
            tone(260, 0.18, 0.35, a=0.001, d=0.05, s=0.4, r=0.55, slide=-0.55),
            tone(90, 0.22, 0.4, a=0.001, d=0.06, s=0.35, r=0.55, slide=-0.35),
            noise(0.2, 0.22, a=0.001, d=0.05, s=0.35, r=0.55, tint=1400),
        ),
    )
    write_wav(
        OUT / "combo.wav",
        mix(
            tone(784, 0.08, 0.16, a=0.002, d=0.03, s=0.4, r=0.5),
            tone(988, 0.1, 0.16, a=0.03, d=0.04, s=0.4, r=0.5),
            tone(1175, 0.14, 0.18, a=0.06, d=0.05, s=0.4, r=0.55),
        ),
    )
    write_wav(
        OUT / "ui.wav",
        mix(
            tone(880, 0.04, 0.16, a=0.002, d=0.015, s=0.35, r=0.55),
            tone(1320, 0.05, 0.1, a=0.008, d=0.02, s=0.3, r=0.55),
        ),
    )
    write_wav(
        OUT / "start.wav",
        mix(
            tone(523.25, 0.12, 0.18, a=0.005, d=0.05, s=0.45, r=0.45),
            tone(659.25, 0.14, 0.16, a=0.04, d=0.05, s=0.4, r=0.5),
            tone(783.99, 0.18, 0.16, a=0.08, d=0.06, s=0.4, r=0.55),
            tone(1046.5, 0.22, 0.12, a=0.12, d=0.08, s=0.35, r=0.55),
        ),
    )
    write_wav(
        OUT / "pad_land.wav",
        mix(
            noise(0.14, 0.16, a=0.005, d=0.04, s=0.35, r=0.55, tint=2000),
            tone(480, 0.1, 0.1, a=0.005, d=0.04, s=0.3, r=0.55, slide=-0.15),
        ),
    )
    print("done")


if __name__ == "__main__":
    main()
