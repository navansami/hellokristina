import 'package:flutter/material.dart';

class LearningObject extends StatelessWidget {
  final String name;
  const LearningObject({super.key, required this.name});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 80, height: 78, child: CustomPaint(painter: _ObjectPainter(name)));
}

class _ObjectPainter extends CustomPainter {
  final String name;
  _ObjectPainter(this.name);
  @override
  void paint(Canvas c, Size size) {
    c.scale(size.width / 80, size.height / 78);
    final p = Paint()..isAntiAlias = true;
    void oval(Rect rect, Color color) {
      p
        ..color = color
        ..style = PaintingStyle.fill;
      c.drawOval(rect, p);
    }

    void round(Rect rect, Color color, double r) {
      p
        ..color = color
        ..style = PaintingStyle.fill;
      c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)), p);
    }

    oval(const Rect.fromLTWH(11, 65, 58, 8), const Color(0x22000000));
    if (name.contains('Coffee')) {
      p
        ..color = const Color(0xFFEACD8B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;
      c.drawOval(const Rect.fromLTWH(49, 29, 22, 24), p);
      round(const Rect.fromLTWH(14, 27, 44, 35), const Color(0xFFFFE2A0), 10);
      oval(const Rect.fromLTWH(14, 22, 44, 13), const Color(0xFFFFF1CE));
      oval(const Rect.fromLTWH(20, 25, 32, 7), const Color(0xFF754735));
      round(const Rect.fromLTWH(8, 63, 58, 5), const Color(0xFFEACD8B), 3);
      p
        ..color = const Color(0xFF93A7B2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      c.drawPath(
          Path()
            ..moveTo(29, 14)
            ..quadraticBezierTo(24, 9, 30, 4)
            ..moveTo(42, 16)
            ..quadraticBezierTo(47, 10, 41, 5),
          p);
    } else if (name.contains('Water')) {
      p
        ..color = const Color(0xFF49C0F8)
        ..style = PaintingStyle.fill;
      c.drawPath(
          Path()
            ..moveTo(40, 5)
            ..cubicTo(34, 19, 15, 35, 17, 49)
            ..cubicTo(19, 77, 63, 76, 64, 48)
            ..cubicTo(65, 35, 45, 16, 40, 5)
            ..close(),
          p);
      p
        ..color = const Color(0xFFB8EDFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      c.drawPath(
          Path()
            ..moveTo(28, 42)
            ..quadraticBezierTo(22, 54, 32, 58),
          p);
    } else if (name.contains('Milk')) {
      round(const Rect.fromLTWH(20, 15, 40, 53), const Color(0xFF72C6E7), 7);
      round(const Rect.fromLTWH(24, 30, 32, 34), const Color(0xFFF5F7E9), 4);
      oval(const Rect.fromLTWH(20, 9, 40, 14), const Color(0xFFB9E9F8));
      oval(const Rect.fromLTWH(25, 12, 30, 8), const Color(0xFFE7F7FC));
      round(const Rect.fromLTWH(27, 24, 4, 24), const Color(0xFFC9EDFA), 2);
    } else {
      round(const Rect.fromLTWH(9, 31, 62, 36), const Color(0xFFCE883B), 10);
      oval(const Rect.fromLTWH(8, 13, 64, 43), const Color(0xFFCE883B));
      round(const Rect.fromLTWH(15, 32, 50, 29), const Color(0xFFFFD18A), 7);
      oval(const Rect.fromLTWH(14, 19, 52, 34), const Color(0xFFFFD18A));
      p
        ..color = const Color(0xFFE6AA5D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      c.drawPath(
          Path()
            ..moveTo(26, 28)
            ..lineTo(23, 38)
            ..moveTo(40, 26)
            ..lineTo(37, 36)
            ..moveTo(54, 28)
            ..lineTo(51, 38),
          p);
    }
  }

  @override
  bool shouldRepaint(covariant _ObjectPainter old) => old.name != name;
}
