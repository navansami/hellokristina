"""Synthesise the app's feedback sounds: warm, bright and loud.

Everything is built from scratch with the standard library, so there are no
third-party samples to license. Instruments:

* mallet: a marimba-like bar (modal partials at 1, 3.99 and 10x with a click)
* bell:   an FM glockenspiel with a shimmering, decaying brightness
* pluck:  a Karplus-Strong string for warmth
* pop:    a bubble pop for taps
* thump:  a soft pitch-dropping kick that gives fanfares weight
* whoosh: band-passed noise sweeping upwards
* sparkle: a scatter of quiet high bell notes

Each sound gets a small room reverb, gentle saturation and is mastered to a
-1 dBFS peak, so effects sit at the same loudness as the tutor voices.

Run: python scripts/generate-feedback-sounds.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path('assets/audio/effects')
OUT.mkdir(parents=True, exist_ok=True)
TAU = 2 * math.pi
NOTES = {'C': -9, 'D': -7, 'E': -5, 'F': -4, 'G': -2, 'A': 0, 'B': 2}


def hz(name):
    """'C6', 'F#5' -> frequency (A4 = 440 Hz)."""
    step = NOTES[name[0]] + (1 if '#' in name else 0)
    octave = int(name[-1])
    return 440 * 2 ** ((step + (octave - 4) * 12) / 12)


class Track:
    def __init__(self, seconds):
        self.s = [0.0] * int(seconds * RATE)

    def add(self, start, samples, gain=1.0):
        at = int(start * RATE)
        s = self.s
        if at + len(samples) > len(s):  # grow rather than cut a note off
            s.extend([0.0] * (at + len(samples) - len(s)))
        for i, x in enumerate(samples):
            s[at + i] += x * gain


def released(out, ms=25):
    """Fade a note's last few milliseconds so it never ends in a click."""
    n = min(len(out), int(ms / 1000 * RATE))
    for i in range(n):
        out[-1 - i] *= (i / n) ** 2
    return out


def mallet(f, dur=.5, bright=1.0):
    n = int(dur * RATE)
    parts = [(1, 1.0, dur * .45), (3.99, .32 * bright, dur * .12),
             (10.0, .10 * bright, dur * .05)]
    rnd = random.Random(int(f))
    out = []
    for i in range(n):
        t = i / RATE
        attack = min(1, t / .002)
        x = sum(a * math.sin(TAU * f * r * t) * math.exp(-t / d)
                for r, a, d in parts)
        if t < .004:  # the mallet's click
            x += (rnd.random() * 2 - 1) * .25 * (1 - t / .004) * bright
        out.append(x * attack)
    return released(out)


def bell(f, dur=.8, index=2.2, bright=1.0):
    n = int(dur * RATE)
    out = []
    for i in range(n):
        t = i / RATE
        amp = math.exp(-t / (dur * .32)) * min(1, t / .0015)
        # High notes get less FM so sidebands stay below Nyquist (no harsh
        # aliasing on the sparkles).
        mod = index * bright * min(1, 1800 / f) * math.exp(-t / .09)
        x = math.sin(TAU * f * t + mod * math.sin(TAU * f * 3.5 * t))
        x += .22 * math.sin(TAU * f * 2.76 * t) * math.exp(-t / (dur * .1))
        out.append(x * amp)
    return released(out)


def pluck(f, dur=.6, damp=.996):
    n = int(dur * RATE)
    period = max(2, int(RATE / f))
    rnd = random.Random(int(f * 7))
    buf = [rnd.random() * 2 - 1 for _ in range(period)]
    # Soften the excitation so the string sounds round, not buzzy.
    for _ in range(2):
        buf = [(buf[i] + buf[i - 1]) * .5 for i in range(period)]
    out = []
    for i in range(n):
        x = buf[i % period]
        nxt = buf[(i + 1) % period]
        buf[i % period] = damp * .5 * (x + nxt)
        out.append(x * min(1, i / 40))
    return released(out)


def pop(f0=520, f1=1250, dur=.075):
    n = int(dur * RATE)
    out, phase = [], 0.0
    for i in range(n):
        t = i / RATE
        f = f0 + (f1 - f0) * (1 - math.exp(-t / .012))
        phase += TAU * f / RATE
        out.append(math.sin(phase) * math.exp(-t / .022) * min(1, t / .001))
    return released(out)


