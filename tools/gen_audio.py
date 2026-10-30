"""Synthetisiert alle Soundeffekte und Musikstücke für Brummi (numpy/scipy, keine Fremdsamples).

Aufruf: python3 gen_audio.py [name ...]   (ohne Namen wird alles erzeugt)
Ausgabe: assets/audio/sfx/*.wav und assets/audio/music/*.ogg
"""
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

import numpy as np
from scipy.signal import butter, fftconvolve, sosfilt

SR = 44100
TAU = 2 * np.pi
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"
rng = np.random.default_rng(7)


# ---------------------------------------------------------------- Grundbausteine

def n_of(sec):
    return int(sec * SR)


def tt(n):
    return np.arange(n) / SR


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def noise(n):
    return rng.uniform(-1, 1, n)


def decay(n, tau):
    return np.exp(-tt(n) / tau)


def ph(f, n=None):
    """Phase in Radiant; f ist eine Frequenz (mit n) oder eine Frequenzkurve."""
    if np.isscalar(f):
        return TAU * f * tt(n)
    return TAU * np.cumsum(f) / SR


def sine(p):
    return np.sin(p)


def tri(p):
    return 2 / np.pi * np.arcsin(np.sin(p))


def saw(p):
    return 2 * ((p / TAU) % 1.0) - 1


def sq(p, duty=0.5):
    return np.where((p / TAU) % 1.0 < duty, 1.0, -1.0)


def sweep(f0, f1, n):
    return np.geomspace(f0, f1, n)


def kf(times, values, n):
    return np.interp(np.linspace(0, 1, n), times, values)


def lp(x, fc, order=2):
    return sosfilt(butter(order, min(fc, SR * 0.45), "low", fs=SR, output="sos"), x)


def hp(x, fc, order=2):
    return sosfilt(butter(order, fc, "high", fs=SR, output="sos"), x)


def bp(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, min(hi, SR * 0.45)], "band", fs=SR, output="sos"), x)


def sweep_bp(x, f0, f1, width=0.5):
    """Bandpass, dessen Mittenfrequenz über die Zeit wandert (Wusch-Geräusche)."""
    block = 256
    nb = int(np.ceil(len(x) / block))
    freqs = np.geomspace(f0, f1, nb)
    out = np.zeros_like(x)
    zi = None
    for i in range(nb):
        lo = max(freqs[i] * (1 - width), 40.0)
        hi = min(freqs[i] * (1 + width), SR * 0.45)
        sos = butter(2, [lo, hi], "band", fs=SR, output="sos")
        if zi is None:
            zi = np.zeros((sos.shape[0], 2))
        seg = x[i * block:(i + 1) * block]
        out[i * block:i * block + len(seg)], zi = sosfilt(sos, seg, zi=zi)
    return out


def adsr(n, a, d, s, r):
    a_n, d_n, r_n = int(a * SR), int(d * SR), int(r * SR)
    hold = max(n - a_n - d_n - r_n, 0)
    e = np.concatenate([np.linspace(0, 1, a_n, endpoint=False), np.linspace(1, s, d_n, endpoint=False),
                        np.full(hold, s), np.linspace(s, 0, r_n)])
    if len(e) < n:
        e = np.pad(e, (0, n - len(e)))
    return e[:n]


def fade(x, a=0.003, r=0.012):
    x = x.copy()
    an, rn = min(n_of(a), len(x)), min(n_of(r), len(x))
    x[:an] *= np.linspace(0, 1, an)
    x[len(x) - rn:] *= np.linspace(1, 0, rn)
    return x


def mix(*sigs):
    out = np.zeros(max(len(s) for s in sigs))
    for s in sigs:
        out[:len(s)] += s
    return out


def at(sig, delay):
    return np.concatenate([np.zeros(n_of(delay)), sig])


def make_ir(sec, seed):
    r = np.random.default_rng(seed)
    n = n_of(sec)
    h = lp(r.normal(size=n) * np.exp(-6.9 * tt(n) / sec), 4500)
    return h / np.sqrt(np.sum(h ** 2))


