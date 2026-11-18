import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// How much of the tutor is shown. `bust` frames the upper body so the face
/// and gestures read clearly in small lesson scenes.
enum TutorFraming { full, bust }

/// An articulated, resolution-independent tutor that acts rather than floats.
///
/// Moods: `idle`, `speaking`, `listening`, `thinking`, `correct`, `celebrate`,
/// `happy`, `hot`, `wrong`, `sad`, `cheer`. Unknown moods behave like idle.
/// Joints are driven by springs, so every change of mood blends with
/// anticipation, overshoot and follow-through instead of snapping.
class AnimatedKristina extends StatefulWidget {
  final double width, height;
  final String mood;
  final int character;

  /// Increment to make the tutor react to a learner action (a small nod).
  final int nudge;

  /// Where the learner's attention is, from -1 to 1 on each axis.
  final Offset gaze;
  final TutorFraming framing;

  /// Called when the learner taps the tutor (after the tutor giggles).
  final VoidCallback? onPoke;
  const AnimatedKristina(
      {super.key,
      this.width = 150,
      this.height = 220,
      this.mood = 'idle',
      this.character = 0,
      this.nudge = 0,
      this.gaze = const Offset(.3, 0),
      this.framing = TutorFraming.full,
      this.onPoke});
  @override
  State<AnimatedKristina> createState() => _AnimatedKristinaState();
}

class _Spring {
  double value, velocity = 0;
  _Spring(this.value);
  void step(double target, double dt, double k, double d) {
    final a = k * (target - value) - d * velocity;
    velocity += a * dt;
    value += velocity * dt;
  }
}

/// A complete pose. Angles are radians; distances are view-box units.
class _Pose {
  double lean = 0,
      sway = 0,
      headTilt = 0,
      headTurn = 0,
      headNod = 0,
      shoulderLift = 0,
      armLA = .18,
      armLB = -.25,
      armRA = -.18,
      armRB = .25,
      legL = 0,
      legR = 0,
      eyeOpen = 1,
      happyEyes = 0,
      pupilX = .3,
      pupilY = 0,
      browL = 0,
      browR = 0,
      worry = 0,
      mouthOpen = 0,
      smile = .45,
      mouthWide = 1,
      blush = 0;
  bool frontL = false, frontR = false;
  static const fields = 23;
  double get(int i) => switch (i) {
        0 => lean,
        1 => sway,
        2 => headTilt,
        3 => headTurn,
        4 => headNod,
        5 => shoulderLift,
        6 => armLA,
        7 => armLB,
        8 => armRA,
        9 => armRB,
        10 => legL,
        11 => legR,
        12 => eyeOpen,
        13 => happyEyes,
        14 => pupilX,
        15 => pupilY,
        16 => browL,
        17 => browR,
        18 => worry,
        19 => mouthOpen,
        20 => smile,
        21 => mouthWide,
        _ => blush,
      };
  void set(int i, double v) {
    switch (i) {
      case 0:
        lean = v;
      case 1:
        sway = v;
      case 2:
        headTilt = v;
      case 3:
        headTurn = v;
      case 4:
        headNod = v;
      case 5:
        shoulderLift = v;
      case 6:
        armLA = v;
      case 7:
        armLB = v;
      case 8:
        armRA = v;
      case 9:
        armRB = v;
      case 10:
        legL = v;
      case 11:
        legR = v;
      case 12:
        eyeOpen = v;
      case 13:
        happyEyes = v;
      case 14:
        pupilX = v;
      case 15:
        pupilY = v;
      case 16:
        browL = v;
      case 17:
        browR = v;
      case 18:
        worry = v;
      case 19:
        mouthOpen = v;
      case 20:
        smile = v;
      case 21:
        mouthWide = v;
      default:
        blush = v;
    }
  }
}

/// Spring stiffness per field: faces react quickly, limbs carry weight.
const List<double> _stiffness = [
  120.0, 120, 150, 140, 260, 220, 190, 210, 190, 210, 220, 220, //
  520, 260, 300, 300, 260, 260, 220, 900, 260, 300, 120,
];

double _clamp01(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);
double _smooth(double x) {
  final t = _clamp01(x);
  return t * t * (3 - 2 * t);
}

/// 0 → 1 → 0 hump over [start, start + duration].
double _hump(double c, double start, double duration) {
  final p = (c - start) / duration;
  return p <= 0 || p >= 1 ? 0 : math.sin(p * math.pi);
}

enum _IdleAction { wave, look, stretch, hair, bounce, peek }

const _idleLength = {
  _IdleAction.wave: 1.8,
  _IdleAction.look: 2.4,
  _IdleAction.stretch: 2.2,
  _IdleAction.hair: 1.6,
  _IdleAction.bounce: 1.1,
  _IdleAction.peek: 1.7,
};

