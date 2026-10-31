import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An articulated, resolution-independent character, based on Kristina's reference.
class AnimatedKristina extends StatefulWidget {
  final double width, height;
  final String mood;
  final int character;
  const AnimatedKristina(
      {super.key,
      this.width = 150,
      this.height = 220,
      this.mood = 'idle',
      this.character = 0});
  @override
  State<AnimatedKristina> createState() => _AnimatedKristinaState();
}

class _AnimatedKristinaState extends State<AnimatedKristina>
    with TickerProviderStateMixin {
  late final AnimationController idle = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 5200))
    ..repeat();
  late final AnimationController reaction = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1150))
    ..forward();
  @override
  void didUpdateWidget(covariant AnimatedKristina oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) reaction.forward(from: 0);
  }

  @override
  void dispose() {
    idle.dispose();
    reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
        label: [
          'Kristina, your Serbian tutor',
          'Miloš, your practice friend',
          'Zara, your practice friend'
        ][widget.character % 3],
        image: true,
        child: RepaintBoundary(
            child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: AnimatedBuilder(
                    animation: Listenable.merge([idle, reaction]),
                    builder: (_, __) => CustomPaint(
                        painter: _KristinaPainter(
                            reduced ? .3 : idle.value,
                            reduced ? 1 : reaction.value,
                            widget.mood,
                            widget.character))))));
  }
}

class _KristinaPainter extends CustomPainter {
  final double time, reaction;
  final String mood;
  final int character;
  _KristinaPainter(this.time, this.reaction, this.mood, this.character);
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
    final scale = math.min(size.width / 200, size.height / 300);
    canvas.translate(
        (size.width - 200 * scale) / 2, (size.height - 300 * scale) / 2);
    canvas.scale(scale);
    final celebrate = mood == 'correct' ||
        mood == 'celebrate' ||
        mood == 'happy' ||
        mood == 'hot';
    final wrong = mood == 'wrong';
    final pulse = math.sin(reaction * math.pi);
    final breath = math.sin(time * math.pi * 2);
    final jump = celebrate
        ? (mood == 'hot' ? -24 : -14) *
            math.sin(reaction * math.pi * 2).abs() *
            (1 - reaction)
        : 0.0;
    oval(
        canvas,
        Rect.fromCenter(center: const Offset(100, 287), width: 96, height: 12),
        const Color(0x18000000));
    canvas.save();
    canvas.translate(0, jump);
    // Hair behind body, separated from head so it swings subtly.
    if (character != 1) {
      canvas.save();
      canvas.translate(90, 100);
      canvas.rotate(.025 * breath);
      canvas.translate(-90, -100);
      fill(
          canvas,
          hair,
          (p) => canvas.drawPath(
              Path()
                ..moveTo(62, 52)
                ..cubicTo(34, 58, 16, 96, 24, 146)
                ..cubicTo(30, 178, 52, 190, 74, 172)
                ..cubicTo(88, 160, 84, 118, 74, 78)
                ..cubicTo(70, 64, 66, 56, 62, 52)
                ..close(),
              p));
      canvas.restore();
    }
    // Legs and shoes.
    stroke(
        canvas,
        Path()
          ..moveTo(82, 201)
          ..lineTo(74, 264),
        jeans,
        27);
    stroke(
        canvas,
        Path()
          ..moveTo(119, 201)
          ..lineTo(126, 264),
        const Color(0xFF2865B0),
        27);
    round(canvas, const Rect.fromLTWH(59, 258, 20, 19), 7, skin);
    round(canvas, const Rect.fromLTWH(119, 258, 20, 19), 7, skin);
    round(canvas, const Rect.fromLTWH(43, 271, 43, 15), 7,
        const Color(0xFFFFF4DF));
    round(canvas, const Rect.fromLTWH(117, 271, 43, 15), 7,
        const Color(0xFFFFF4DF));
    stroke(
        canvas,
        Path()
          ..moveTo(62, 274)
          ..lineTo(73, 274)
          ..moveTo(133, 274)
          ..lineTo(143, 274),
        const Color(0xFFE2D5BD),
        3);
    // Independently articulated arms. Positive reaction raises both hands.
    void arm(double x, double angle, bool left) {
      canvas.save();
      canvas.translate(x, 151 + breath);
      canvas.rotate(angle);
      stroke(
          canvas,
          Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(left ? -13 : 13, 23, 0, 43),
          shirt,
          22);
      oval(canvas, const Rect.fromLTWH(-10, 34, 21, 25), skin);
      stroke(
          canvas,
          Path()
            ..moveTo(3, 45)
            ..lineTo(8, 37),
          const Color(0xFFE99A7C),
          2);
      canvas.restore();
    }