def room(x, wet=0.25, sec=0.6):
    return mix(x, fftconvolve(x, make_ir(sec, 1)) * wet)


# ---------------------------------------------------------------- Stimme (Formant-Synthese)

def voice(f0, formants, amp, nharm=45):
    """Additive Stimme: Obertöne von f0, gewichtet durch Formanten (Frequenz-Kurve, Bandbreite, Gain)."""
    n = len(f0)
    cyc = np.cumsum(f0) / SR
    x = np.zeros(n)
    for h in range(1, nharm + 1):
        fh = f0 * h
        a = np.zeros(n)
        for ff, bw, g in formants:
            a += g / (1.0 + ((fh - ff) / bw) ** 2)
        a = np.where(fh < SR * 0.45, a * h ** -0.7, 0.0)
        x += a * np.sin(TAU * h * cyc)
    return x * amp


# ---------------------------------------------------------------- Klangerzeuger

def bell(f, dur, tau=0.6):
    n = n_of(dur)
    t = tt(n)
    x = np.zeros(n)
    for p, a in [(1, 1.0), (2.0, 0.5), (2.76, 0.35), (4.07, 0.2), (5.4, 0.12)]:
        if f * p < SR * 0.45:
            x += a * np.sin(TAU * f * p * t) * np.exp(-t * p ** 0.6 / tau)
    return fade(x * np.minimum(t / 0.002, 1.0), 0.0, 0.02)


def box(f, dur, tau=1.1):
    n = n_of(dur)
    t = tt(n)
    x = np.zeros(n)
    for p, a in [(1, 1.0), (2.76, 0.28), (5.4, 0.1), (8.93, 0.04)]:
        if f * p < SR * 0.45:
            x += a * np.sin(TAU * f * p * t) * np.exp(-t * p ** 0.6 / tau)
    return fade(x, 0.001, 0.03)


def pluck(f, dur, tau=0.3, nh=9, tilt=1.2, damp=0.5):
    n = n_of(dur)
    t = tt(n)
    x = np.zeros(n)
    for h in range(1, nh + 1):
        if f * h > SR * 0.45:
            break
        x += h ** -tilt * np.sin(TAU * f * h * t) * np.exp(-t * (1 + damp * (h - 1)) / tau)
    return x * np.minimum(t / 0.004, 1.0) * np.minimum((dur - t) / 0.02, 1.0)


def lead(f, dur, vib=5.2, depth=0.004):
    n = n_of(dur)
    t = tt(n)
    p = ph(f * (1 + depth * np.minimum(t / 0.3, 1.0) * np.sin(TAU * vib * t)))
    x = np.sin(p) + 0.3 * np.sin(2 * p) + 0.1 * np.sin(3 * p) + 0.04 * lp(noise(n), 3000)
    return x * adsr(n, 0.04, 0.1, 0.8, 0.12)


def pad(freqs, dur, cutoff=1500, att=0.4, rel=0.7, trem=0.0):
    n = n_of(dur)
    t = tt(n)
    x = np.zeros(n)
    for f in freqs:
        for cents in (-7, 0, 7):
            x += saw(ph(f * 2 ** (cents / 1200), n))
    x = lp(x, cutoff) / (3 * len(freqs))
    if trem:
        x *= 1 - 0.35 * (0.5 + 0.5 * np.sin(TAU * trem * t))
    return x * adsr(n, att, 0.2, 0.85, rel)


def bass(f, dur):
    n = n_of(dur)
    return lp(tri(ph(f, n)) + 0.5 * np.sin(ph(f, n)), 900) * adsr(n, 0.004, 0.12, 0.55, 0.06)


def bass_growl(f, dur):
    n = n_of(dur)
    return lp(sq(ph(f, n), 0.4) * 0.7 + saw(ph(f * 1.003, n)) * 0.4, 520) * adsr(n, 0.004, 0.1, 0.6, 0.05)