class _AnimatedKristinaState extends State<AnimatedKristina>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _frame = ValueNotifier<int>(0);
  final _pose = _Pose();
  late final List<_Spring> _springs =
      List.generate(_Pose.fields, (i) => _Spring(_Pose().get(i)));
  late math.Random _random = math.Random(widget.character * 7919 + 17);
  bool _reduced = false;
  double _base = 0,
      _now = 0,
      _moodAt = 0,
      _enterAt = 0,
      _tickleAt = -10,
      _nudgeAt = -10;
  double _nextBlink = 1.8, _blinkAt = -10, _nextSaccade = 1;
  Offset _saccade = Offset.zero;
  _IdleAction? _idle;
  double _idleAt = 0, _nextIdle = 3.5;
  double _hairLag = 0, _hairVelocity = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduced) {
      if (_ticker.isActive) _ticker.stop();
      _settle();
    } else if (!_ticker.isActive) {
      _base = _now;
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedKristina old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) {
      _moodAt = _now;
      _idle = null;
      _nextIdle = _now + 3 + _random.nextDouble() * 3;
    }
    if (old.character != widget.character) {
      _random = math.Random(widget.character * 7919 + 17);
      _enterAt = _now;
    }
    if (old.nudge != widget.nudge) {
      _nudgeAt = _now;
      _springs[4].velocity += 70;
      _springs[2].velocity += widget.nudge.isEven ? .9 : -.9;
    }
    if (_reduced) _settle();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _settle() {
    final target = _target(1.6, 30);
    for (var i = 0; i < _Pose.fields; i++) {
      _springs[i]
        ..value = target.get(i)
        ..velocity = 0;
      _pose.set(i, target.get(i));
    }
    _pose
      ..frontL = target.frontL
      ..frontR = target.frontR;
    _frame.value++;
  }

  void _tick(Duration elapsed) {
    final now = _base + elapsed.inMicroseconds / 1e6;
    var dt = now - _now;
    _now = now;
    if (dt <= 0) return;
    if (dt > .1) dt = .1;
    // Life between moods: blinks, glances and small idle performances.
    if (now >= _nextBlink) {
      _blinkAt = now;
      final twice = _random.nextDouble() < .2;
      _nextBlink = now + (twice ? .32 : 2.2 + _random.nextDouble() * 3.2);
    }
    if (now >= _nextSaccade) {
      _saccade = Offset(
          _random.nextDouble() * .8 - .4, _random.nextDouble() * .5 - .25);
      _nextSaccade = now + .7 + _random.nextDouble() * 1.8;
    }
    if (widget.mood == 'idle' || widget.mood == 'thinking') {
      final active = _idle != null && now - _idleAt < _idleLength[_idle]!;
      if (!active) _idle = null;
      if (_idle == null && now >= _nextIdle && widget.mood == 'idle') {
        _idle = _IdleAction.values[_random.nextInt(_IdleAction.values.length)];
        _idleAt = now;
        _nextIdle = now + _idleLength[_idle]! + 3.5 + _random.nextDouble() * 4;
      }
    }
    final target = _target(now - _moodAt, now);
    final steps = (dt / (1 / 120)).ceil();
    final h = dt / steps;
    for (var s = 0; s < steps; s++) {
      for (var i = 0; i < _Pose.fields; i++) {
        final k = _stiffness[i];
        _springs[i].step(target.get(i), h, k, 2 * math.sqrt(k) * .62);
      }
      // Hair follows the head with a little lag for secondary motion.
      final a = 90 * (_springs[2].value - _hairLag) - 9 * _hairVelocity;
      _hairVelocity += a * h;
      _hairLag += _hairVelocity * h;
    }
    for (var i = 0; i < _Pose.fields; i++) {
      _pose.set(i, _springs[i].value);
    }
    _pose
      ..frontL = target.frontL
      ..frontR = target.frontR;
    _frame.value++;
  }

  /// Target pose for the current mood, `c` seconds into it, at clock `t`.
  _Pose _target(double c, double t) {
    final p = _Pose()
      ..lean = .02 * math.sin(t * 1.3)
      ..headTilt = .03 * math.sin(t * .9)
      ..armLA = .18 + .03 * math.sin(t * 1.6)
      ..armRA = -.18 - .03 * math.sin(t * 1.6 + 1)
      ..pupilX = widget.gaze.dx + _saccade.dx
      ..pupilY = widget.gaze.dy + _saccade.dy;
    switch (widget.mood) {
      case 'speaking':
        p
          ..mouthOpen =
              .12 + .75 * (math.sin(t * 17) * math.sin(t * 7.3 + 1)).abs()
          ..mouthWide = .85 + .25 * math.sin(t * 9.1)
          ..smile = .35
          ..headNod = 2.2 * math.sin(t * 6)
          ..headTilt = .05 * math.sin(t * 2.1)
          ..browL = -1.8 * math.sin(t * 3.1).abs()
          ..browR = -1.8 * math.sin(t * 3.1).abs()
          ..armRA = -.55 + .15 * math.sin(t * 3)
          ..armRB = -1.35 + .28 * math.sin(t * 4.4)
          ..frontR = true
          ..pupilX = 0
          ..pupilY = 0;
      case 'listening':
        p
          ..headTilt = -.13
          ..headNod = 1.6 * math.sin(t * 5)
          ..armLA = 2.55
          ..armLB = .6
          ..frontL = true
          ..eyeOpen = 1.12
          ..browL = -3.5
          ..browR = -3
          ..mouthOpen = .22
          ..smile = .1
          ..mouthWide = .55
          ..pupilX = -.4
          ..pupilY = -.3;
      case 'thinking':
        p
          ..headTilt = .07
          ..armRA = 1.57
          ..armRB = 1.5 + .08 * math.sin(t * 8)
          ..frontR = true
          ..pupilX = .6
          ..pupilY = -.7
          ..browR = -4
          ..browL = 1
          ..smile = .15
          ..mouthWide = .75;
      case 'correct':
      case 'happy':
        final pump = c < 1.1 ? .28 * math.sin(c * 20) : 0.0;
        final active = c < 1.5;
        p
          ..armRA = active ? -1.65 : -.3
          ..armRB = active ? -1.45 + pump : .3
          ..frontR = active
          ..armLA = active ? .55 : .2
          ..armLB = -.5
          ..happyEyes = c < 1.2 ? 1 : 0
          ..smile = 1
          ..mouthOpen = c < 1.4 ? .55 : .15
          ..blush = .6
          ..headTilt = .08 * _hump(c, .1, .8)
          ..browL = -3
          ..browR = -3
          ..pupilX = 0
          ..pupilY = 0;
      case 'celebrate':
      case 'cheer':
        final wiggle = c < 1.8 ? .22 * math.sin(c * 16) : 0.0;
        final active = c < 2.0;
        p
          ..armLA = active ? 2.6 + wiggle : .25
          ..armLB = .15
          ..armRA = active ? -2.6 - wiggle : -.25
          ..armRB = -.15
          ..happyEyes = c < 1.8 ? 1 : 0
          ..smile = 1
          ..mouthOpen = c < 1.8 ? .8 : .2
          ..blush = .8
          ..headTilt = .1 * math.sin(c * 6) * (active ? 1 : 0)
          ..browL = -4
          ..browR = -4
          ..pupilX = 0
          ..pupilY = 0;
      case 'hot':
        final beat = c * 2 * math.pi * 1.8;
        final dancing = c < 3.2;
        p
          ..lean = dancing ? .12 * math.sin(beat / 2) : 0
          ..sway = dancing ? 6 * math.sin(beat / 2) : 0
          ..armLA = dancing ? 1.4 + 1.2 * math.sin(beat) : 2.5
          ..armLB = dancing ? .5 : .2
          ..armRA = dancing ? -1.4 + 1.2 * math.sin(beat) : -2.5
          ..armRB = dancing ? -.5 : -.2
          ..legL = dancing ? .22 * math.max(0, math.sin(beat)) : 0
          ..legR = dancing ? -.22 * math.max(0, -math.sin(beat)) : 0
          ..headTilt = .15 * math.sin(beat / 2)
          ..happyEyes = .4
          ..eyeOpen = 1.1
          ..smile = 1
          ..mouthOpen = .85
          ..blush = 1
          ..browL = -5
          ..browR = -5
          ..pupilX = 0
          ..pupilY = 0;
      case 'wrong':
      case 'sad':
        final shrug = _hump(c, .45, 1.3);
        final recovered = _smooth((c - 1.2) / .6);
        p
          ..headTilt = c < .4 ? -.13 : .1 * shrug
          ..lean = c < .4 ? -.05 : 0
          ..eyeOpen = c < .45 ? .3 : 1
          ..worry = 1 - recovered * .7
          ..browL = -2 * shrug
          ..browR = -2 * shrug
          ..mouthOpen = c < .45 ? .22 : .05
          ..mouthWide = c < .45 ? .8 : .9
          ..smile = -.6 + 1.0 * recovered
          ..shoulderLift = c < .4 ? 5 : 7 * shrug
          ..armLA = shrug > .05 ? .95 : .3
          ..armLB = shrug > .05 ? 1.75 : -.3
          ..armRA = shrug > .05 ? -.95 : -.3
          ..armRB = shrug > .05 ? -1.75 : .3
          ..pupilX = c < 1.2 ? -.2 : 0
          ..pupilY = c < 1.2 ? .5 : 0;
        if (widget.mood == 'sad' && c > 2.0) {
          // Shake it off: an encouraging thumbs up.
          p
            ..armRA = -1.0
            ..armRB = -1.45
            ..frontR = true
            ..smile = .8
            ..worry = 0
            ..browL = -2
            ..browR = -2;
        }
      default:
        _idlePose(p, t);
    }
    // Learner nudges: a quick pleased glance towards the answer.
    final nudge = _hump(t - _nudgeAt, 0, .55);
    if (nudge > 0) {
      p
        ..smile = math.max(p.smile, .45 + .4 * nudge)
        ..browL = p.browL - 2 * nudge
        ..browR = p.browR - 2 * nudge;
    }
    // Tapping the tutor: a giggle and a hug.
    final tickle = t - _tickleAt;
    if (tickle >= 0 && tickle < 1.2) {
      p
        ..happyEyes = 1
        ..mouthOpen = .7
        ..smile = 1
        ..blush = 1
        ..armLA = .55
        ..armLB = -1.35
        ..armRA = -.55
        ..armRB = 1.35
        ..frontL = true
        ..frontR = true
        ..sway = 3 * math.sin(tickle * 32) * (1 - tickle / 1.2)
        ..headTilt = .12 * math.sin(tickle * 12);
    }
    // An entrance greets the learner with a wave.
    final enter = t - _enterAt;
    if (enter < 1.6 && widget.mood == 'idle') {
      p
        ..armRA = -2.55
        ..armRB = -.5 + .45 * math.sin(enter * 14)
        ..smile = .9
        ..mouthOpen = .3
        ..browL = -2.5
        ..browR = -2.5
        ..pupilX = 0
        ..pupilY = 0;
    }
    return p;
  }

  void _idlePose(_Pose p, double t) {
    final idle = _idle;
    if (idle == null) return;
    final a = t - _idleAt;
    final d = _idleLength[idle]!;
    final on = _hump(a, 0, d) > .02;
    switch (idle) {
      case _IdleAction.wave:
        if (!on) return;
        p
          ..armRA = -2.55
          ..armRB = -.5 + .45 * math.sin(a * 14)
          ..smile = .85
          ..mouthOpen = .25
          ..headTilt = .08
          ..browL = -2
          ..browR = -2
          ..pupilX = 0
          ..pupilY = 0;
      case _IdleAction.look:
        final look = .9 * math.sin(a / d * 2 * math.pi);
        p
          ..headTurn = look
          ..pupilX = look * 1.1
          ..headTilt = .04 * look;
      case _IdleAction.stretch:
        if (!on) return;
        p
          ..armLA = 2.75
          ..armLB = -.25
          ..armRA = -2.75
          ..armRB = .25
          ..frontL = false
          ..eyeOpen = .25
          ..mouthOpen = .65
          ..mouthWide = .6
          ..smile = 0
          ..headTilt = -.06;
      case _IdleAction.hair:
        if (!on) return;
        p
          ..armLA = 2.45
          ..armLB = .7 + .1 * math.sin(a * 9)
          ..frontL = true
          ..headTilt = -.1
          ..smile = .65
          ..pupilX = .5;
      case _IdleAction.bounce:
        p
          ..smile = .8
          ..happyEyes = on ? .8 : 0
          ..armLA = .45
          ..armRA = -.45;
      case _IdleAction.peek:
        p
          ..lean = .09 * _hump(a, 0, d)
          ..headTilt = .14 * _hump(a, 0, d)
          ..browR = -4.5 * _hump(a, 0, d)
          ..smile = .65
          ..pupilX = 0
          ..pupilY = 0;
    }
  }

  /// Vertical hop (negative is up) and squash, computed exactly per clip so
  /// jumps keep crisp anticipation and landing.
  (double, double) _hopAndSquash() {
    if (_reduced) return (0, 1);
    final c = _now - _moodAt;
    var hop = 0.0, squash = 1.0;
    void jump(double start, double air, double height) {
      squash -= .1 * _hump(c, start - .13, .13);
      final p = (c - start) / air;
      if (p > 0 && p < 1) {
        hop -= height * math.sin(p * math.pi);
        squash += .07 * math.sin(p * math.pi);
      }
      squash -= .13 * _hump(c, start + air, .2);
    }

    switch (widget.mood) {
      case 'correct':
      case 'happy':
        jump(.13, .42, 20);
      case 'celebrate':
      case 'cheer':
        jump(.13, .4, 24);
        jump(.75, .36, 16);
      case 'hot':
        if (c < 3.2) {
          final beat = (math.sin(c * 2 * math.pi * 1.8)).abs();
          hop -= 10 * beat;
          squash += .05 * beat - .03;
        } else {
          jump(3.25, .4, 22);
        }
      case 'wrong':
      case 'sad':
        squash -= .06 * _hump(c, 0, .35);
      case 'idle':
        if (_idle == _IdleAction.bounce) {
          final a = _now - _idleAt;
          hop -= 8 * _hump(a, .1, .35) + 6 * _hump(a, .55, .3);
          squash -= .07 * _hump(a, .45, .12) + .07 * _hump(a, .85, .14);
        }
        if (_idle == _IdleAction.stretch) {
          squash += .05 * _hump(_now - _idleAt, .1, 1.8);
        }
    }
    final tickle = _now - _tickleAt;
    if (tickle >= 0 && tickle < .5) {
      hop -= 9 * _hump(tickle, 0, .32);
      squash -= .08 * _hump(tickle, .3, .15);
    }
    // Pop in on entrance with an elastic overshoot.
    final enter = _now - _enterAt;
    if (enter < .7) {
      final e = Curves.elasticOut.transform(_clamp01(enter / .7));
      hop += 34 * (1 - e);
      squash *= .55 + .45 * e;
    }
    return (hop, squash);
  }

  void _poke() {
    if (_reduced) return;
    _tickleAt = _now;
    widget.onPoke?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
        label: [
          'Kristina, your Serbian tutor',
          'Miloš, your practice friend',
          'Zara, your practice friend'
        ][widget.character % 3],
        image: true,
        child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _poke,
            child: RepaintBoundary(
                child: SizedBox(
                    width: widget.width,
                    height: widget.height,
                    child: CustomPaint(
                        painter: _KristinaPainter(this, _frame))))));
  }
}

