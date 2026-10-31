import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'learner_look.dart';

/// Flat vector bust. Pieces are drawn here so every color and style can combine.
class LearnerPortrait extends StatelessWidget {
  final LearnerLook look;
  final bool headOnly;
  const LearnerPortrait({super.key, required this.look, this.headOnly = false});

  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _PortraitPainter(look, headOnly),
      child: const SizedBox.expand());
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
          border: Border.all(color: Colors.white.withValues(alpha: .2), width: 2)),
      clipBehavior: Clip.antiAlias,
      child: ColoredBox(
          color: look.backgroundColor,
          child: LearnerPortrait(look: look, headOnly: true)));
}

class _PortraitPainter extends CustomPainter {
  final LearnerLook look;
  final bool headOnly;
  _PortraitPainter(this.look, this.headOnly);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (headOnly) {
      final scale = math.min(size.width / 150, size.height / 150);
      canvas.translate(size.width / 2, size.height / 2 + size.height * .06);
      canvas.scale(scale);
      canvas.translate(-100, -108);
    } else {
      final scale = math.min(size.width / 200, size.height / 240);
      canvas.translate(
          (size.width - 200 * scale) / 2, (size.height - 240 * scale) / 2);
      canvas.scale(scale);
    }
    _bust(canvas);
    canvas.restore();
  }

  void _bust(Canvas canvas) {
    final skin = look.skinColor;
    final hair = look.hairColorValue;
    if (look.hair == 5) _bobBack(canvas, hair);
    _shoulders(canvas);
    _neck(canvas, skin);
    _ears(canvas, skin);
    _head(canvas, skin);
    _face(canvas, skin, hair);
    if (look.hair != 5 && look.hair != 7) _hair(canvas, hair);
    if (look.hair == 5) _bangs(canvas, hair);
    _glasses(canvas);
    _hat(canvas);
  }

  void _fill(Canvas canvas, Color color, Path path) =>
      canvas.drawPath(path, Paint()..color = color);

  void _shoulders(Canvas canvas) {
    const shapes = [
      [74.0, 176.0],
      [92.0, 166.0],
      [110.0, 158.0],
      [132.0, 148.0],
    ];
    final half = shapes[look.body][0];
    final top = shapes[look.body][1];
    final shirt = look.shirtColor;
    final path = Path()
      ..moveTo(100 - half, 240)
      ..lineTo(100 - half, top + 36)
      ..quadraticBezierTo(100 - half, top, 100, top + 6)
      ..quadraticBezierTo(100 + half, top, 100 + half, top + 36)
      ..lineTo(100 + half, 240)
      ..close();
    _fill(canvas, shirt, path);
    _fill(
        canvas,
        Color.lerp(shirt, Colors.black, .14)!,
        Path()
          ..moveTo(100 - half * .35, top + 18)
          ..quadraticBezierTo(100, top + 34, 100 + half * .35, top + 18)
          ..lineTo(100 + half * .2, 240)
          ..lineTo(100 - half * .2, 240)
          ..close());
  }

  void _neck(Canvas canvas, Color skin) {
    const shapes = [28.0, 32.0, 30.0, 38.0];
    final width = shapes[look.body];
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: const Offset(100, 158), width: width, height: 52),
            const Radius.circular(14)),
        Paint()..color = skin);
  }

  void _ears(Canvas canvas, Color skin) {
    final shade = Color.lerp(skin, Colors.black, .16)!;
    for (final center in const [Offset(48, 112), Offset(152, 112)]) {
      canvas.drawOval(
          Rect.fromCenter(center: center, width: 24, height: 32),
          Paint()..color = skin);
      canvas.drawOval(
          Rect.fromCenter(center: center, width: 10, height: 16),
          Paint()..color = shade);
    }
  }

  void _head(Canvas canvas, Color skin) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(46, 44, 108, 118), const Radius.circular(48)),
        Paint()..color = skin);
  }

  void _face(Canvas canvas, Color skin, Color hair) {
    final shade = Color.lerp(skin, const Color(0xFF5A3030), .28)!;
    final brow = look.hair == 7 ? Color.lerp(skin, Colors.black, .4)! : hair;
    final closed = look.expression == 2;
    if (!closed) {
      final tall = look.expression == 3 ? 34.0 : look.expression == 1 ? 22.0 : 30.0;
      _eye(canvas, const Offset(78, 98), tall);
      _eye(canvas, const Offset(122, 98), tall);
    } else {
      _closedEye(canvas, 66, brow);
      _closedEye(canvas, 108, brow);
    }
    final stroke = Paint()
      ..color = brow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
        Path()
          ..moveTo(64, 80)
          ..quadraticBezierTo(76, look.expression == 3 ? 74 : 72, 90, 78),
        stroke);
    canvas.drawPath(
        Path()
          ..moveTo(110, 78)
          ..quadraticBezierTo(124, look.expression == 3 ? 74 : 72, 136, 80),
        stroke);
    canvas.drawOval(const Rect.fromLTWH(94, 108, 12, 14),
        Paint()..color = Color.lerp(skin, Colors.black, .12)!);
    final mouth = Paint()
      ..color = shade
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    if (look.expression == 3) {
      canvas.drawOval(
          const Rect.fromLTWH(92, 124, 16, 14), Paint()..color = shade);
    } else if (closed || look.expression == 0) {
      canvas.drawPath(
          Path()
            ..moveTo(82, 126)
            ..quadraticBezierTo(100, 142, 118, 126),
          mouth);
    } else {
      canvas.drawPath(
          Path()
            ..moveTo(86, 128)
            ..quadraticBezierTo(100, 136, 114, 128),
          mouth);
    }
  }

  void _eye(Canvas canvas, Offset center, double height) {
    canvas.drawOval(
        Rect.fromCenter(center: center, width: 28, height: height),
        Paint()..color = Colors.white);
    canvas.drawCircle(
        center + const Offset(0, 2), 7, Paint()..color = look.eyeColor);
    canvas.drawCircle(center + const Offset(0, 3), 3.4, Paint()..color = const Color(0xFF1C140F));
    canvas.drawCircle(
        center + const Offset(-3, -2), 2.2, Paint()..color = Colors.white);
  }

  void _closedEye(Canvas canvas, double x, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
        Path()
          ..moveTo(x, 100)
          ..quadraticBezierTo(x + 14, 88, x + 28, 100),
        paint);
  }

  void _hair(Canvas canvas, Color color) {
    switch (look.hair) {
      case 1:
        _cap(canvas, color, 70);
        _fill(
            canvas,
            color,
            Path()
              ..moveTo(58, 78)
              ..quadraticBezierTo(48, 52, 78, 46)
              ..quadraticBezierTo(70, 70, 64, 84)
              ..close());
      case 2:
        for (final spot in const [
          Offset(72, 52),
          Offset(96, 40),
          Offset(122, 40),
          Offset(142, 56),
          Offset(108, 58),
        ]) {
          canvas.drawCircle(spot, 16, Paint()..color = color);
        }
      case 3:
        _cap(canvas, color, 72);
        if (look.hat == 0) {
          canvas.drawCircle(const Offset(118, 36), 18, Paint()..color = color);
        }
      case 4:
        _fill(
            canvas,
            color,
            Path()
              ..moveTo(52, 96)
              ..cubicTo(40, 40, 78, 18, 118, 28)
              ..cubicTo(150, 18, 168, 48, 150, 78)
              ..cubicTo(132, 60, 112, 66, 100, 74)
              ..cubicTo(84, 62, 66, 70, 52, 96)
              ..close());
      case 6:
        _cap(canvas, color, 58);
      default:
        _cap(canvas, color, 74);
    }
  }

  void _cap(Canvas canvas, Color color, double forehead) {
    _fill(
        canvas,
        color,
        Path()
          ..moveTo(50, forehead + 16)
          ..cubicTo(44, 40, 70, 26, 100, 28)
          ..cubicTo(134, 24, 160, 44, 152, forehead + 12)
          ..cubicTo(136, forehead - 8, 118, forehead - 4, 100, forehead)
          ..cubicTo(80, forehead - 6, 62, forehead, 50, forehead + 16)
          ..close());
  }

  void _bobBack(Canvas canvas, Color color) {
    _fill(
        canvas,
        color,
        Path()
          ..moveTo(42, 90)
          ..lineTo(34, 196)
          ..quadraticBezierTo(52, 210, 74, 190)
          ..lineTo(66, 96)
          ..close());
    _fill(
        canvas,
        color,
        Path()
          ..moveTo(158, 90)
          ..lineTo(166, 196)
          ..quadraticBezierTo(148, 210, 126, 190)
          ..lineTo(134, 96)
          ..close());
  }

  void _bangs(Canvas canvas, Color color) => _cap(canvas, color, 78);

  void _glasses(Canvas canvas) {
    if (look.glasses == 0) return;
    final paint = Paint()
      ..color = look.glassesColorValue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    final radius = look.glasses == 1 ? 16.0 : 6.0;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(58, 82, 38, 32), Radius.circular(radius)),
        paint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(104, 82, 38, 32), Radius.circular(radius)),
        paint);
    canvas.drawLine(const Offset(96, 98), const Offset(104, 98), paint);
    canvas.drawLine(const Offset(58, 94), const Offset(46, 90), paint);
    canvas.drawLine(const Offset(142, 94), const Offset(156, 90), paint);
  }

  void _hat(Canvas canvas) {
    if (look.hat == 0) return;
    final color = look.hatColorValue;
    final band = Color.lerp(color, Colors.black, .2)!;
    if (look.hat == 1) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(62, 30, 76, 42), const Radius.circular(16)),
          Paint()..color = color);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(46, 62, 108, 14), const Radius.circular(7)),
          Paint()..color = band);
      canvas.drawCircle(const Offset(100, 36), 4, Paint()..color = band);
      return;
    }
    canvas.drawOval(const Rect.fromLTWH(50, 18, 100, 72), Paint()..color = color);
    canvas.drawRect(const Rect.fromLTWH(50, 48, 100, 36), Paint()..color = color);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(48, 70, 104, 14), const Radius.circular(6)),
        Paint()..color = band);
  }

  @override
  bool shouldRepaint(covariant _PortraitPainter old) =>
      old.look != look || old.headOnly != headOnly;
}