def kick():
    n = n_of(0.3)
    x = np.sin(ph(np.geomspace(140, 42, n))) * decay(n, 0.09)
    return fade(x + 0.3 * lp(noise(n), 3000) * decay(n, 0.004), 0.0, 0.02)


def clap():
    n = n_of(0.18)
    return bp(noise(n), 1200, 5500) * decay(n, 0.07) + 0.3 * tri(ph(190, n)) * decay(n, 0.05)


def shaker():
    n = n_of(0.07)
    return hp(noise(n), 6000) * decay(n, 0.018)


def thump():
    n = n_of(0.3)
    return np.sin(ph(np.geomspace(95, 38, n))) * decay(n, 0.12)


# ---------------------------------------------------------------- Soundeffekte

def sfx_jump():
    n = n_of(0.22)
    f = sweep(320, 780, n)
    return tri(ph(f)) * decay(n, 0.12) + 0.3 * sine(ph(f * 2)) * decay(n, 0.06)


def sfx_land():
    n = n_of(0.17)
    return sine(ph(sweep(150, 52, n))) * decay(n, 0.05) + 0.6 * lp(noise(n), 900) * decay(n, 0.035)


def sfx_step():
    n = n_of(0.09)
    return lp(noise(n), 600) * decay(n, 0.02) + 0.6 * sine(ph(sweep(110, 70, n))) * decay(n, 0.03)


def sfx_coin():
    def blip(f):
        n = n_of(0.3)
        return lp(sq(ph(f, n), 0.5), 7000) * decay(n, 0.1) * np.minimum(tt(n) / 0.002, 1)
    return mix(blip(1568), at(blip(2093), 0.07)) * 0.6


def sfx_star():
    notes = [72, 76, 79, 84, 88]
    parts = [at(bell(hz(m), 1.2, 0.5), i * 0.09) for i, m in enumerate(notes)]
    shimmer = hp(noise(n_of(1.2)), 5000) * decay(n_of(1.2), 0.25) * 0.05
    return room(mix(*parts, at(shimmer, 0.3)), 0.3, 0.8)


def sfx_checkpoint():
    n = n_of(1.5)
    swell = np.sin(ph(hz(60), n)) * adsr(n, 0.3, 0.2, 0.3, 0.8) * 0.3
    return room(mix(bell(hz(84), 1.5, 0.7), at(bell(hz(91), 1.4, 0.7), 0.12), swell), 0.3, 0.9)


def sfx_punch():
    n = n_of(0.15)
    w = sweep_bp(noise(n), 700, 2200, 0.6) * adsr(n, 0.003, 0.05, 0.3, 0.06) * 3
    return w + 0.6 * sine(ph(sweep(220, 110, n))) * decay(n, 0.05)


def sfx_dash():
    n = n_of(0.24)
    w = sweep_bp(noise(n), 500, 3800, 0.6) * adsr(n, 0.02, 0.08, 0.5, 0.1) * 3
    return w + 0.3 * sine(ph(sweep(180, 90, n))) * decay(n, 0.1)


def sfx_hit():
    n = n_of(0.2)
    thwack = lp(noise(n), 3500) * decay(n, 0.03)
    body = 0.9 * sine(ph(sweep(300, 90, n))) * decay(n, 0.07)
    boing = 0.3 * tri(ph(sweep(500, 250, n))) * decay(n, 0.1)
    return thwack + body + boing


def sfx_pop():
    n = n_of(0.3)
    return mix(sine(ph(sweep(350, 1100, n_of(0.08)))) * decay(n_of(0.08), 0.03),
               0.7 * lp(noise(n), 2500) * decay(n, 0.09),
               at(0.3 * tri(ph(sweep(700, 200, n))) * decay(n, 0.12), 0.04))


def sfx_hurt():
    n = n_of(0.34)
    f0 = kf([0, 1], [480, 290], n) * (1 + 0.01 * np.sin(TAU * 8 * tt(n)))
    f1 = kf([0, 1], [650, 450], n)
    f2 = kf([0, 1], [1000, 750], n)
    x = voice(f0, [(f1, 100, 1.0), (f2, 130, 0.6), (2800, 250, 0.2)], kf([0, .08, .65, 1], [0, 1, .6, 0], n))
    return np.tanh(x / np.max(np.abs(x)) * 1.5)