def thump(dur=.22, f0=170, f1=48):
    n = int(dur * RATE)
    out, phase = [], 0.0
    for i in range(n):
        t = i / RATE
        f = f1 + (f0 - f1) * math.exp(-t / .03)
        phase += TAU * f / RATE
        out.append(math.sin(phase) * math.exp(-t / .07) * min(1, t / .002))
    return released(out)


def whoosh(dur=.5, lo=300, hi=4000, seed=3):
    """Noise through a resonant band-pass whose centre sweeps up."""
    n = int(dur * RATE)
    rnd = random.Random(seed)
    low = band = 0.0
    out = []
    for i in range(n):
        p = i / n
        fc = lo * (hi / lo) ** p
        f = 2 * math.sin(math.pi * fc / RATE)
        q = .35
        x = rnd.random() * 2 - 1
        low += f * band
        high = x - low - q * band
        band += f * high
        out.append(band * math.sin(math.pi * p) ** 1.5)
    return released(out)


def sparkle(track, start, count, seed, spread=.5, level=.18):
    rnd = random.Random(seed)
    scale = ['C7', 'D7', 'E7', 'G7', 'A7', 'C8']
    for k in range(count):
        when = start + rnd.random() * spread
        track.add(when, bell(hz(rnd.choice(scale)), .35, 1.2),
                  level * (.6 + .4 * rnd.random()))


def reverb(samples, wet=.2, size=1.0):
    """A small Freeverb-style room: four damped combs and two all-passes."""
    combs = [int(d * size) for d in (1116, 1188, 1277, 1356)]
    tail = int(.35 * RATE)
    dry = samples + [0.0] * tail
    acc = [0.0] * len(dry)
    for d in combs:
        buf = [0.0] * d
        store, fb, damp = 0.0, .78, .3
        for i, x in enumerate(dry):
            y = buf[i % d]
            store = y * (1 - damp) + store * damp
            buf[i % d] = x + store * fb
            acc[i] += y * .25
    for d in (556, 441):
        buf = [0.0] * d
        for i, x in enumerate(acc):
            y = buf[i % d]
            buf[i % d] = x + y * .5
            acc[i] = y - x * .5
    return [a + wet * b for a, b in zip(dry, acc)]


def master(samples, drive=1.6, peak=.89):
    # Remove DC, saturate gently for density, then normalise the peak.
    out, prev_x, prev_y = [], 0.0, 0.0
    for x in samples:
        y = x - prev_x + .995 * prev_y
        prev_x, prev_y = x, y
        out.append(y)
    top = max(abs(x) for x in out) or 1
    out = [math.tanh(drive * x / top) / math.tanh(drive) for x in out]
    # Trim trailing near-silence and fade the last 30 ms.
    end = len(out)
    while end > 0 and abs(out[end - 1]) < .002:
        end -= 1
    out = out[:end + int(.01 * RATE)]
    fade = int(.03 * RATE)
    for i in range(min(fade, len(out))):
        out[-1 - i] *= i / fade
    top = max(abs(x) for x in out) or 1
    return [x * peak / top for x in out]


def write(name, samples):
    with wave.open(str(OUT / f'{name}.wav'), 'wb') as f:
        f.setparams((1, 2, RATE, len(samples), 'NONE', 'not compressed'))
        f.writeframes(b''.join(
            struct.pack('<h', int(max(-1, min(1, x)) * 32767))
            for x in samples))
    print(f'{name:11s} {len(samples) / RATE:.2f}s')


def chime(track, start, note, level=1.0, dur=.7):
    """The house sound: a bell doubled by a mallet an octave down."""
    f = hz(note)
    track.add(start, bell(f, dur), .55 * level)
    track.add(start, mallet(f / 2, dur * .8, .8), .45 * level)


sounds = {}

# Tile taps: a friendly bubble pop.
t = Track(.12)
t.add(0, pop())
t.add(0, mallet(hz('E6'), .08, .5), .25)
sounds['tap'] = (t, .06)

# Correct: a bright rising "ding-ding" with a sparkle.
t = Track(.9)
chime(t, 0, 'E6', .9)
chime(t, .085, 'A6', 1.0, .8)
sparkle(t, .12, 4, 1, .25, .12)
sounds['correct'] = (t, .2)

# Not quite: a soft, warm "bum-bum" falling a fourth. Gentle, never harsh.
t = Track(.6)
t.add(0, mallet(hz('D4'), .35, .4), .9)
t.add(.12, mallet(hz('A3'), .45, .3), 1.0)
t.add(.12, pluck(hz('A2'), .35, .99), .25)
sounds['retry'] = (t, .14, .7)  # quieter: a miss is never the loudest

