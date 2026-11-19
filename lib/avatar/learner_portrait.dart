import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'learner_look.dart';

/// A chibi-style bust of the learner, drawn piece by piece so every style
/// and colour combines. [blink] closes the eyes (for the living preview).
class LearnerPortrait extends StatelessWidget {
  final LearnerLook look;
  final bool headOnly;
  final bool blink;
  const LearnerPortrait(
      {super.key,
      required this.look,
      this.headOnly = false,
      this.blink = false});

  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _PortraitPainter(look, headOnly, blink),
      child: const SizedBox.expand());
}

/// The look's background colour and pattern, filling its box.
class AvatarBackdrop extends StatelessWidget {
  final LearnerLook look;
  final Widget? child;
  const AvatarBackdrop({super.key, required this.look, this.child});
  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _BackdropPainter(look.background, look.backdrop),
      child: child ?? const SizedBox.expand());
}

class LearnerBadge extends StatelessWidget {
  final LearnerLook look;
  final double size;
  final double radius;
  const LearnerBadge(
      {super.key, required this.look, this.size = 46, this.radius = 18});

  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border:
              Border.all(color: Colors.white.withValues(alpha: .6), width: 2)),
      clipBehavior: Clip.antiAlias,
      child: AvatarBackdrop(
          look: look, child: LearnerPortrait(look: look, headOnly: true)));
}

Color _darker(Color c, [double t = .18]) => Color.lerp(c, Colors.black, t)!;
Color _lighter(Color c, [double t = .25]) => Color.lerp(c, Colors.white, t)!;
Paint _paint(Color c) => Paint()
  ..color = c
  ..isAntiAlias = true;
Paint _stroke(Color c, double width) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

Path _star(Offset c, double r, [double inner = .45, int points = 5]) {
  final path = Path();
  for (var i = 0; i < points * 2; i++) {
    final radius = i.isEven ? r : r * inner;
    final a = -math.pi / 2 + i * math.pi / points;
    final p = c + Offset(math.cos(a) * radius, math.sin(a) * radius);
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

Path _heart(Offset c, double s) => Path()
  ..moveTo(c.dx, c.dy + s * .9)
  ..cubicTo(
      c.dx - s * 1.3, c.dy, c.dx - s * .8, c.dy - s * .95, c.dx, c.dy - s * .35)
  ..cubicTo(
      c.dx + s * .8, c.dy - s * .95, c.dx + s * 1.3, c.dy, c.dx, c.dy + s * .9)
  ..close();

class _BackdropPainter extends CustomPainter {
  final int color, style;
  _BackdropPainter(this.color, this.style);

  @override
  void paint(Canvas canvas, Size size) {
    final base = LearnerLook.backgrounds[color];
    final rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
              center: const Alignment(0, -.3),
              radius: 1.1,
              colors: [_lighter(base, .22), base]).createShader(rect));
    final light = base.computeLuminance() > .55;
    final mark = light
        ? _darker(base, .12).withValues(alpha: .55)
        : _lighter(base, .25).withValues(alpha: .5);
    final u = math.max(size.width, size.height) / 100;
    final random = math.Random(color * 31 + style);
    switch (style) {
      case 1: // dots
        for (var y = 0.0; y < size.height + 10 * u; y += 14 * u) {
          final shift = (y / (14 * u)).round().isOdd ? 7 * u : 0;
          for (var x = 0.0; x < size.width + 10 * u; x += 14 * u) {
            canvas.drawCircle(Offset(x + shift, y), 2.6 * u, _paint(mark));
          }
        }
      case 2: // stars
        for (var i = 0; i < 14; i++) {
          canvas.drawPath(
              _star(
                  Offset(random.nextDouble() * size.width,
                      random.nextDouble() * size.height),
                  (3 + random.nextDouble() * 4) * u),
              _paint(mark));
        }
      case 3: // sunburst
        final c = Offset(size.width / 2, size.height * .42);
        final r = size.longestSide;
        for (var i = 0; i < 16; i += 2) {
          final a = i * math.pi / 8;
          canvas.drawPath(
              Path()
                ..moveTo(c.dx, c.dy)
                ..lineTo(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r)
                ..lineTo(c.dx + math.cos(a + math.pi / 8) * r,
                    c.dy + math.sin(a + math.pi / 8) * r)
                ..close(),
              _paint(mark.withValues(alpha: .35)));
        }
      case 4: // hearts
        for (var i = 0; i < 12; i++) {
          canvas.drawPath(
              _heart(
                  Offset(random.nextDouble() * size.width,
                      random.nextDouble() * size.height),
                  (3 + random.nextDouble() * 3) * u),
              _paint(mark));
        }
      case 5: // waves
        for (var band = 0; band < 3; band++) {
          final y = size.height * (.62 + band * .14);
          final path = Path()..moveTo(0, y);
          for (var x = 0.0; x <= size.width; x += 4) {
            path.lineTo(
                x, y + math.sin(x / size.width * math.pi * 4 + band) * 4 * u);
          }
          path
            ..lineTo(size.width, size.height)
            ..lineTo(0, size.height)
            ..close();
          canvas.drawPath(
              path, _paint(mark.withValues(alpha: .35 + band * .1)));
        }
      case 6: // confetti
        const colors = [
          Color(0xFFFF6B4A), Color(0xFF7B5CFA), Color(0xFF14B39C), //
          Color(0xFFFFC62E), Color(0xFFEC4899), Color(0xFF3B82F6),
        ];
        for (var i = 0; i < 26; i++) {
          canvas.save();
          canvas.translate(random.nextDouble() * size.width,
              random.nextDouble() * size.height);
          canvas.rotate(random.nextDouble() * math.pi);
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromCenter(
                      center: Offset.zero, width: 5 * u, height: 2.4 * u),
                  Radius.circular(u)),
              _paint(colors[i % colors.length].withValues(alpha: .75)));
          canvas.restore();
        }
      case 7: // city skyline
        final ground = size.height * .78;
        final path = Path()..moveTo(0, size.height);
        var x = 0.0;
        while (x < size.width) {
          final w = (8 + random.nextDouble() * 12) * u;
          final h = (10 + random.nextDouble() * 22) * u;
          path
            ..lineTo(x, ground - h)
            ..lineTo(x + w, ground - h);
          x += w;
        }
        path
          ..lineTo(size.width, size.height)
          ..close();
        canvas.drawPath(path, _paint(mark.withValues(alpha: .45)));
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter old) =>
      old.color != color || old.style != style;
}

class _PortraitPainter extends CustomPainter {
  final LearnerLook look;
  final bool headOnly, blink;
  _PortraitPainter(this.look, this.headOnly, this.blink);