def sfx_nein():
    n = n_of(0.62)
    f0 = kf([0, .15, .5, .85, 1], [300, 340, 390, 370, 320], n) * (1 + 0.012 * np.sin(TAU * 6 * tt(n)))
    keys = [0, .14, .24, .60, .82, .92, 1]
    f1 = kf(keys, [250, 250, 850, 850, 430, 260, 250], n)
    f2 = kf(keys, [1700, 1700, 1350, 1350, 2000, 1800, 1700], n)
    amp = kf([0, .05, .14, .24, .6, .82, .92, 1], [0, .35, .4, 1, 1, .85, .4, 0], n)
    x = voice(f0, [(f1, 100, 1.0), (f2, 140, 0.6), (2800, 250, 0.3)], amp)
    x = np.tanh(x / np.max(np.abs(x)) * 1.7)
    ring = bell(hz(88), 0.5, 0.25) * 0.12
    return room(mix(x, at(ring, 0.1)), 0.15, 0.4)


def sfx_stun():
    n = n_of(0.85)
    t = tt(n)
    f = sweep(560, 300, n) * (1 + 0.2 * np.sin(TAU * 7 * t))
    return tri(ph(f)) * adsr(n, 0.02, 0.1, 0.8, 0.25) * (1 - 0.4 * (0.5 + 0.5 * np.sin(TAU * 14 * t)))


def sfx_vanish():
    n = n_of(0.55)
    t = tt(n)
    puff = lp(noise(n), 1800) * np.sin(np.pi * np.minimum(t / 0.55, 1)) ** 2 * 0.8
    return puff + 0.4 * sine(ph(sweep(900, 180, n))) * decay(n, 0.2)


def sfx_defeat():
    n = n_of(0.95)
    t = tt(n)
    f = sweep(1500, 220, n) * (1 + 0.02 * np.sin(TAU * 9 * t))
    x = (sine(ph(f)) + 0.2 * sine(ph(f * 2))) * adsr(n, 0.02, 0.1, 0.8, 0.2) * 0.8
    return mix(x, at(sfx_pop() * 0.7, 0.8))


def sfx_alert():
    return room(mix(bell(hz(79), 0.6, 0.25), at(bell(hz(75), 0.7, 0.3), 0.22)) * 0.9, 0.2, 0.5)


def sfx_pip():
    def clank():
        n = n_of(0.25)
        t = tt(n)
        x = sum(a * np.sin(TAU * f * t) * np.exp(-t / tau) for f, a, tau in [(830, 1, .1), (1370, .7, .08), (2210, .5, .06), (3340, .3, .04)])
        return x + 0.6 * hp(noise(n), 3000) * decay(n, 0.01)

    def chirp(f0, f1, dur):
        n = n_of(dur)
        f = sweep(f0, f1, n)
        return (sine(ph(f)) + 0.2 * sine(ph(2 * f))) * adsr(n, 0.005, 0.02, 0.7, 0.03)

    return mix(clank() * 0.8, at(clank() * 0.6, 0.09), at(chirp(900, 1400, 0.09), 0.38), at(chirp(1100, 1700, 0.1), 0.52))


def sfx_portal_open():
    n = n_of(2.0)
    t = tt(n)
    swell = sweep_bp(noise(n), 300, 5000, 0.6) * np.sin(np.pi * t / 2.0) ** 2 * 1.5
    chord = sum(np.sin(TAU * hz(m) * t) for m in (60, 64, 67, 72, 76)) * adsr(n, 0.8, 0.2, 0.8, 0.7) * 0.15
    return room(mix(swell, chord, at(bell(hz(88), 1.0, 0.5) * 0.5, 0.7), at(bell(hz(95), 1.0, 0.5) * 0.4, 0.9)), 0.3, 1.0)