# Three in a row: a quick arpeggio up.
t = Track(1.0)
for i, n in enumerate(['C6', 'E6', 'G6']):
    chime(t, i * .065, n, .85 + .1 * i)
sparkle(t, .2, 6, 2, .35)
sounds['streak'] = (t, .22)

# Five in a row: higher, faster and with a whoosh.
t = Track(1.2)
t.add(0, whoosh(.35, 600, 6000), .5)
for i, n in enumerate(['C6', 'E6', 'G6', 'C7']):
    chime(t, .05 + i * .055, n, .85 + .08 * i)
sparkle(t, .25, 10, 3, .5, .2)
sounds['hot_streak'] = (t, .25)

# Combo chip: a plucky fifth.
t = Track(.6)
t.add(0, pluck(hz('G5'), .4), .6)
t.add(.06, pluck(hz('D6'), .45), .7)
t.add(.06, bell(hz('D7'), .4), .25)
sounds['combo'] = (t, .18)

# XP counter: a tiny coin.
t = Track(.12)
t.add(0, bell(hz('B6'), .08, 1.4), .7)
t.add(.03, bell(hz('E7'), .08, 1.2), .6)
sounds['xp_tick'] = (t, .03)


def fanfare(t, notes, chord, chord_at, sparkle_seed, big=1.0):
    t.add(0, thump(), .55 * big)
    for i, n in enumerate(notes):
        chime(t, i * .075, n, .8)
    t.add(chord_at, thump(.3, 140, 42), .7 * big)
    for n in chord:
        t.add(chord_at, bell(hz(n), 1.1), .4)
        t.add(chord_at, pluck(hz(n) / 2, 1.0, .997), .3)
    sparkle(t, chord_at + .05, int(8 * big), sparkle_seed, .6, .16)


# Practice complete: a short, happy fanfare.
t = Track(1.6)
fanfare(t, ['C5', 'E5', 'G5'], ['C5', 'E5', 'G5', 'C6'], .26, 4)
sounds['complete'] = (t, .24)

# Perfect: a longer run up and a glitter cascade.
t = Track(1.7)
fanfare(t, ['C5', 'E5', 'G5', 'C6', 'E6'], ['C5', 'G5', 'C6', 'E6', 'G6'],
        .4, 5, 1.3)
for i, n in enumerate(['C8', 'G7', 'E7', 'C7', 'G6']):
    t.add(.55 + i * .06, bell(hz(n), .4, 1.3), .18)
sounds['perfect'] = (t, .26)

# Daily goal: a two-chord "ta-da".
t = Track(1.5)
t.add(0, thump(), .5)
for n in ['G5', 'B5', 'D6']:
    t.add(0, bell(hz(n), .45), .4)
    t.add(0, mallet(hz(n) / 2, .3), .3)
t.add(.2, thump(.3, 140, 42), .7)
for n in ['C6', 'E6', 'G6', 'C7']:
    t.add(.2, bell(hz(n), 1.1), .38)
    t.add(.2, pluck(hz(n) / 2, .9, .997), .28)
sparkle(t, .25, 9, 6, .6, .16)
sounds['goal'] = (t, .26)

# Level up: whoosh, a climbing run, a big chord and a shimmering tail.
t = Track(2.0)
t.add(0, whoosh(.5, 250, 7000, 9), .55)
run = ['G4', 'C5', 'E5', 'G5', 'C6', 'E6']
when = 0.0
for i, n in enumerate(run):
    chime(t, when, n, .75 + .05 * i, .5)
    when += .085 - i * .008
t.add(.5, thump(.4, 150, 40), 1.0)
for n in ['C5', 'G5', 'C6', 'E6', 'G6', 'C7']:
    t.add(.5, bell(hz(n), 1.4), .36)
    t.add(.5, pluck(hz(n) / 2, 1.3, .998), .26)
sparkle(t, .55, 16, 7, .9, .17)
sounds['level_up'] = (t, .3)

for name, (track, wet, *peak) in sounds.items():
    # Taps and ticks repeat quickly, so they stay dry and short.
    wet_track = reverb(track.s, wet) if wet >= .1 else track.s
    write(name, master(wet_track, peak=peak[0] if peak else .89))
print(f'Generated {len(sounds)} feedback sounds.')