    arm(
        65,
        celebrate
            ? .9 + pulse * .9
            : wrong
                ? -.45
                : -.22 + breath * .05,
        true);
    arm(
        136,
        celebrate
            ? -.9 - pulse * .9
            : wrong
                ? .5
                : -2.1 + math.sin(time * math.pi * 4) * .14,
        false);
    // Magenta turtleneck.
    round(canvas, Rect.fromLTWH(61, 133 + breath, 79, 79), 20, shirt);
    round(canvas, Rect.fromLTWH(82, 120 + breath, 40, 28), 9,
        Color.lerp(shirt, Colors.black, .12)!);
    // Head pivots, rather than translating a flat picture.
    canvas.save();
    canvas.translate(102, 93 + breath);
    canvas.rotate(wrong ? -.1 : .025 * breath + (celebrate ? .04 * pulse : 0));
    canvas.translate(-102, -93);
    oval(canvas, const Rect.fromLTWH(29, 72, 30, 30), skin);
    oval(canvas, const Rect.fromLTWH(143, 72, 29, 30), skin);
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
    } else {
      // Tall sweep on the left, a lower rounded section on the right,
      // and a dip between them. The dip stays above the skull.
      fill(
          canvas,
          hair,
          (p) => canvas.drawPath(
              Path()
                ..moveTo(54, 76)
                ..cubicTo(20, 52, 18, 8, 58, 4)
                ..cubicTo(88, 1, 108, 14, 116, 24)
                ..cubicTo(126, 16, 154, 18, 168, 36)
                ..cubicTo(178, 50, 170, 68, 154, 72)
                ..cubicTo(138, 64, 116, 58, 98, 58)
                ..cubicTo(78, 58, 64, 66, 54, 76)
                ..close(),
              p));
    }
    if (character == 1) {
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
    }
    // Eyelids blink twice per idle cycle; eyes track gently.
    final blink = (time > .72 && time < .75) || (time > .79 && time < .805);
    final eyeHeight = blink
        ? 3.0
        : wrong
            ? 24.0
            : 33.0;
    oval(
        canvas,
        Rect.fromCenter(
            center: const Offset(81, 81), width: 25, height: eyeHeight),
        Colors.white);
    oval(
        canvas,
        Rect.fromCenter(
            center: const Offset(119, 81), width: 25, height: eyeHeight),
        Colors.white);
    if (!blink) {
      final look = math.sin(time * math.pi * 2) * 1.5;
      oval(canvas, Rect.fromLTWH(81 + look, 70, 12, 22),
          const Color(0xFF82400F));
      oval(canvas, Rect.fromLTWH(119 + look, 70, 12, 22),
          const Color(0xFF82400F));
      oval(canvas, Rect.fromLTWH(82 + look, 70, 5, 7), Colors.white);
      oval(canvas, Rect.fromLTWH(120 + look, 70, 5, 7), Colors.white);
    }
    if (character == 2) {
      final glasses = Paint()
        ..color = const Color(0xFF7455C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(64, 62, 33, 38), const Radius.circular(12)),
          glasses);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(102, 62, 33, 38), const Radius.circular(12)),
          glasses);
      canvas.drawLine(const Offset(97, 78), const Offset(102, 78), glasses);
    }
    stroke(
        canvas,
        Path()
          ..moveTo(69, 59)
          ..quadraticBezierTo(78, wrong ? 53 : 49, 88, 55),
        hair,
        5);
    stroke(
        canvas,
        Path()
          ..moveTo(108, 54)
          ..quadraticBezierTo(119, wrong ? 42 : 48, 130, 54),
        hair,
        5);
    oval(canvas, const Rect.fromLTWH(95, 88, 12, 15), const Color(0xFFED9674));
    for (final point in [
      const Offset(65, 98),
      const Offset(74, 103),
      const Offset(62, 107),
      const Offset(132, 99),
      const Offset(139, 104),
      const Offset(130, 108)
    ]) {
      oval(canvas, Rect.fromCircle(center: point, radius: 2.4),
          const Color(0xFFD78C71));
    }
    if (mood == 'speaking') {
      round(
          canvas,
          Rect.fromCenter(
              center: const Offset(101, 113),
              width: 20,
              height: 5 + math.sin(time * math.pi * 24).abs() * 11),
          7,
          const Color(0xFF843F37));
    } else if (celebrate) {
      round(canvas, const Rect.fromLTWH(87, 108, 29, 15), 8,
          const Color(0xFF843F37));
      round(canvas, const Rect.fromLTWH(91, 108, 21, 5), 2, Colors.white);
    } else {
      stroke(
          canvas,
          Path()
            ..moveTo(87, 110)
            ..quadraticBezierTo(99, wrong ? 104 : 123, 113, 110),
          const Color(0xFFD77D59),
          5);
    }
    canvas.restore();
    canvas.restore();
    // A short celebratory burst, only on answer feedback.
    if (celebrate && reaction < .95) {
      final particles = mood == 'hot' ? 14 : 9;
      for (int i = 0; i < particles; i++) {
        final angle = i * math.pi * 2 / particles;
        final radius = 45 + reaction * 55;
        final pos = Offset(
            100 + math.cos(angle) * radius, 105 + math.sin(angle) * radius);
        oval(
            canvas,
            Rect.fromCenter(center: pos, width: 5, height: 9),
            [
              const Color(0xFFFFC84A),
              const Color(0xFF58CC02),
              const Color(0xFF55C8F5)
            ][i % 3]
                .withValues(alpha: 1 - reaction));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KristinaPainter old) =>
      old.time != time ||
      old.reaction != reaction ||
      old.mood != mood ||
      old.character != character;
}