def sfx_fanfare():
    def brass(f, dur):
        n = n_of(dur)
        x = lp(saw(ph(f, n)) + saw(ph(f * 1.004, n)), 2200)
        return x * adsr(n, 0.03, 0.08, 0.8, 0.1) * 0.5
    notes = [(0, 72, .14), (.14, 76, .14), (.28, 79, .14), (.42, 84, 1.0)]
    parts = [at(brass(hz(m), d + 0.05), s) for s, m, d in notes]
    parts += [at(brass(hz(m), 1.0) * 0.5, 0.42) for m in (72, 76, 79)]
    parts.append(at(bell(hz(96), 1.0, 0.5) * 0.35, 0.45))
    return room(mix(*parts), 0.3, 0.8)


def sfx_goal():
    parts = [at(bell(hz(m), 1.3, 0.6), i * 0.07) for i, m in enumerate([84, 88, 91, 96, 100, 103])]
    n = n_of(1.6)
    chord = sum(np.sin(TAU * hz(m) * tt(n)) for m in (72, 76, 79, 84)) * adsr(n, 0.3, 0.2, 0.6, 0.8) * 0.12
    return room(mix(*parts, chord, hp(noise(n), 5000) * decay(n, 0.3) * 0.04), 0.35, 1.0)


def sfx_ui():
    n = n_of(0.08)
    return sine(ph(sweep(700, 1000, n))) * adsr(n, 0.004, 0.02, 0.6, 0.03)


SFX = {  # Name: (Funktion, Lautstärke 0..1)
    "jump": (sfx_jump, 0.55), "land": (sfx_land, 0.7), "step": (sfx_step, 0.4), "coin": (sfx_coin, 0.6),
    "star": (sfx_star, 0.7), "checkpoint": (sfx_checkpoint, 0.6), "punch": (sfx_punch, 0.55),
    "dash": (sfx_dash, 0.5), "hit": (sfx_hit, 0.8), "pop": (sfx_pop, 0.75), "hurt": (sfx_hurt, 0.85),
    "nein": (sfx_nein, 0.95), "stun": (sfx_stun, 0.6), "vanish": (sfx_vanish, 0.6),
    "defeat": (sfx_defeat, 0.7), "alert": (sfx_alert, 0.6), "pip": (sfx_pip, 0.7),
    "portal_open": (sfx_portal_open, 0.65), "fanfare": (sfx_fanfare, 0.7), "goal": (sfx_goal, 0.7),
    "ui": (sfx_ui, 0.4),
}


# ---------------------------------------------------------------- Musik

CH = {"C": [60, 64, 67], "G": [55, 59, 62], "Am": [57, 60, 64], "F": [53, 57, 60], "Em": [52, 55, 59],
      "Dm": [50, 53, 57], "E": [52, 56, 59], "Bb": [58, 62, 65]}
ROOT = {"C": 36, "G": 43, "Am": 33, "F": 41, "Em": 40, "Dm": 38, "E": 40, "Bb": 34}


class Track:
    """Stereo-Spur mit Beat-Raster; render() hängt den Hall-Ausklang nahtlos an den Anfang (Loop)."""

    def __init__(self, bars, bpm, beats=4):
        self.spb = 60.0 / bpm
        self.beats = beats
        self.length = int(bars * beats * self.spb * SR)
        self.buf = np.zeros((self.length + n_of(2.5), 2))

    def add(self, sig, beat, gain=1.0, pan=0.0):
        s = int(beat * self.spb * SR)
        end = min(s + len(sig), len(self.buf))
        if end <= s:
            return
        a = (pan + 1) * np.pi / 4
        self.buf[s:end, 0] += gain * np.cos(a) * sig[:end - s]
        self.buf[s:end, 1] += gain * np.sin(a) * sig[:end - s]

    def render(self, wet=0.3):
        irs = [make_ir(1.6, 11), make_ir(1.6, 12)]
        dry = np.pad(self.buf, ((0, len(irs[0]) - 1), (0, 0)))
        wetb = np.stack([fftconvolve(self.buf[:, c], irs[c]) for c in range(2)], axis=1)
        full = dry + wet * wetb
        out = np.zeros((self.length, 2))
        for i in range(0, len(full), self.length):
            seg = full[i:i + self.length]
            out[:len(seg)] += seg
        out *= 0.14 / np.sqrt(np.mean(out ** 2))
        peak = np.max(np.abs(out))
        if peak > 0.95:
            out *= 0.95 / peak
        return out


