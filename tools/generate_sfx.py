"""Генерирует звуковые эффекты (WAV, 16 бит, моно) в assets/audio/sfx/.

Запуск: python tools/generate_sfx.py
Внешние библиотеки не нужны. Чтобы поменять звук, правь параметры ниже и запусти заново.
"""
import math
import os
import struct
import wave

RATE = 44100
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio", "sfx")


def sine(p):
    return math.sin(2 * math.pi * p)


def bell(p):
    return sine(p) + 0.4 * sine(2 * p) + 0.15 * sine(3 * p)


def pulse(duty):
    return lambda p: 1.0 if (p % 1.0) < duty else -1.0


def note(freq, dur, wave_fn, volume=1.0, decay=6.0, attack=0.003):
    samples = []
    for i in range(int(RATE * dur)):
        t = i / RATE
        env = min(1.0, t / attack) * math.exp(-decay * t / dur)
        samples.append(wave_fn(freq * t) * env * volume)
    return samples


def mix(parts, total_dur):
    buf = [0.0] * int(RATE * total_dur)
    for offset, samples in parts:
        start = int(RATE * offset)
        for i, s in enumerate(samples):
            if start + i < len(buf):
                buf[start + i] += s
    return buf


def finish(buf, peak=0.7):
    top = max(abs(s) for s in buf) or 1.0
    buf = [s / top * peak for s in buf]
    fade_in = int(RATE * 0.002)
    fade_out = int(RATE * 0.008)
    for i in range(min(fade_in, len(buf))):
        buf[i] *= i / fade_in
    for i in range(min(fade_out, len(buf))):
        buf[-1 - i] *= i / fade_out
    return buf


def save(name, buf):
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name + ".wav")
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in buf))
    print("%-10s %4d ms  peak %.2f" % (name, len(buf) * 1000 // RATE, max(abs(s) for s in buf)))


C5, E5, G5, C6 = 523.25, 659.25, 783.99, 1046.50

# Короткий мягкий щелчок кнопки
save("click", finish(mix([(0, note(740, 0.05, pulse(0.5), decay=5.0))], 0.05), peak=0.45))

# «Дзынь» монет: два колокольчика, второй выше
save("sell", finish(mix([
    (0.00, note(1319, 0.28, bell, decay=7.0)),
    (0.07, note(1976, 0.40, bell, decay=6.0)),
], 0.47)))

# Покупка: быстрое арпеджио вверх
save("purchase", finish(mix([
    (0.00, note(C5, 0.10, pulse(0.25), decay=3.0)),
    (0.07, note(E5, 0.10, pulse(0.25), decay=3.0)),
    (0.14, note(G5, 0.26, pulse(0.25), decay=4.0)),
], 0.42)))

# Новый уровень: фанфара из четырёх нот
save("level_up", finish(mix([
    (0.00, note(C5, 0.12, pulse(0.25), decay=2.5)),
    (0.10, note(E5, 0.12, pulse(0.25), decay=2.5)),
    (0.20, note(G5, 0.12, pulse(0.25), decay=2.5)),
    (0.30, note(C6, 0.50, pulse(0.25), decay=4.0)),
    (0.30, note(C5, 0.50, sine, volume=0.6, decay=4.0)),
], 0.82)))