  late Color skin, hair, outline;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (headOnly) {
      final scale = math.min(size.width / 150, size.height / 150);
      canvas.translate(size.width / 2, size.height / 2 + size.height * .05);
      canvas.scale(scale);
      canvas.translate(-100, -104);
    } else {
      final scale = math.min(size.width / 200, size.height / 240);
      canvas.translate(
          (size.width - 200 * scale) / 2, (size.height - 240 * scale) / 2);
      canvas.scale(scale);
    }
    skin = look.skinColor;
    hair = look.hairColorValue;
    outline = _darker(skin, .32);
    _bust(canvas);
    canvas.restore();
  }

  void _bust(Canvas canvas) {
    _hairBehind(canvas);
    if (look.outfit == 1) _hoodBack(canvas);
    _neck(canvas);
    _outfit(canvas);
    _hairOverShoulders(canvas);
    _ears(canvas);
    _head(canvas);
    _face(canvas);
    _hairFront(canvas);
    _glasses(canvas);
    _hat(canvas);
  }

  // ---- Body ---------------------------------------------------------------

  Path get _torso => Path()
    ..moveTo(16, 244)
    ..cubicTo(16, 206, 38, 186, 70, 180)
    ..quadraticBezierTo(100, 174, 130, 180)
    ..cubicTo(162, 186, 184, 206, 184, 244)
    ..close();

  void _neck(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(84, 138, 32, 52), const Radius.circular(14));
    canvas.drawRRect(rect, _paint(skin));
    canvas.save();
    canvas.clipRRect(rect);
    canvas.drawOval(
        const Rect.fromLTWH(76, 136, 48, 22), _paint(_darker(skin, .14)));
    canvas.restore();
  }

  void _hoodBack(Canvas canvas) {
    final c = look.outfitColorValue;
    canvas.drawPath(
        Path()
          ..moveTo(52, 196)
          ..cubicTo(50, 160, 70, 148, 100, 148)
          ..cubicTo(130, 148, 150, 160, 148, 196)
          ..close(),
        _paint(_darker(c, .22)));
  }

  void _pattern(Canvas canvas, Path region, Color base) {
    if (look.pattern == 0) return;
    final mark = base.computeLuminance() > .55
        ? _darker(base, .22).withValues(alpha: .55)
        : _lighter(base, .35).withValues(alpha: .6);
    canvas.save();
    canvas.clipPath(region);
    switch (look.pattern) {
      case 1:
        for (var y = 186.0; y < 244; y += 13) {
          canvas.drawRect(Rect.fromLTWH(0, y, 200, 6), _paint(mark));
        }
      case 2:
        for (var y = 188.0; y < 250; y += 14) {
          final shift = ((y - 188) / 14).round().isOdd ? 7.0 : 0.0;
          for (var x = 10.0; x < 200; x += 14) {
            canvas.drawCircle(Offset(x + shift, y), 3, _paint(mark));
          }
        }
      case 3:
        for (var y = 194.0; y < 250; y += 20) {
          final shift = ((y - 194) / 20).round().isOdd ? 10.0 : 0.0;
          for (var x = 14.0; x < 200; x += 20) {
            canvas.drawPath(_star(Offset(x + shift, y), 5.5), _paint(mark));
          }
        }
      case 4:
        for (var y = 194.0; y < 250; y += 20) {
          final shift = ((y - 194) / 20).round().isOdd ? 10.0 : 0.0;
          for (var x = 14.0; x < 200; x += 20) {
            canvas.drawPath(_heart(Offset(x + shift, y), 4.4), _paint(mark));
          }
        }
      case 5:
        for (var y = 192.0; y < 250; y += 16) {
          final path = Path()..moveTo(0, y);
          for (var x = 0.0; x <= 200; x += 10) {
            path.lineTo(x + 5, y + ((x / 10).round().isEven ? 6 : 0));
          }
          canvas.drawPath(path, _stroke(mark, 3));
        }
    }
    canvas.restore();
  }

  void _garment(Canvas canvas, Path region, Color color) {
    canvas.drawPath(region, _paint(color));
    _pattern(canvas, region, color);
    // Soft shading down the sides.
    canvas.save();
    canvas.clipPath(region);
    canvas.drawRect(
        const Rect.fromLTWH(0, 170, 200, 80),
        Paint()
          ..shader = const LinearGradient(colors: [
            Color(0x22000000),
            Color(0x00000000),
            Color(0x00000000),
            Color(0x22000000),
          ], stops: [
            0,
            .25,
            .75,
            1
          ]).createShader(const Rect.fromLTWH(16, 170, 168, 80)));
    canvas.restore();
  }

  void _outfit(Canvas canvas) {
    final c = look.outfitColorValue;
    final dark = _darker(c, .2);
    const white = Color(0xFFF7F5F2);
    switch (look.outfit) {
      case 1: // hoodie
        _garment(canvas, _torso, c);
        canvas.drawPath(
            Path()
              ..moveTo(70, 182)
              ..quadraticBezierTo(100, 214, 130, 182),
            _stroke(dark, 7));
        for (final x in [92.0, 108.0]) {
          canvas.drawLine(
              Offset(x, 196), Offset(x - 1, 222), _stroke(white, 3));
          canvas.drawCircle(Offset(x - 1, 224), 3, _paint(white));
        }
      case 2: // sweater
        _garment(canvas, _torso, c);
        canvas.drawPath(
            Path()
              ..moveTo(78, 180)
              ..quadraticBezierTo(100, 198, 122, 180),
            _stroke(_lighter(c, .2), 9));
        for (var i = 0; i < 9; i++) {
          final t = i / 8;
          final x = 80 + 40 * t;
          final y = 181 + math.sin(t * math.pi) * 11;
          canvas.drawLine(
              Offset(x, y - 3), Offset(x, y + 3), _stroke(dark, 1.4));
        }
      case 3: // collared shirt
        _garment(canvas, _torso, c);
        for (final side in [-1.0, 1.0]) {
          canvas.drawPath(
              Path()
                ..moveTo(100, 196)
                ..lineTo(100 + side * 22, 178)
                ..lineTo(100 + side * 30, 196)
                ..close(),
              _paint(white));
        }
        for (final y in [206.0, 222.0, 238.0]) {
          canvas.drawCircle(Offset(100, y), 2.6, _paint(dark));
        }
      case 4: // dungarees over a tee
        canvas.drawPath(_torso, _paint(white));
        final bib = Path()
          ..moveTo(66, 244)
          ..lineTo(70, 204)
          ..quadraticBezierTo(70, 198, 76, 198)
          ..lineTo(124, 198)
          ..quadraticBezierTo(130, 198, 130, 204)
          ..lineTo(134, 244)
          ..close();
        _garment(canvas, bib, c);
        canvas.drawLine(
            const Offset(74, 200), const Offset(64, 182), _stroke(c, 8));
        canvas.drawLine(
            const Offset(126, 200), const Offset(136, 182), _stroke(c, 8));
        for (final x in [78.0, 122.0]) {
          canvas.drawCircle(Offset(x, 206), 4, _paint(const Color(0xFFF2C94C)));
        }
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(88, 212, 24, 16), const Radius.circular(4)),
            _stroke(dark, 2));
      case 5: // jacket
        _garment(canvas, _torso, c);
        canvas.drawPath(
            Path()
              ..moveTo(84, 180)
              ..lineTo(100, 244)
              ..lineTo(116, 180)
              ..close(),
            _paint(white));
        for (final side in [-1.0, 1.0]) {
          canvas.drawPath(
              Path()
                ..moveTo(100 + side * 16, 180)
                ..lineTo(100 + side * 28, 182)
                ..lineTo(100 + side * 18, 214)
                ..lineTo(100 + side * 6, 228)
                ..close(),
              _paint(dark));
        }
      case 6: // tank top
        canvas.drawPath(_torso, _paint(skin));
        final tank = Path()
          ..moveTo(50, 244)
          ..cubicTo(52, 220, 60, 204, 66, 194)
          ..lineTo(68, 180)
          ..lineTo(80, 180)
          ..quadraticBezierTo(100, 208, 120, 180)
          ..lineTo(132, 180)
          ..lineTo(134, 194)
          ..cubicTo(140, 204, 148, 220, 150, 244)
          ..close();
        _garment(canvas, tank, c);
      case 7: // turtleneck
        _garment(canvas, _torso, c);
        final collar = RRect.fromRectAndRadius(
            const Rect.fromLTWH(80, 160, 40, 28), const Radius.circular(10));
        canvas.drawRRect(collar, _paint(_lighter(c, .08)));
        for (final y in [168.0, 176.0]) {
          canvas.drawLine(
              Offset(84, y), Offset(116, y), _stroke(_darker(c, .12), 1.6));
        }
      case 8: // Serbian folk vest (jelek) over a white shirt
        canvas.drawPath(_torso, _paint(white));
        canvas.drawPath(
            Path()
              ..moveTo(82, 180)
              ..quadraticBezierTo(100, 192, 118, 180),
            _stroke(const Color(0xFFD64545), 3));
        for (final side in [-1.0, 1.0]) {
          final panel = Path()
            ..moveTo(100 - side * 84, 244)
            ..cubicTo(100 - side * 84, 206, 100 - side * 62, 186,
                100 - side * 30, 180)
            ..lineTo(100 - side * 14, 244)
            ..close();
          _garment(canvas, panel, c);
          // Gold embroidery along the edge.
          for (var i = 0; i < 6; i++) {
            final t = i / 5;
            final p = Offset(100 - side * (30 - 16 * t), 186 + 56 * t);
            canvas.drawCircle(p, 2.4, _paint(const Color(0xFFF2C94C)));
          }
          canvas.drawPath(_star(Offset(100 - side * 50, 214), 6, .45, 8),
              _paint(const Color(0xFFF2C94C)));
        }
      default: // t-shirt
        _garment(canvas, _torso, c);
        canvas.drawPath(
            Path()
              ..moveTo(80, 180)
              ..quadraticBezierTo(100, 196, 120, 180),
            _stroke(dark, 5));
    }
  }

  // ---- Head ---------------------------------------------------------------

  Path get _headPath {
    switch (look.face) {
      case 1: // oval
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
              const Rect.fromLTWH(47, 36, 106, 128),
              const Radius.circular(52)));
      case 2: // heart
        return Path()
          ..moveTo(100, 162)
          ..cubicTo(72, 160, 44, 140, 43, 104)
          ..cubicTo(42, 62, 66, 38, 100, 38)
          ..cubicTo(134, 38, 158, 62, 157, 104)
          ..cubicTo(156, 140, 128, 160, 100, 162)
          ..close();
      case 3: // square
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
              const Rect.fromLTWH(43, 40, 114, 120),
              const Radius.circular(36)));
      default: // round
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
              const Rect.fromLTWH(42, 40, 116, 122),
              const Radius.circular(56)));
    }
  }

  double get _earX => look.face == 1 ? 47 : 43;

  void _ears(Canvas canvas) {
    for (final side in [-1.0, 1.0]) {
      final x = 100 + side * (100 - _earX);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(x, 110), width: 22, height: 30),
          _paint(skin));
      canvas.drawOval(
          Rect.fromCenter(center: Offset(x + side, 110), width: 9, height: 15),
          _paint(_darker(skin, .14)));
      switch (look.earrings) {
        case 1:
          canvas.drawCircle(
              Offset(x, 124), 3.6, _paint(const Color(0xFFF2C94C)));
          canvas.drawCircle(Offset(x - .8, 123), 1.2, _paint(Colors.white));
        case 2:
          canvas.drawCircle(
              Offset(x, 131), 7, _stroke(const Color(0xFFF2C94C), 2.6));
      }
    }
  }

  void _head(Canvas canvas) {
    final head = _headPath;
    canvas.drawPath(head, _paint(skin));
    // A soft highlight on the forehead.
    canvas.save();
    canvas.clipPath(head);
    canvas.drawOval(const Rect.fromLTWH(62, 44, 60, 30),
        _paint(Colors.white.withValues(alpha: .10)));
    canvas.restore();
    if (look.hair == 0) {
      canvas.drawOval(const Rect.fromLTWH(78, 48, 26, 12),
          _paint(Colors.white.withValues(alpha: .22)));
    }
  }

  // ---- Face ---------------------------------------------------------------

  static const _eyeY = 104.0;
  static const _leftEye = Offset(76, _eyeY), _rightEye = Offset(124, _eyeY);

  Color get _browColor =>
      look.hair == 0 ? _darker(skin, .45) : _darker(hair, .1);

  void _face(Canvas canvas) {
    _cheeksUnder(canvas);
    _eyes(canvas);
    _brows(canvas);
    // Nose.
    canvas.drawPath(
        Path()
          ..moveTo(96, 120)
          ..quadraticBezierTo(100, 124, 104, 120),
        _stroke(_darker(skin, .25), 3));
    _facialHair(canvas);
    _mouth(canvas);
    _cheekStickers(canvas);
  }

  void _cheeksUnder(Canvas canvas) {
    if (look.cheeks == 1 || look.cheeks == 3) {
      for (final x in [64.0, 136.0]) {
        canvas.drawOval(
            Rect.fromCenter(center: Offset(x, 126), width: 24, height: 13),
            _paint(const Color(0xFFFF7A8A).withValues(alpha: .38)));
      }
    }
    if (look.cheeks == 2 || look.cheeks == 3) {
      final dot = _paint(_darker(skin, .32).withValues(alpha: .7));
      for (final side in [-1.0, 1.0]) {
        for (final o in const [
          Offset(-6, -3), Offset(1, -6), Offset(6, -1), Offset(-2, 3), //
          Offset(5, 5),
        ]) {
          canvas.drawCircle(
              Offset(100 + side * 36 + o.dx * side, 124 + o.dy), 1.5, dot);
        }
      }
    }
  }

  void _cheekStickers(Canvas canvas) {
    switch (look.cheeks) {
      case 4:
        for (final x in [62.0, 138.0]) {
          canvas.drawPath(
              _heart(Offset(x, 126), 6), _paint(const Color(0xFFFF5C8A)));
        }
      case 5:
        for (final x in [62.0, 138.0]) {
          canvas.drawPath(
              _star(Offset(x, 126), 7), _paint(const Color(0xFFFFC62E)));
        }
      case 6:
        canvas.save();
        canvas.translate(138, 128);
        canvas.rotate(-.5);
        final rect = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 26, height: 10),
            const Radius.circular(5));
        canvas.drawRRect(rect, _paint(const Color(0xFFF5D6B4)));
        canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: 9, height: 10),
            _paint(const Color(0xFFE9BE93)));
        canvas.restore();
    }
  }

  void _eyes(Canvas canvas) {
    final style = look.eyes;
    final closed = blink && style != 2;
    for (final center in [_leftEye, _rightEye]) {
      final right = center == _rightEye;
      if (closed || style == 2 || (style == 4 && right)) {
        _happyEye(canvas, center);
        continue;
      }
      switch (style) {
        case 1:
          _roundEye(canvas, center, big: true);
        case 3:
          _sleepyEye(canvas, center);
        case 5:
          canvas.drawPath(
              _star(center, 13, .48), _paint(const Color(0xFFFFC62E)));
          canvas.drawPath(
              _star(center, 13, .48), _stroke(const Color(0xFFE09A12), 1.6));
          canvas.drawCircle(
              center + const Offset(-3, -3), 2, _paint(Colors.white));
        case 6:
          canvas.drawPath(_heart(center, 11), _paint(const Color(0xFFFF4D7E)));
          canvas.drawCircle(center + const Offset(-4, -3), 2.2,
              _paint(Colors.white.withValues(alpha: .9)));
        case 7:
          canvas.drawOval(
              Rect.fromCenter(center: center, width: 11, height: 15),
              _paint(const Color(0xFF231A16)));
          canvas.drawCircle(
              center + const Offset(-2, -3), 2, _paint(Colors.white));
        case 8:
          _roundEye(canvas, center);
          final outer = right ? 1.0 : -1.0;
          for (var i = 0; i < 3; i++) {
            final a = -math.pi / 2 + outer * (.55 + i * .32);
            final from = center + Offset(math.cos(a) * 13, math.sin(a) * 15);
            canvas.drawLine(
                from,
                from + Offset(math.cos(a) * 6, math.sin(a) * 6),
                _stroke(const Color(0xFF231A16), 2.4));
          }
        default:
          _roundEye(canvas, center);
      }
    }
  }

  void _roundEye(Canvas canvas, Offset c, {bool big = false}) {
    final w = big ? 28.0 : 25.0, h = big ? 32.0 : 29.0;
    final white = Rect.fromCenter(center: c, width: w, height: h);
    canvas.drawOval(white, _paint(Colors.white));
    canvas.save();
    canvas.clipPath(Path()..addOval(white));
    final iris = big ? 12.5 : 10.0;
    final ic = c + const Offset(0, 3);
    canvas.drawCircle(
        ic,
        iris,
        Paint()
          ..shader = RadialGradient(colors: [
            _lighter(look.eyeColorValue, .25),
            look.eyeColorValue,
            _darker(look.eyeColorValue, .25),
          ], stops: const [
            0,
            .6,
            1
          ]).createShader(Rect.fromCircle(center: ic, radius: iris)));
    canvas.drawCircle(ic, iris * .48, _paint(const Color(0xFF1B1310)));
    canvas.restore();
    canvas.drawOval(white, _stroke(_darker(skin, .35), 2));
    canvas.drawCircle(
        c + const Offset(-4, -4), big ? 4 : 3.2, _paint(Colors.white));
    canvas.drawCircle(c + const Offset(4, 6), big ? 2.2 : 1.6,
        _paint(Colors.white.withValues(alpha: .9)));
    if (big) {
      canvas.drawPath(
          _star(c + const Offset(5, -5), 3.4, .4, 4), _paint(Colors.white));
    }
  }

  void _sleepyEye(Canvas canvas, Offset c) {
    final white =
        Rect.fromCenter(center: c + const Offset(0, 4), width: 25, height: 20);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(c.dx - 15, c.dy + 1, 30, 20));
    canvas.drawOval(white, _paint(Colors.white));
    canvas.drawCircle(c + const Offset(0, 6), 8, _paint(look.eyeColorValue));
    canvas.drawCircle(
        c + const Offset(0, 6), 4, _paint(const Color(0xFF1B1310)));
    canvas.restore();
    canvas.drawLine(c + const Offset(-14, 1), c + const Offset(14, 1),
        _stroke(_darker(skin, .45), 3.2));
  }

  void _happyEye(Canvas canvas, Offset c) {
    canvas.drawPath(
        Path()
          ..moveTo(c.dx - 11, c.dy + 4)
          ..quadraticBezierTo(c.dx, c.dy - 10, c.dx + 11, c.dy + 4),
        _stroke(const Color(0xFF2A1E19), 3.6));
  }

  void _brows(Canvas canvas) {
    if (look.brows == 0) return;
    final width = look.brows == 2 ? 6.5 : 4.2;
    final paint = _stroke(_browColor, width);
    for (final side in [-1.0, 1.0]) {
      final inner = Offset(100 + side * 12, 82);
      final outer = Offset(100 + side * 38, 82);
      double innerY = inner.dy, outerY = outer.dy, lift = -5;
      switch (look.brows) {
        case 3: // raised
          innerY -= 6;
          outerY -= 6;
          lift = -8;
        case 4: // fierce: inner ends down
          innerY += 5;
          outerY -= 3;
          lift = -1;
        case 5: // worried: inner ends up
          innerY -= 6;
          outerY += 3;
          lift = -2;
      }
      canvas.drawPath(
          Path()
            ..moveTo(inner.dx, innerY)
            ..quadraticBezierTo((inner.dx + outer.dx) / 2,
                (innerY + outerY) / 2 + lift, outer.dx, outerY),
          paint);
    }
  }

  void _mouth(Canvas canvas) {
    final lip = _darker(skin, .42);
    const inside = Color(0xFF7A2430);
    const tongue = Color(0xFFFF7A8A);
    switch (look.mouth) {
      case 1: // grin with teeth
        final open = Path()
          ..moveTo(84, 132)
          ..quadraticBezierTo(100, 154, 116, 132)
          ..close();
        canvas.drawPath(open, _paint(inside));
        canvas.save();
        canvas.clipPath(open);
        canvas.drawRect(
            const Rect.fromLTWH(80, 128, 40, 7), _paint(Colors.white));
        canvas.restore();
      case 2: // laugh
        final open = Path()
          ..moveTo(82, 130)
          ..quadraticBezierTo(100, 162, 118, 130)
          ..close();
        canvas.drawPath(open, _paint(inside));
        canvas.save();
        canvas.clipPath(open);
        canvas.drawOval(const Rect.fromLTWH(88, 140, 24, 16), _paint(tongue));
        canvas.restore();
      case 3: // smirk
        canvas.drawPath(
            Path()
              ..moveTo(88, 138)
              ..quadraticBezierTo(104, 142, 114, 130),
            _stroke(lip, 3.6));
      case 4: // cheeky tongue
        canvas.drawPath(
            Path()
              ..moveTo(98, 138)
              ..lineTo(98, 144)
              ..quadraticBezierTo(104, 154, 110, 144)
              ..lineTo(110, 138)
              ..close(),
            _paint(tongue));
        canvas.drawPath(
            Path()
              ..moveTo(86, 133)
              ..quadraticBezierTo(100, 144, 114, 133),
            _stroke(lip, 3.6));
      case 5: // kitty :3
        canvas.drawPath(
            Path()
              ..moveTo(88, 134)
              ..quadraticBezierTo(94, 142, 100, 134)
              ..quadraticBezierTo(106, 142, 112, 134),
            _stroke(lip, 3.2));
      case 6: // wow
        canvas.drawOval(const Rect.fromLTWH(93, 130, 14, 16), _paint(inside));
      case 7: // calm
        canvas.drawPath(
            Path()
              ..moveTo(91, 136)
              ..quadraticBezierTo(100, 140, 109, 136),
            _stroke(lip, 3.4));
      default: // smile
        canvas.drawPath(
            Path()
              ..moveTo(85, 132)
              ..quadraticBezierTo(100, 146, 115, 132),
            _stroke(lip, 3.8));
    }
  }

  void _facialHair(Canvas canvas) {
    final c = look.hair == 0 && look.hairColor == 8 ? _darker(skin, .4) : hair;
    switch (look.facialHair) {
      case 1: // stubble
        final dot = _paint(c.withValues(alpha: .45));
        final random = math.Random(7);
        for (var i = 0; i < 70; i++) {
          final a = math.pi * (.08 + .84 * random.nextDouble());
          final r = 44 + random.nextDouble() * 16;
          final p = Offset(100 + math.cos(a) * r * .95, 104 + math.sin(a) * r);
          if (p.dy > 120) canvas.drawCircle(p, 1.1, dot);
        }
      case 2: // moustache
        canvas.drawPath(
            Path()
              ..moveTo(100, 127)
              ..cubicTo(92, 120, 80, 122, 76, 132)
              ..cubicTo(86, 130, 94, 134, 100, 131)
              ..cubicTo(106, 134, 114, 130, 124, 132)
              ..cubicTo(120, 122, 108, 120, 100, 127)
              ..close(),
            _paint(c));
      case 3: // beard
        canvas.save();
        canvas.clipPath(_headPath);
        canvas.drawPath(
            Path()
              ..moveTo(40, 106)
              ..cubicTo(42, 148, 70, 174, 100, 174)
              ..cubicTo(130, 174, 158, 148, 160, 106)
              ..lineTo(151, 108)
              ..cubicTo(150, 132, 138, 146, 120, 148)
              ..quadraticBezierTo(100, 152, 80, 148)
              ..cubicTo(62, 146, 50, 132, 49, 108)
              ..close(),
            _paint(c));
        canvas.restore();
        canvas.drawPath(
            Path()
              ..moveTo(100, 127)
              ..cubicTo(90, 121, 80, 123, 77, 132)
              ..cubicTo(86, 130, 94, 133, 100, 131)
              ..cubicTo(106, 133, 114, 130, 123, 132)
              ..cubicTo(120, 123, 110, 121, 100, 127)
              ..close(),
            _paint(c));
      case 4: // goatee
        canvas.drawPath(
            Path()
              ..moveTo(90, 146)
              ..quadraticBezierTo(100, 162, 110, 146)
              ..quadraticBezierTo(100, 150, 90, 146)
              ..close(),
            _paint(c));
        canvas.drawPath(
            Path()
              ..moveTo(100, 127)
              ..cubicTo(92, 122, 84, 124, 82, 130)
              ..quadraticBezierTo(92, 128, 100, 130)
              ..quadraticBezierTo(108, 128, 118, 130)
              ..cubicTo(116, 124, 108, 122, 100, 127)
              ..close(),
            _paint(c));
    }
  }

  // ---- Hair ---------------------------------------------------------------

  /// The hair that sits on the head down to [forehead], with sideburns.
  Path _cap(double forehead, {double side = 110, double top = 28}) => Path()
    ..moveTo(39, side)
    ..cubicTo(30, 58, 62, top, 100, top)
    ..cubicTo(138, top, 170, 58, 161, side)
    ..cubicTo(156, side - 22, 152, forehead + 12, 140, forehead + 4)
    ..quadraticBezierTo(100, forehead - 10, 60, forehead + 4)
    ..cubicTo(48, forehead + 12, 44, side - 22, 39, side)
    ..close();

  void _hairFill(Canvas canvas, Path path, [Color? color]) {
    final c = color ?? hair;
    canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_lighter(c, .12), c, _darker(c, .08)])
              .createShader(path.getBounds()));
  }

  /// A glossy streak so hair reads as hair, not a helmet.
  void _shine(Canvas canvas, double y) {
    canvas.drawPath(
        Path()
          ..moveTo(70, y + 10)
          ..quadraticBezierTo(84, y, 102, y + 2),
        _stroke(Colors.white.withValues(alpha: .28), 4));
  }

  void _hairBehind(Canvas canvas) {
    final back = _darker(hair, .14);
    switch (look.hair) {
      case 6: // afro
        final cloud = Path();
        for (var i = 0; i < 14; i++) {
          final a = math.pi * 2 * i / 14;
          cloud.addOval(Rect.fromCircle(
              center: Offset(100 + math.cos(a) * 62, 92 + math.sin(a) * 58),
              radius: 24));
        }
        cloud.addOval(
            Rect.fromCircle(center: const Offset(100, 92), radius: 64));
        _hairFill(canvas, cloud);
      case 8: // space buns
        for (final x in [52.0, 148.0]) {
          canvas.drawCircle(Offset(x, 42), 22, _paint(back));
          canvas.drawCircle(Offset(x - 4, 36), 8,
              _paint(Colors.white.withValues(alpha: .18)));
        }
      case 9: // ponytail
        _hairFill(
            canvas,
            Path()
              ..moveTo(138, 56)
              ..cubicTo(196, 54, 192, 136, 170, 184)
              ..cubicTo(160, 160, 166, 110, 140, 92)
              ..close(),
            back);
      case 11: // bob
        canvas.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(33, 44, 134, 116),
                const Radius.circular(46)),
            _paint(back));
      case 18: // mullet
        _hairFill(
            canvas,
            Path()
              ..moveTo(46, 108)
              ..cubicTo(42, 150, 56, 178, 80, 190)
              ..lineTo(120, 190)
              ..cubicTo(144, 178, 158, 150, 154, 108)
              ..close(),
            back);
      case 12: // long
      case 13: // waves
      case 14: // braids
        canvas.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(36, 42, 128, 140),
                const Radius.circular(50)),
            _paint(back));
    }
  }

  void _hairOverShoulders(Canvas canvas) {
    switch (look.hair) {
      case 10: // pigtails
        for (final side in [-1.0, 1.0]) {
          final x = 100 + side * 56;
          _hairFill(
              canvas,
              Path()
                ..moveTo(x, 92)
                ..cubicTo(
                    x + side * 28, 110, x + side * 26, 170, x + side * 8, 196)
                ..cubicTo(
                    x - side * 4, 170, x - side * 2, 130, x - side * 4, 104)
                ..close());
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromCenter(
                      center: Offset(x + side * 4, 104), width: 16, height: 9),
                  const Radius.circular(4)),
              _paint(look.hatColorValue));
        }
      case 12: // long
      case 13: // waves
        final wavy = look.hair == 13;
        for (final side in [-1.0, 1.0]) {
          final x = 100 + side * 58;
          final path = Path()..moveTo(x, 86);
          if (wavy) {
            path
              ..cubicTo(
                  x + side * 16, 120, x - side * 2, 150, x + side * 12, 180)
              ..cubicTo(
                  x + side * 20, 200, x + side * 4, 214, x + side * 10, 226)
              ..quadraticBezierTo(x - side * 6, 228, x - side * 16, 218)
              ..cubicTo(
                  x - side * 10, 200, x - side * 22, 170, x - side * 10, 140)
              ..cubicTo(x - side * 4, 120, x - side * 6, 104, x - side * 4, 96);
          } else {
            path
              ..cubicTo(
                  x + side * 10, 140, x + side * 8, 190, x + side * 6, 222)
              ..quadraticBezierTo(x - side * 8, 228, x - side * 18, 220)
              ..cubicTo(
                  x - side * 14, 180, x - side * 8, 130, x - side * 6, 98);
          }
          _hairFill(canvas, path..close());
        }
      case 14: // braids
        for (final side in [-1.0, 1.0]) {
          for (var i = 0; i < 7; i++) {
            final c = Offset(100 + side * (54 + i * .8), 112 + i * 15.0);
            canvas.drawOval(Rect.fromCenter(center: c, width: 20, height: 19),
                _paint(i.isEven ? hair : _darker(hair, .1)));
            canvas.drawLine(c + Offset(-6 * side, -4), c + Offset(6 * side, 4),
                _stroke(_darker(hair, .25), 1.6));
          }
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromCenter(
                      center: Offset(100 + side * 60, 216),
                      width: 14,
                      height: 7),
                  const Radius.circular(3)),
              _paint(look.hatColorValue));
          canvas.drawPath(
              Path()
                ..moveTo(100 + side * 54, 220)
                ..lineTo(100 + side * 66, 220)
                ..lineTo(100 + side * 60, 234)
                ..close(),
              _paint(hair));
        }
    }
  }

  void _hairFront(Canvas canvas) {
    switch (look.hair) {
      case 0:
        return;
      case 1: // buzz
        canvas.drawPath(
            _cap(70, side: 96, top: 36), _paint(Color.lerp(skin, hair, .72)!));
      case 2: // crop
        _hairFill(canvas, _cap(64, side: 104));
        _shine(canvas, 38);
      case 3: // side part
        _hairFill(canvas, _cap(68));
        _hairFill(
            canvas,
            Path()
              ..moveTo(54, 80)
              ..cubicTo(56, 40, 104, 30, 136, 44)
              ..cubicTo(156, 54, 160, 76, 154, 96)
              ..cubicTo(146, 74, 118, 64, 86, 72)
              ..quadraticBezierTo(66, 76, 54, 80)
              ..close());
        canvas.drawPath(
            Path()
              ..moveTo(70, 40)
              ..quadraticBezierTo(76, 56, 74, 70),
            _stroke(_darker(hair, .25), 2.4));
        _shine(canvas, 40);
      case 4: // quiff
        _hairFill(canvas, _cap(68));
        _hairFill(
            canvas,
            Path()
              ..moveTo(56, 66)
              ..cubicTo(48, 22, 100, 2, 140, 16)
              ..cubicTo(166, 26, 160, 54, 146, 64)
              ..quadraticBezierTo(108, 42, 56, 66)
              ..close());
        canvas.drawPath(
            Path()
              ..moveTo(78, 34)
              ..quadraticBezierTo(104, 16, 136, 24),
            _stroke(Colors.white.withValues(alpha: .3), 4));
      case 5: // curls
        _hairFill(canvas, _cap(72));
        for (final c in const [
          Offset(56, 64), Offset(68, 44), Offset(88, 34), Offset(112, 34), //
          Offset(132, 44), Offset(144, 64), Offset(78, 62), Offset(100, 56),
          Offset(122, 62),
        ]) {
          canvas.drawCircle(c, 15, _paint(hair));
          canvas.drawCircle(c + const Offset(-4, -4), 5,
              _paint(Colors.white.withValues(alpha: .16)));
        }
      case 6: // afro front curls
        for (var i = 0; i < 7; i++) {
          final x = 56 + i * 14.7;
          canvas.drawCircle(
              Offset(x, 62 + (i == 0 || i == 6 ? 8 : 0)), 13, _paint(hair));
        }
      case 7: // top bun
        canvas.drawCircle(const Offset(100, 24), 22, _paint(hair));
        canvas.drawCircle(const Offset(94, 18), 7,
            _paint(Colors.white.withValues(alpha: .2)));
        _hairFill(canvas, _cap(64, side: 104));
        canvas.drawOval(
            const Rect.fromLTWH(86, 38, 28, 9), _paint(look.hatColorValue));
      case 8: // space buns
        _hairFill(canvas, _cap(66));
        canvas.drawLine(const Offset(100, 30), const Offset(100, 58),
            _stroke(_darker(hair, .25), 2.4));
      case 9: // ponytail
        _hairFill(canvas, _cap(64, side: 100));
        canvas.drawCircle(const Offset(146, 62), 7, _paint(look.hatColorValue));
        _shine(canvas, 38);
      case 10: // pigtails
      case 12: // long
      case 14: // braids
        _hairFill(canvas, _cap(66));
        canvas.drawPath(
            Path()
              ..moveTo(100, 30)
              ..quadraticBezierTo(98, 46, 100, 58),
            _stroke(_darker(hair, .3), 2.4));
        _shine(canvas, 38);
      case 11: // bob with a rounded fringe
        _hairFill(
            canvas,
            Path()
              ..moveTo(36, 126)
              ..cubicTo(28, 56, 62, 28, 100, 28)
              ..cubicTo(138, 28, 172, 56, 164, 126)
              ..quadraticBezierTo(158, 131, 152, 126)
              ..cubicTo(152, 106, 150, 92, 146, 82)
              ..quadraticBezierTo(124, 92, 100, 87)
              ..quadraticBezierTo(76, 92, 54, 82)
              ..cubicTo(50, 92, 48, 106, 48, 126)
              ..quadraticBezierTo(42, 131, 36, 126)
              ..close());
        _shine(canvas, 38);
      case 13: // waves, swept
        _hairFill(canvas, _cap(66));
        _hairFill(
            canvas,
            Path()
              ..moveTo(50, 92)
              ..cubicTo(50, 50, 96, 36, 120, 48)
              ..cubicTo(100, 52, 84, 62, 70, 74)
              ..quadraticBezierTo(60, 82, 50, 92)
              ..close());
        _shine(canvas, 38);
      case 15: // mohawk
        canvas.drawPath(
            _cap(70, side: 96, top: 36), _paint(Color.lerp(skin, hair, .38)!));
        _hairFill(
            canvas,
            Path()
              ..moveTo(82, 70)
              ..lineTo(76, 42)
              ..lineTo(90, 44)
              ..lineTo(86, 14)
              ..lineTo(99, 30)
              ..lineTo(102, -2)
              ..lineTo(110, 30)
              ..lineTo(120, 12)
              ..lineTo(116, 44)
              ..lineTo(126, 40)
              ..lineTo(118, 70)
              ..quadraticBezierTo(100, 64, 82, 70)
              ..close());
      case 16: // spiky
        final spikes = Path()..moveTo(42, 92);
        const tips = [
          Offset(36, 50), Offset(56, 54), Offset(54, 18), Offset(78, 38), //
          Offset(92, 6), Offset(106, 34), Offset(126, 8), Offset(132, 38),
          Offset(156, 22), Offset(150, 54), Offset(168, 54), Offset(158, 92),
        ];
        for (var i = 0; i < tips.length; i++) {
          spikes.lineTo(tips[i].dx, tips[i].dy);
        }
        spikes
          ..cubicTo(150, 72, 124, 64, 100, 68)
          ..cubicTo(76, 64, 50, 72, 42, 92)
          ..close();
        _hairFill(canvas, spikes);
      case 17: // curtains
        _hairFill(canvas, _cap(58));
        for (final side in [-1.0, 1.0]) {
          _hairFill(
              canvas,
              Path()
                ..moveTo(100, 40)
                ..cubicTo(100 - side * 22, 50, 100 - side * 40, 70,
                    100 - side * 44, 104)
                ..cubicTo(100 - side * 52, 86, 100 - side * 50, 62,
                    100 - side * 34, 46)
                ..close());
        }
      case 18: // mullet top
        _hairFill(canvas, _cap(64, side: 112));
        _shine(canvas, 38);
      case 19: // pixie
        _hairFill(canvas, _cap(70, side: 100));
        _hairFill(
            canvas,
            Path()
              ..moveTo(46, 86)
              ..cubicTo(66, 52, 116, 50, 146, 60)
              ..quadraticBezierTo(120, 74, 92, 80)
              ..quadraticBezierTo(66, 86, 46, 86)
              ..close());
        _shine(canvas, 40);
    }
  }

  // ---- Glasses ------------------------------------------------------------

  void _glasses(Canvas canvas) {
    final style = look.glasses;
    if (style == 0) return;
    final c = look.glassesColorValue;
    final frame = _stroke(c, style == 7 ? 6.5 : 4);
    final tint = Paint()..color = c.withValues(alpha: .18);
    Path lens(Offset center) {
      switch (style) {
        case 1:
          return Path()..addOval(Rect.fromCircle(center: center, radius: 17));
        case 3: // cat-eye
          final outer = center.dx < 100 ? -1.0 : 1.0;
          return Path()
            ..moveTo(center.dx - 17 * outer, center.dy - 4)
            ..quadraticBezierTo(center.dx, center.dy - 14,
                center.dx + 20 * outer, center.dy - 14)
            ..quadraticBezierTo(center.dx + 18 * outer, center.dy + 14,
                center.dx, center.dy + 14)
            ..quadraticBezierTo(center.dx - 18 * outer, center.dy + 12,
                center.dx - 17 * outer, center.dy - 4)
            ..close();
        case 4: // shades
          return Path()
            ..addRRect(RRect.fromRectAndCorners(
                Rect.fromCenter(center: center, width: 38, height: 26),
                topLeft: const Radius.circular(6),
                topRight: const Radius.circular(6),
                bottomLeft: const Radius.circular(16),
                bottomRight: const Radius.circular(16)));
        case 5:
          return _star(center, 21, .52);
        case 6:
          return _heart(center + const Offset(0, -2), 17);
        default: // square and nerdy
          return Path()
            ..addRRect(RRect.fromRectAndRadius(
                Rect.fromCenter(center: center, width: 38, height: 30),
                const Radius.circular(7)));
      }
    }

    final dark = style == 4;
    final fun = style == 5 || style == 6;
    for (final center in [_leftEye, _rightEye]) {
      final path = lens(center);
      canvas.drawPath(
          path,
          dark
              ? _paint(const Color(0xFF1E1A2E).withValues(alpha: .92))
              : fun
                  ? _paint(c.withValues(alpha: .75))
                  : tint);
      if (dark || fun) {
        canvas.drawLine(
            center + const Offset(-10, -4),
            center + const Offset(-2, -10),
            _stroke(Colors.white.withValues(alpha: .5), 3));
      }
      canvas.drawPath(path, frame);
    }
    final bridgeY = _eyeY - (style == 3 ? 6 : 2);
    canvas.drawPath(
        Path()
          ..moveTo(_leftEye.dx + 17, bridgeY)
          ..quadraticBezierTo(100, bridgeY - 6, _rightEye.dx - 17, bridgeY),
        frame);
    canvas.drawLine(Offset(_leftEye.dx - 18, _eyeY - 4),
        Offset(_earX + 2, _eyeY - 8), frame);
    canvas.drawLine(Offset(_rightEye.dx + 18, _eyeY - 4),
        Offset(200 - _earX - 2, _eyeY - 8), frame);
  }

  // ---- Headwear -----------------------------------------------------------

  void _hat(Canvas canvas) {
    final c = look.hatColorValue;
    final dark = _darker(c, .2);
    final light = _lighter(c, .3);
    const gold = Color(0xFFF2C94C);
    switch (look.hat) {
      case 1: // beanie
        canvas.drawPath(
            Path()
              ..moveTo(38, 80)
              ..cubicTo(34, 30, 70, 16, 100, 16)
              ..cubicTo(130, 16, 166, 30, 162, 80)
              ..close(),
            _paint(c));
        for (var x = 52.0; x < 150; x += 12) {
          canvas.drawLine(Offset(x, 30), Offset(x, 72),
              _stroke(dark.withValues(alpha: .35), 2));
        }
        canvas.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(34, 66, 132, 22),
                const Radius.circular(10)),
            _paint(dark));
        canvas.drawCircle(const Offset(100, 14), 13, _paint(light));
      case 2: // cap
      case 3: // backwards cap
        canvas.drawPath(
            Path()
              ..moveTo(40, 80)
              ..cubicTo(36, 32, 70, 22, 100, 22)
              ..cubicTo(130, 22, 164, 32, 160, 80)
              ..close(),
            _paint(c));
        canvas.drawLine(const Offset(100, 24), const Offset(100, 78),
            _stroke(dark.withValues(alpha: .4), 2));
        canvas.drawCircle(const Offset(100, 24), 5, _paint(dark));
        if (look.hat == 2) {
          canvas.drawPath(
              Path()
                ..moveTo(36, 80)
                ..quadraticBezierTo(100, 66, 164, 80)
                ..quadraticBezierTo(172, 92, 160, 94)
                ..quadraticBezierTo(100, 84, 40, 94)
                ..quadraticBezierTo(28, 92, 36, 80)
                ..close(),
              _paint(dark));
        } else {
          canvas.drawPath(
              Path()
                ..moveTo(84, 80)
                ..quadraticBezierTo(100, 58, 116, 80)
                ..close(),
              _paint(skin));
          canvas.drawPath(
              Path()
                ..moveTo(84, 80)
                ..quadraticBezierTo(100, 58, 116, 80),
              _stroke(dark, 3));
          canvas.drawRRect(
              RRect.fromRectAndRadius(const Rect.fromLTWH(38, 76, 124, 8),
                  const Radius.circular(4)),
              _paint(dark));
        }
      case 4: // bucket hat
        canvas.drawPath(
            Path()
              ..moveTo(50, 72)
              ..cubicTo(48, 30, 72, 22, 100, 22)
              ..cubicTo(128, 22, 152, 30, 150, 72)
              ..close(),
            _paint(c));
        canvas.drawPath(
            Path()
              ..moveTo(50, 68)
              ..lineTo(150, 68)
              ..lineTo(170, 92)
              ..quadraticBezierTo(100, 80, 30, 92)
              ..close(),
            _paint(dark));
        canvas.drawLine(
            const Offset(52, 64), const Offset(148, 64), _stroke(light, 3));
      case 5: // beret
        canvas.save();
        canvas.translate(92, 44);
        canvas.rotate(-.18);
        canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: 120, height: 44),
            _paint(c));
        canvas.drawOval(
            Rect.fromCenter(center: const Offset(0, 14), width: 96, height: 16),
            _paint(dark));
        canvas.drawLine(
            const Offset(0, -22), const Offset(4, -30), _stroke(dark, 4));
        canvas.restore();
      case 6: // šajkača, the Serbian folk cap
        final cap = Path()
          ..moveTo(40, 86)
          ..lineTo(44, 54)
          ..quadraticBezierTo(46, 40, 62, 38)
          ..lineTo(91, 37)
          ..lineTo(100, 47)
          ..lineTo(109, 37)
          ..lineTo(138, 38)
          ..quadraticBezierTo(154, 40, 156, 54)
          ..lineTo(160, 86)
          ..quadraticBezierTo(100, 76, 40, 86)
          ..close();
        canvas.drawPath(cap, _paint(c));
        // The crease running front to back, and the folded edge.
        canvas.drawPath(
            Path()
              ..moveTo(100, 44)
              ..quadraticBezierTo(98, 58, 100, 78),
            _stroke(dark, 3));
        canvas.drawPath(
            Path()
              ..moveTo(44, 70)
              ..quadraticBezierTo(100, 60, 156, 70),
            _stroke(dark.withValues(alpha: .7), 2.5));
        canvas.drawPath(
            Path()
              ..moveTo(58, 42)
              ..quadraticBezierTo(76, 34, 90, 40),
            _stroke(light.withValues(alpha: .6), 3));
      case 7: // crown
        final crown = Path()
          ..moveTo(56, 70)
          ..lineTo(52, 30)
          ..lineTo(74, 48)
          ..lineTo(88, 20)
          ..lineTo(100, 42)
          ..lineTo(112, 20)
          ..lineTo(126, 48)
          ..lineTo(148, 30)
          ..lineTo(144, 70)
          ..close();
        canvas.drawPath(crown, _paint(gold));
        canvas.drawPath(crown, _stroke(const Color(0xFFD9A92E), 2));
        canvas.drawRect(const Rect.fromLTWH(56, 60, 88, 10),
            _paint(const Color(0xFFE0B13C)));
        for (final x in [72.0, 100.0, 128.0]) {
          canvas.drawCircle(Offset(x, 65), 4.4, _paint(c));
        }
        for (final p in const [
          Offset(52, 30), Offset(88, 20), Offset(112, 20), Offset(148, 30), //
        ]) {
          canvas.drawCircle(p, 4, _paint(gold));
        }
      case 8: // flower crown
        for (var i = 0; i < 9; i++) {
          final t = i / 8;
          final a = math.pi * (1.08 + .84 * t);
          final p = Offset(100 + math.cos(a) * 60, 98 + math.sin(a) * 44);
          if (i.isOdd) {
            canvas.drawOval(
                Rect.fromCenter(
                    center: p + const Offset(0, 6), width: 14, height: 8),
                _paint(const Color(0xFF5EBE6A)));
          }
          final petal = i % 3 == 0
              ? c
              : i % 3 == 1
                  ? Colors.white
                  : light;
          for (var k = 0; k < 5; k++) {
            final b = k * math.pi * 2 / 5;
            canvas.drawCircle(p + Offset(math.cos(b) * 5, math.sin(b) * 5), 4.4,
                _paint(petal));
          }
          canvas.drawCircle(p, 3.4, _paint(gold));
        }
      case 9: // headphones
        canvas.drawPath(
            Path()
              ..moveTo(40, 104)
              ..cubicTo(30, 30, 170, 30, 160, 104),
            _stroke(dark, 9));
        for (final x in [38.0, 162.0]) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromCenter(
                      center: Offset(x, 112), width: 24, height: 38),
                  const Radius.circular(12)),
              _paint(c));
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromCenter(
                      center: Offset(x, 112), width: 12, height: 26),
                  const Radius.circular(6)),
              _paint(light));
        }
      case 10: // big bow
        canvas.save();
        canvas.translate(132, 46);
        canvas.rotate(.3);
        for (final side in [-1.0, 1.0]) {
          canvas.drawPath(
              Path()
                ..moveTo(0, 0)
                ..cubicTo(side * 20, -24, side * 34, -8, side * 30, 4)
                ..cubicTo(side * 30, 18, side * 14, 14, 0, 0)
                ..close(),
              _paint(c));
        }
        canvas.drawCircle(Offset.zero, 7, _paint(dark));
        canvas.restore();
      case 11: // headband
        canvas.drawPath(
            Path()
              ..moveTo(42, 84)
              ..cubicTo(44, 34, 156, 34, 158, 84),
            _stroke(c, 10));
        canvas.drawPath(
            Path()
              ..moveTo(48, 70)
              ..cubicTo(56, 42, 144, 42, 152, 70),
            _stroke(light.withValues(alpha: .6), 2.5));
      case 12: // party hat
        canvas.save();
        canvas.translate(112, 40);
        canvas.rotate(.25);
        final cone = Path()
          ..moveTo(-28, 16)
          ..lineTo(0, -46)
          ..lineTo(28, 16)
          ..close();
        canvas.drawPath(cone, _paint(c));
        canvas.save();
        canvas.clipPath(cone);
        for (var y = -40.0; y < 20; y += 14) {
          canvas.drawRect(Rect.fromLTWH(-30, y, 60, 6), _paint(light));
        }
        canvas.restore();
        canvas.drawCircle(const Offset(0, -48), 7, _paint(gold));
        canvas.restore();
      case 13: // cat ears
      case 14: // bunny ears
        final bunny = look.hat == 14;
        for (final side in [-1.0, 1.0]) {
          final base = Offset(100 + side * 36, 46);
          if (bunny) {
            canvas.save();
            canvas.translate(base.dx, base.dy);
            canvas.rotate(side * .18);
            canvas.drawRRect(
                RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -64, 24, 70),
                    const Radius.circular(12)),
                _paint(c));
            canvas.drawRRect(
                RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -54, 12, 52),
                    const Radius.circular(6)),
                _paint(const Color(0xFFFFB3C6)));
            canvas.restore();
          } else {
            canvas.drawPath(
                Path()
                  ..moveTo(base.dx - side * 18, base.dy + 8)
                  ..lineTo(base.dx + side * 10, base.dy - 34)
                  ..lineTo(base.dx + side * 20, base.dy + 12)
                  ..close(),
                _paint(c));
            canvas.drawPath(
                Path()
                  ..moveTo(base.dx - side * 8, base.dy + 6)
                  ..lineTo(base.dx + side * 9, base.dy - 20)
                  ..lineTo(base.dx + side * 14, base.dy + 8)
                  ..close(),
                _paint(const Color(0xFFFFB3C6)));
          }
        }
        canvas.drawPath(
            Path()
              ..moveTo(44, 80)
              ..cubicTo(46, 34, 154, 34, 156, 80),
            _stroke(dark, 6));
      case 15: // wizard hat
        canvas.drawPath(
            Path()
              ..moveTo(52, 72)
              ..cubicTo(74, 50, 86, 10, 98, -14)
              ..quadraticBezierTo(116, -22, 130, -8)
              ..quadraticBezierTo(112, -6, 108, 4)
              ..cubicTo(116, 30, 130, 54, 150, 72)
              ..close(),
            _paint(c));
        canvas.drawOval(const Rect.fromLTWH(28, 62, 144, 24), _paint(dark));
        final star = c.computeLuminance() > .55 ? dark : gold;
        for (final p in const [
          Offset(88, 46),
          Offset(114, 52),
          Offset(100, 20)
        ]) {
          canvas.drawPath(_star(p, 6), _paint(star));
        }
    }
  }

  @override
  bool shouldRepaint(covariant _PortraitPainter old) =>
      old.look != look || old.headOnly != headOnly || old.blink != blink;
}