def music_level():
    T = Track(16, 112)
    spb = T.spb
    prog = ["C", "G", "Am", "F", "C", "G", "F", "G", "Am", "F", "C", "G", "Am", "F", "G", "C"]
    for bar, ch in enumerate(prog):
        b = bar * 4
        T.add(pad([hz(m) for m in CH[ch]], 4 * spb + 0.3, 1400, 0.35, 0.5), b, 0.16, -0.2)
        for beat, off in [(0, 0), (1, 7), (2, 0), (2.5, 12), (3, 7)]:
            T.add(bass(hz(ROOT[ch] + off), 0.9 * spb), b + beat, 0.5)
        for i, idx in enumerate([0, 2, 1, 2, 0, 2, 1, 2]):
            T.add(pluck(hz(CH[ch][idx] + 12), 0.8 * spb, 0.25), b + i * 0.5, 0.2, -0.3 if i % 2 == 0 else 0.3)
        T.add(kick(), b, 0.5)
        T.add(kick(), b + 2, 0.45)
        if bar >= 4:
            T.add(clap(), b + 1, 0.2)
            T.add(clap(), b + 3, 0.2)
        for i in range(8):
            T.add(shaker(), b + i * 0.5, 0.12 if i % 2 else 0.07, 0.2)

    mel = {
        0: [(0, 76, 1), (1, 79, 1), (2, 76, .5), (2.5, 74, .5), (3, 72, 1)],
        1: [(0, 74, 1.5), (1.5, 71, .5), (2, 74, 1), (3, 67, 1)],
        2: [(0, 72, 1), (1, 76, 1), (2, 81, 1.5), (3.5, 79, .5)],
        3: [(0, 77, 1), (1, 76, .5), (1.5, 74, .5), (2, 72, 2)],
        4: [(0, 79, 1), (1, 76, .5), (1.5, 79, .5), (2, 84, 1), (3, 79, 1)],
        5: [(0, 83, 1), (1, 81, .5), (1.5, 79, .5), (2, 74, 2)],
        6: [(0, 81, 1), (1, 79, .5), (1.5, 77, .5), (2, 76, 1), (3, 74, 1)],
        7: [(0, 67, .5), (.5, 71, .5), (1, 74, .5), (1.5, 79, .5), (2, 77, .5), (2.5, 74, .5), (3, 71, 1)],
        8: [(0, 76, .5), (.5, 81, .5), (1, 84, 1), (2, 83, .5), (2.5, 81, .5), (3, 76, 1)],
        9: [(0, 81, .5), (.5, 84, .5), (1, 81, .5), (1.5, 77, .5), (2, 81, 2)],
        10: [(0, 79, .5), (.5, 76, .5), (1, 79, 1), (2, 84, 1.5), (3.5, 79, .5)],
        11: [(0, 83, 1), (1, 86, 1), (2, 83, .5), (2.5, 79, .5), (3, 74, 1)],
        12: [(0, 84, .5), (.5, 83, .5), (1, 81, 1), (2, 76, 1), (3, 81, 1)],
        13: [(0, 77, 1), (1, 81, 1), (2, 84, 1), (3, 81, 1)],
        14: [(0, 83, 1.5), (1.5, 79, .5), (2, 74, 1), (3, 71, 1)],
        15: [(0, 72, 1), (1, 76, 1), (2, 79, 1), (3, 84, 1)],
    }
    for bar, notes in mel.items():
        for beat, m, d in notes:
            T.add(lead(hz(m), d * spb * 0.95 + 0.05), bar * 4 + beat, 0.34 if bar < 8 else 0.3, 0.1)
            if bar >= 8:
                T.add(pluck(hz(m + 12), 0.6, 0.3), bar * 4 + beat, 0.12, 0.4)
    return T.render(0.3)