class _KristinaPainter extends CustomPainter {
  final _AnimatedKristinaState s;
  _KristinaPainter(this.s, Listenable frame) : super(repaint: frame);
  int get character => s.widget.character;
  String get mood => s.widget.mood;
  Color get hair => [
        const Color(0xFF56372D),
        const Color(0xFF273A49),
        const Color(0xFF302536)
      ][character % 3];
  Color get skin => [
        const Color(0xFFFFBC9D),
        const Color(0xFFE6AF7F),
        const Color(0xFFB97959)
      ][character % 3];
  Color get shirt => [
        const Color(0xFFC43F72),
        const Color(0xFFFFAE45),
        const Color(0xFF31B6A6)
      ][character % 3];
  static const jeans = Color(0xFF3478C8);
  static const mouthColor = Color(0xFF843F37);
  static const confettiColors = [
    Color(0xFFFFC84A),
    Color(0xFF58CC02),
    Color(0xFF55C8F5),
    Color(0xFFFF7A59),
    Color(0xFFB77CF2),
  ];
  final Paint p = Paint()..isAntiAlias = true;
  void fill(Canvas c, Color color, void Function(Paint) draw) {
    p
      ..color = color
      ..style = PaintingStyle.fill;
    draw(p);
  }

  void oval(Canvas c, Rect r, Color color) =>
      fill(c, color, (p) => c.drawOval(r, p));
  void round(Canvas c, Rect r, double radius, Color color) => fill(
      c,
      color,
      (p) =>
          c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)), p));
  void stroke(Canvas c, Path path, Color color, double width) {
    p
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    c.drawPath(path, p);
    p.style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pose = s._pose;
    final bust = s.widget.framing == TutorFraming.bust;
    final view = bust
        ? const Rect.fromLTWH(-8, -18, 216, 236)
        : const Rect.fromLTWH(0, 0, 200, 300);
    final scale = math.min(size.width / view.width, size.height / view.height);
    canvas.translate((size.width - view.width * scale) / 2 - view.left * scale,
        (size.height - view.height * scale) / 2 - view.top * scale);
    canvas.scale(scale);
    final time = s._reduced ? 1.56 : s._now;
    final breath = math.sin(time * math.pi * 2 / 5.2);
    final (hop, squash) = s._hopAndSquash();
    if (bust) {
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(
          view.left - 200, view.top - 200, view.right + 200, view.bottom));
    } else {
      final lift = (-hop / 60).clamp(0.0, .6);
      oval(
          canvas,
          Rect.fromCenter(
              center: const Offset(100, 287),
              width: 96 * (1 - lift) * (2 - squash),
              height: 12 * (1 - lift)),
          Color.fromRGBO(0, 0, 0, .09 * (1 - lift)));
    }
    if (!s._reduced) _confetti(canvas);
    canvas.save();
    canvas.translate(pose.sway, hop);
    // Squash and stretch around the feet.
    canvas.translate(100, 287);
    canvas.scale(1 + (1 - squash) * .55, squash);
    canvas.translate(-100, -287);
    _legs(canvas, pose);
    canvas.save();
    canvas.translate(100, 205);
    canvas.rotate(pose.lean);
    canvas.translate(-100, -205);
    final headPivot = Offset(102, 93 + breath - pose.shoulderLift * .4);
    void headSpace(double extraTilt) {
      canvas.translate(headPivot.dx, headPivot.dy + pose.headNod);
      canvas.rotate(pose.headTilt + extraTilt);
      canvas.translate(-102, -93);
    }

    // Hair behind body, separated from head so it swings after it.
    if (character != 1) {
      canvas.save();
      headSpace(character == 0
          ? (s._hairLag - pose.headTilt) * .6
          : .025 * breath + (s._hairLag - pose.headTilt) * .6);
      fill(
          canvas,
          hair,
          (p) => canvas.drawPath(
              character == 0
                  ? (Path()
                    ..moveTo(34, 47)
                    ..cubicTo(34, 64, 18, 72, 21, 90)
                    ..cubicTo(22, 106, 34, 113, 28, 129)
                    ..cubicTo(23, 141, 16, 144, 21, 154)
                    ..cubicTo(25, 163, 40, 157, 55, 157)
                    ..cubicTo(64, 156, 68, 146, 79, 142)
                    ..lineTo(83, 113)
                    ..lineTo(66, 59)
                    ..close())
                  : (Path()
                    ..moveTo(62, 52)
                    ..cubicTo(34, 58, 16, 96, 24, 146)
                    ..cubicTo(30, 178, 52, 190, 74, 172)
                    ..cubicTo(88, 160, 84, 118, 74, 78)
                    ..cubicTo(70, 64, 66, 56, 62, 52)
                    ..close()),
              p));
      canvas.restore();
    }
    final shoulderY = 151 + breath - pose.shoulderLift;
    if (!pose.frontL)
      _arm(canvas, Offset(65, shoulderY), pose.armLA, pose.armLB);
    if (!pose.frontR) {
      _arm(canvas, Offset(136, shoulderY), pose.armRA, pose.armRB);
    }
    // Turtleneck torso.
    round(canvas, Rect.fromLTWH(61, 133 + breath, 79, 79), 20, shirt);
    round(
        canvas,
        Rect.fromLTWH(82, 120 + breath - pose.shoulderLift * .4, 40, 28),
        9,
        Color.lerp(shirt, Colors.black, .12)!);
    canvas.save();
    headSpace(0);
    _head(canvas, pose, time);
    canvas.restore();
    if (pose.frontL)
      _arm(canvas, Offset(65, shoulderY), pose.armLA, pose.armLB);
    if (pose.frontR) {
      _arm(canvas, Offset(136, shoulderY), pose.armRA, pose.armRB);
    }
    canvas.restore();
    canvas.restore();
    if (bust) canvas.restore();
    if (!s._reduced) _effects(canvas);
  }

  void _legs(Canvas canvas, _Pose pose) {
    void leg(Offset hip, double angle, double footX, double endX, Color color) {
      canvas.save();
      canvas.translate(hip.dx, hip.dy);
      canvas.rotate(angle);
      canvas.translate(-hip.dx, -hip.dy);
      stroke(
          canvas,
          Path()
            ..moveTo(hip.dx, hip.dy)
            ..lineTo(endX, 264),
          color,
          27);
      round(canvas, Rect.fromLTWH(footX, 258, 20, 19), 7, skin);
      final left = footX < 100;
      round(canvas, Rect.fromLTWH(left ? footX - 16 : footX - 2, 271, 43, 15),
          7, const Color(0xFFFFF4DF));
      stroke(
          canvas,
          Path()
            ..moveTo(left ? footX + 3 : footX + 14, 274)
            ..lineTo(left ? footX + 14 : footX + 24, 274),
          const Color(0xFFE2D5BD),
          3);
      canvas.restore();
    }

    leg(const Offset(82, 201), pose.legL, 59, 74, jeans);
    leg(const Offset(119, 201), pose.legR, 119, 126, const Color(0xFF2865B0));
  }

  void _arm(Canvas canvas, Offset shoulder, double upper, double fore) {
    canvas.save();
    canvas.translate(shoulder.dx, shoulder.dy);
    canvas.rotate(upper);
    stroke(
        canvas,
        Path()
          ..moveTo(0, 0)
          ..lineTo(0, 25),
        shirt,
        21);
    canvas.translate(0, 25);
    canvas.rotate(fore);
    stroke(
        canvas,
        Path()
          ..moveTo(0, 0)
          ..lineTo(0, 21),
        Color.lerp(shirt, Colors.black, .05)!,
        19);
    oval(
        canvas,
        Rect.fromCenter(center: const Offset(0, 29), width: 21, height: 23),
        skin);
    stroke(
        canvas,
        Path()
          ..moveTo(-3, 31)
          ..lineTo(-6, 24),
        const Color(0xFFE99A7C),
        2);
    canvas.restore();
  }

  void _head(Canvas canvas, _Pose pose, double time) {
    final fx = pose.headTurn * 6;
    oval(canvas, Rect.fromLTWH(29 - fx * .4, 72, 30, 30), skin);
    oval(canvas, Rect.fromLTWH(143 - fx * .4, 72, 29, 30), skin);
    round(canvas, const Rect.fromLTWH(47, 33, 109, 100), 34, skin);
    if (character == 1) {
      fill(
          canvas,
          hair,
          (p) => canvas.drawPath(
              Path()
                ..moveTo(50, 74)
                ..cubicTo(38, 42, 56, 18, 96, 16)
                ..cubicTo(134, 12, 166, 26, 162, 64)
                ..cubicTo(156, 76, 146, 70, 130, 64)
                ..cubicTo(110, 56, 88, 54, 72, 60)
                ..cubicTo(60, 66, 54, 70, 50, 74)
                ..close(),
              p));
      fill(
          canvas,
          hair,
          (p) => canvas.drawPath(
              Path()
                ..moveTo(44, 66)
                ..lineTo(40, 38)
                ..lineTo(57, 39)
                ..lineTo(65, 20)
                ..lineTo(83, 30)
                ..lineTo(101, 13)
                ..lineTo(117, 29)
                ..lineTo(141, 25)
                ..lineTo(155, 54)
                ..lineTo(148, 73)
                ..lineTo(140, 58)
                ..lineTo(65, 55)
                ..close(),
              p));
    } else {
      fill(
          canvas,
          hair,
          (p) => canvas.drawPath(
              character == 0
                  ? (Path()
                    ..moveTo(52, 76)
                    ..cubicTo(47, 72, 42, 71, 35, 75)
                    ..cubicTo(38, 62, 29, 54, 31, 39)
                    ..cubicTo(29, 21, 44, 9, 62, 6)
                    ..cubicTo(76, 4, 90, 1, 99, 4)
                    ..cubicTo(112, 8, 118, 20, 116, 32)
                    ..lineTo(133, 32)
                    ..cubicTo(151, 31, 160, 42, 157, 62)
                    ..lineTo(156, 76)
                    ..cubicTo(154, 61, 149, 48, 133, 48)
                    ..lineTo(120, 48)
                    ..cubicTo(111, 48, 105, 46, 102, 38)
                    ..cubicTo(97, 48, 89, 49, 79, 49)
                    ..cubicTo(62, 48, 53, 56, 52, 76)
                    ..close())
                  : (Path()
                    ..moveTo(54, 76)
                    ..cubicTo(20, 52, 18, 8, 58, 4)
                    ..cubicTo(88, 1, 108, 14, 116, 24)
                    ..cubicTo(126, 16, 154, 18, 168, 36)
                    ..cubicTo(178, 50, 170, 68, 154, 72)
                    ..cubicTo(138, 64, 116, 58, 98, 58)
                    ..cubicTo(78, 58, 64, 66, 54, 76)
                    ..close()),
              p));
    }
    // Blush sits under the eyes and warms with joy.
    if (pose.blush > .02) {
      final blush =
          Color.fromRGBO(255, 120, 120, (.38 * pose.blush).clamp(0.0, .38));
      oval(
          canvas,
          Rect.fromCenter(center: Offset(68 + fx, 103), width: 22, height: 11),
          blush);
      oval(
          canvas,
          Rect.fromCenter(center: Offset(134 + fx, 103), width: 22, height: 11),
          blush);
    }
    _eyes(canvas, pose, fx, time);
    if (character == 2) {
      final glasses = Paint()
        ..color = const Color(0xFF7455C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(64 + fx, 62, 33, 38), const Radius.circular(12)),
          glasses);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(102 + fx, 62, 33, 38), const Radius.circular(12)),
          glasses);
      canvas.drawLine(Offset(97 + fx, 78), Offset(102 + fx, 78), glasses);
    }
    // Brows: raise lifts both ends, worry lifts the inner ends.
    final w = pose.worry * 5;
    stroke(
        canvas,
        Path()
          ..moveTo(69 + fx, 59 + pose.browL + w * .4)
          ..quadraticBezierTo(
              78 + fx, 49 + pose.browL - w * .3, 88 + fx, 55 + pose.browL - w),
        hair,
        5);
    stroke(
        canvas,
        Path()
          ..moveTo(108 + fx, 54 + pose.browR - w)
          ..quadraticBezierTo(119 + fx, 48 + pose.browR - w * .3, 130 + fx,
              54 + pose.browR + w * .4),
        hair,
        5);
    oval(canvas, Rect.fromLTWH(95 + fx * 1.1, 88, 12, 15),
        const Color(0xFFED9674));
    for (final point in const [
      Offset(65, 98),
      Offset(74, 103),
      Offset(62, 107),
      Offset(132, 99),
      Offset(139, 104),
      Offset(130, 108)
    ]) {
      oval(canvas, Rect.fromCircle(center: point.translate(fx, 0), radius: 2.4),
          const Color(0xFFD78C71));
    }
    _mouth(canvas, pose, fx);
    // A sweat drop slides down after a mistake.
    final c = s._now - s._moodAt;
    if (!s._reduced &&
        (mood == 'wrong' || mood == 'sad') &&
        c > .1 &&
        c < 1.6) {
      final y = 52 + (c - .1) * 14;
      final a = (1 - _smooth((c - 1.2) / .4));
      final drop = Path()
        ..moveTo(152, y)
        ..quadraticBezierTo(146, y + 12, 152, y + 15)
        ..quadraticBezierTo(158, y + 12, 152, y);
      fill(canvas, Color.fromRGBO(120, 196, 245, a),
          (p) => canvas.drawPath(drop, p));
      oval(canvas, Rect.fromLTWH(150, y + 8, 3, 4),
          Color.fromRGBO(255, 255, 255, a));
    }
  }

  void _eyes(Canvas canvas, _Pose pose, double fx, double time) {
    final blinkAge = s._now - s._blinkAt;
    final blink = s._reduced ? 0.0 : _hump(blinkAge, 0, .15);
    final open = (pose.eyeOpen * (1 - blink)).clamp(.08, 1.2);
    final sparkle = mood == 'hot';
    for (final cx in [81.0 + fx, 119.0 + fx]) {
      if (pose.happyEyes > .5 && blink < .5) {
        stroke(
            canvas,
            Path()
              ..moveTo(cx - 10, 85)
              ..quadraticBezierTo(cx, 69, cx + 10, 85),
            const Color(0xFF4A2618),
            5);
        continue;
      }
      final h = 33 * open;
      if (h < 12) {
        // Closed or squeezed eyes read as soft lines.
        final squeeze = pose.worry > .3 ? (cx < 100 ? -3.0 : 3.0) : 0.0;
        stroke(
            canvas,
            Path()
              ..moveTo(cx - 10, 81 + squeeze)
              ..quadraticBezierTo(cx, 85, cx + 10, 81 - squeeze),
            const Color(0xFF4A2618),
            4.5);
        continue;
      }
      final eye = Rect.fromCenter(center: Offset(cx, 81), width: 25, height: h);
      oval(canvas, eye, Colors.white);
      canvas.save();
      canvas.clipPath(Path()..addOval(eye));
      final px = cx + 3 + pose.pupilX.clamp(-1.4, 1.4) * 4.5;
      final py = 81 + pose.pupilY.clamp(-1.2, 1.2) * 4.5;
      oval(
          canvas,
          Rect.fromCenter(center: Offset(px, py), width: 12, height: 22),
          const Color(0xFF82400F));
      if (sparkle) {
        final r = 4 + math.sin(time * 12) * 1.2;
        final star = Path()
          ..moveTo(px, py - 6 - r)
          ..lineTo(px + 1.6, py - 6 - 1.6)
          ..lineTo(px + r, py - 6)
          ..lineTo(px + 1.6, py - 6 + 1.6)
          ..lineTo(px, py - 6 + r)
          ..lineTo(px - 1.6, py - 6 + 1.6)
          ..lineTo(px - r, py - 6)
          ..lineTo(px - 1.6, py - 6 - 1.6)
          ..close();
        fill(canvas, Colors.white, (p) => canvas.drawPath(star, p));
      } else {
        oval(canvas, Rect.fromLTWH(px - 5, py - 11, 5, 7), Colors.white);
      }
      canvas.restore();
    }
  }

  void _mouth(Canvas canvas, _Pose pose, double fx) {
    final cx = 101 + fx * 1.1;
    const cy = 112.0;
    final open = pose.mouthOpen.clamp(0.0, 1.0);
    final smile = pose.smile.clamp(-1.0, 1.0);
    final half = 12 * pose.mouthWide.clamp(.4, 1.4) + 3 * smile.clamp(0.0, 1.0);
    if (open < .08) {
      stroke(
          canvas,
          Path()
            ..moveTo(cx - half, cy - 2)
            ..quadraticBezierTo(cx, cy - 2 + 13 * smile, cx + half, cy - 2),
          const Color(0xFFD77D59),
          5);
      return;
    }
    final corner = cy - 4 * smile;
    final top = cy - 3 - open * 3 + smile * 2;
    final bottom = cy + open * 22 + smile * 4;
    final shape = Path()
      ..moveTo(cx - half, corner)
      ..quadraticBezierTo(cx, top, cx + half, corner)
      ..quadraticBezierTo(cx, bottom, cx - half, corner)
      ..close();
    fill(canvas, mouthColor, (p) => canvas.drawPath(shape, p));
    canvas.save();
    canvas.clipPath(shape);
    if (smile > .3) {
      round(canvas, Rect.fromLTWH(cx - half, top - 4, half * 2, 7 + open * 2),
          2, Colors.white);
    }
    if (open > .35) {
      oval(
          canvas,
          Rect.fromCenter(
              center: Offset(cx, bottom * .5 + corner * .5 + open * 5),
              width: half * 1.2,
              height: 10 + open * 6),
          const Color(0xFFE5707A));
    }
    canvas.restore();
  }

  /// Confetti bursts from behind the tutor so it never covers the face.
  void _confetti(Canvas canvas) {
    final c = s._now - s._moodAt;
    final burst = switch (mood) {
      'correct' || 'happy' => 12,
      'celebrate' || 'cheer' => 22,
      'hot' => 30,
      _ => 0,
    };
    if (burst > 0 && c < 2.2) {
      for (var i = 0; i < burst; i++) {
        final seed = (i * 2654435761 + character * 97) & 0xFFFF;
        final angle =
            -math.pi / 2 + ((seed % 1000) / 1000 - .5) * math.pi * 1.5;
        final speed = 130 + (seed % 97) * 1.6;
        final start = mood == 'hot' ? (i % 3) * .35 : 0.0;
        final t = c - .15 - start;
        if (t < 0 || t > 1.6) continue;
        final pos = Offset(100 + math.cos(angle) * speed * t,
            130 + math.sin(angle) * speed * t + 180 * t * t);
        final alpha = 1 - _clamp01((t - 1.0) / .6);
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(t * 9 + i);
        round(
            canvas,
            Rect.fromCenter(center: Offset.zero, width: 7, height: 11),
            1.5,
            confettiColors[i % confettiColors.length].withValues(alpha: alpha));
        canvas.restore();
      }
    }
  }

  void _effects(Canvas canvas) {
    final c = s._now - s._moodAt;
    if (mood == 'hot' && c < 3.6) {
      // Music notes drift up while dancing.
      for (var i = 0; i < 3; i++) {
        final t = (c * .8 + i / 3) % 1;
        final x = (i.isEven ? 30.0 : 172.0) + math.sin(t * 6 + i) * 8;
        final y = 120 - t * 110;
        final color = confettiColors[(i + 2) % 5].withValues(alpha: 1 - t);
        oval(canvas,
            Rect.fromCenter(center: Offset(x, y), width: 10, height: 8), color);
        stroke(
            canvas,
            Path()
              ..moveTo(x + 4.5, y)
              ..lineTo(x + 4.5, y - 17)
              ..lineTo(x + 11, y - 13),
            color,
            2.5);
      }
    }
    final tickle = s._now - s._tickleAt;
    if (tickle >= 0 && tickle < 1.3) {
      for (var i = 0; i < 4; i++) {
        final t = _clamp01((tickle - i * .12) / 1.0);
        if (t <= 0 || t >= 1) continue;
        final x = 100 + (i - 1.5) * 26 + math.sin(t * 8 + i) * 6;
        final y = 40 - t * 70;
        final a = 1 - t;
        final heart = Path()
          ..moveTo(x, y + 5)
          ..cubicTo(x - 9, y - 2, x - 5, y - 10, x, y - 4)
          ..cubicTo(x + 5, y - 10, x + 9, y - 2, x, y + 5)
          ..close();
        fill(canvas, Color.fromRGBO(255, 90, 120, a),
            (p) => canvas.drawPath(heart, p));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KristinaPainter old) => old.s != s;
}