def music_tension():
    T = Track(16, 112)
    spb = T.spb
    prog = ["Am", "Am", "Dm", "E"] * 4
    box_notes = {"Am": [(1, 81), (2, 84)], "Dm": [(1, 77), (2.5, 81)], "E": [(1, 80), (2, 83)]}
    for bar, ch in enumerate(prog):
        b = bar * 4
        T.add(pad([hz(m - 12) for m in CH[ch]], 4 * spb + 0.3, 1100, 0.5, 0.6, trem=5.5), b, 0.22)
        for i in range(8):
            T.add(bass_growl(hz(ROOT[ch]), 0.4 * spb), b + i * 0.5, 0.35 if i % 2 == 0 else 0.22)
        for beat, g in [(0, 0.55), (0.5, 0.3), (2, 0.45), (2.5, 0.25)]:
            T.add(kick(), b + beat, g)
        if bar % 4 != 1:
            for beat, m in box_notes[ch]:
                T.add(box(hz(m), 1.6, 1.4), b + beat, 0.16, 0.3 if beat == 1 else -0.3)
    return T.render(0.35)


def music_story_calm():
    T = Track(16, 76, 3)
    spb = T.spb
    prog = ["C", "F", "C", "G", "Am", "F", "G", "C"] * 2
    mel = {
        0: [(0, 76, 1), (1, 79, 1), (2, 76, 1)], 1: [(0, 77, 1), (1, 81, 1), (2, 77, 1)],
        2: [(0, 79, 1.5), (1.5, 76, .5), (2, 72, 1)], 3: [(0, 74, 1), (1, 71, 1), (2, 74, 1)],
        4: [(0, 72, 1), (1, 76, 1), (2, 81, 1)], 5: [(0, 81, 1), (1, 79, .5), (1.5, 77, .5), (2, 76, 1)],
        6: [(0, 74, 1), (1, 79, 1), (2, 83, 1)], 7: [(0, 84, 3)],
    }
    for bar, ch in enumerate(prog):
        b = bar * 3
        T.add(pad([hz(m - 12) for m in CH[ch]], 3 * spb + 0.3, 900, 0.5, 0.7), b, 0.14, -0.2)
        T.add(bass(hz(ROOT[ch] + 12), 1.2 * spb), b, 0.3)
        for beat, idx in [(1, 1), (2, 2)]:
            T.add(box(hz(CH[ch][idx]), 1.2, 0.9), b + beat, 0.12, -0.3 if beat == 1 else 0.3)
        for beat, m, d in mel[bar % 8]:
            T.add(box(hz(m), 1.8, 1.2), b + beat, 0.3, 0.1)
            if bar >= 8:
                T.add(box(hz(m + 12), 1.2, 0.8), b + beat, 0.1, 0.4)
    return T.render(0.35)


def music_story_dark():
    T = Track(16, 60)
    spb = T.spb
    prog = ["Am", "Bb", "Am", "E", "Dm", "Bb", "E", "Am"] * 2
    mel = {
        0: [(0, 76, 2), (2, 72, 2)], 1: [(0, 77, 2), (2, 74, 2)], 2: [(0, 76, 1), (1, 79, 1), (2, 76, 2)],
        3: [(0, 80, 2), (2, 83, 2)], 4: [(0, 77, 2), (2, 74, 2)], 5: [(0, 74, 1), (1, 70, 1), (2, 74, 2)],
        6: [(0, 83, 1), (1, 80, 1), (2, 76, 2)], 7: [(0, 81, 4)],
    }
    for bar, ch in enumerate(prog):
        b = bar * 4
        T.add(pad([hz(m - 12) for m in CH[ch]], 4 * spb + 0.4, 800, 0.9, 1.0), b, 0.2, -0.2)
        T.add(pad([hz(m) for m in CH[ch]], 4 * spb + 0.4, 2000, 0.9, 1.0, trem=6.0), b, 0.1, 0.25)
        T.add(np.sin(ph(hz(ROOT[ch] - 12 + 12), n_of(4 * spb))) * adsr(n_of(4 * spb), 1.0, 0.3, 0.8, 1.0), b, 0.25)
        T.add(thump(), b, 0.4)
        T.add(thump(), b + 1.5, 0.3)
        for beat, m, d in mel[bar % 8]:
            T.add(box(hz(m), 2.5, 1.6), b + beat, 0.28, 0.2)
    return T.render(0.45)


def music_story_hope():
    T = Track(16, 92)
    spb = T.spb
    prog = ["C", "G", "Am", "Em", "F", "C", "F", "G", "C", "G", "Am", "Em", "F", "G", "C", "C"]
    mel = {
        8: [(0, 76, 1), (1, 79, 1), (2, 84, 2)], 9: [(0, 83, 1), (1, 81, 1), (2, 79, 2)],
        10: [(0, 81, 1), (1, 84, 1), (2, 83, 1), (3, 81, 1)], 11: [(0, 79, 1), (1, 76, 1), (2, 79, 2)],
        12: [(0, 81, 1), (1, 79, 1), (2, 77, 1), (3, 81, 1)], 13: [(0, 79, 1), (1, 83, 1), (2, 86, 2)],
        14: [(0, 84, 3), (3, 79, 1)], 15: [(0, 76, 1), (1, 74, 1), (2, 72, 2)],
    }
    for bar, ch in enumerate(prog):
        b = bar * 4
        T.add(pad([hz(m) for m in CH[ch]], 4 * spb + 0.4, 1600, 0.6, 0.8), b, 0.16, -0.2)
        T.add(bass(hz(ROOT[ch] + 12), 1.6 * spb), b, 0.35)
        T.add(bass(hz(ROOT[ch] + 12), 1.6 * spb), b + 2, 0.25)
        for i, idx in enumerate([0, 1, 2, 1, 2, 1, 0, 1]):
            T.add(pluck(hz(CH[ch][idx] + 12), 0.8, 0.35), b + i * 0.5, 0.14, -0.3 if i % 2 == 0 else 0.3)
        if bar >= 8:
            T.add(kick(), b, 0.3)
            T.add(kick(), b + 2, 0.25)
            for i in range(4):
                T.add(shaker(), b + i + 0.5, 0.08, 0.2)
            for beat, m, d in mel[bar]:
                T.add(lead(hz(m), d * spb * 0.95 + 0.05), b + beat, 0.3, 0.1)
    return T.render(0.35)


MUSIC = {"level": music_level, "tension": music_tension, "story_calm": music_story_calm,
         "story_dark": music_story_dark, "story_hope": music_story_hope}


# ---------------------------------------------------------------- Ausgabe

def write_wav(path, x):
    x16 = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1 if x.ndim == 1 else 2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(x16.tobytes())


def main() -> None:
    only = set(sys.argv[1:])
    (OUT / "sfx").mkdir(parents=True, exist_ok=True)
    (OUT / "music").mkdir(parents=True, exist_ok=True)
    for name, (fn, gain) in SFX.items():
        if only and name not in only:
            continue
        x = fade(np.asarray(fn(), dtype=float))
        x = x / np.max(np.abs(x)) * 0.9 * gain
        write_wav(OUT / "sfx" / f"{name}.wav", x)
        print("sfx", name, f"{len(x) / SR:.2f}s", flush=True)
    for name, fn in MUSIC.items():
        if only and name not in only:
            continue
        x = fn()
        with tempfile.TemporaryDirectory() as tmp:
            wav = Path(tmp) / "m.wav"
            write_wav(wav, x)
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "libvorbis", "-q:a", "5",
                            str(OUT / "music" / f"{name}.ogg")], check=True)
        print("music", name, f"{len(x) / SR:.1f}s", flush=True)


if __name__ == "__main__":
    main()
