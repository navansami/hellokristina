import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../practice/object_bank.dart';

class LearningObject extends StatelessWidget {
  final String name;
  const LearningObject({super.key, required this.name});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 80,
      height: 78,
      child: CustomPaint(
          painter: _ObjectPainter(PictureOption.parse(name).key)));
}

class _ObjectPainter extends CustomPainter {
  final String name;
  _ObjectPainter(this.name);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 80, size.height / 78);
    final paint = Paint()..isAntiAlias = true;
    void oval(Rect rect, Color color) {
      paint
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawOval(rect, paint);
    }

    void round(Rect rect, Color color, double radius) {
      paint
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);
    }

    void line(Offset a, Offset b, Color color, double width) {
      paint
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(a, b, paint);
    }

    oval(const Rect.fromLTWH(11, 65, 58, 8), const Color(0x22000000));
    switch (name) {
      case 'coffee':
        paint
          ..color = const Color(0xFFEACD8B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8;
        canvas.drawOval(const Rect.fromLTWH(49, 29, 22, 24), paint);
        round(const Rect.fromLTWH(14, 27, 44, 35), const Color(0xFFFFE2A0), 10);
        oval(const Rect.fromLTWH(14, 22, 44, 13), const Color(0xFFFFF1CE));
        oval(const Rect.fromLTWH(20, 25, 32, 7), const Color(0xFF754735));
        round(const Rect.fromLTWH(8, 63, 58, 5), const Color(0xFFEACD8B), 3);
        paint
          ..color = const Color(0xFF93A7B2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(
            Path()
              ..moveTo(29, 14)
              ..quadraticBezierTo(24, 9, 30, 4)
              ..moveTo(42, 16)
              ..quadraticBezierTo(47, 10, 41, 5),
            paint);
      case 'water':
        paint
          ..color = const Color(0xFF49C0F8)
          ..style = PaintingStyle.fill;
        canvas.drawPath(
            Path()
              ..moveTo(40, 5)
              ..cubicTo(34, 19, 15, 35, 17, 49)
              ..cubicTo(19, 77, 63, 76, 64, 48)
              ..cubicTo(65, 35, 45, 16, 40, 5)
              ..close(),
            paint);
        paint
          ..color = const Color(0xFFB8EDFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(
            Path()
              ..moveTo(28, 42)
              ..quadraticBezierTo(22, 54, 32, 58),
            paint);
      case 'milk':
        round(const Rect.fromLTWH(20, 15, 40, 53), const Color(0xFF72C6E7), 7);
        round(const Rect.fromLTWH(24, 30, 32, 34), const Color(0xFFF5F7E9), 4);
        oval(const Rect.fromLTWH(20, 9, 40, 14), const Color(0xFFB9E9F8));
        oval(const Rect.fromLTWH(25, 12, 30, 8), const Color(0xFFE7F7FC));
        round(const Rect.fromLTWH(27, 24, 4, 24), const Color(0xFFC9EDFA), 2);
      case 'tea':
        round(const Rect.fromLTWH(16, 28, 40, 32), const Color(0xFF8FD16A), 8);
        oval(const Rect.fromLTWH(16, 22, 40, 14), const Color(0xFFD7F5B8));
        oval(const Rect.fromLTWH(24, 25, 24, 7), const Color(0xFFC47A3A));
        round(const Rect.fromLTWH(48, 30, 16, 8), const Color(0xFFCE883B), 3);
        line(const Offset(56, 30), const Offset(62, 18), const Color(0xFFCE883B), 3);
        round(const Rect.fromLTWH(58, 12, 10, 12), const Color(0xFFFFD18A), 2);
      case 'fruit':
        oval(const Rect.fromLTWH(18, 18, 44, 46), const Color(0xFFFF5A5A));
        oval(const Rect.fromLTWH(24, 24, 16, 12), const Color(0xFFFF8D8D));
        line(const Offset(40, 18), const Offset(44, 8), const Color(0xFF6B4A2B), 4);
        round(const Rect.fromLTWH(46, 8, 16, 10), const Color(0xFF58A700), 5);
      case 'vegetables':
        paint
          ..color = const Color(0xFFFF8A1E)
          ..style = PaintingStyle.fill;
        canvas.drawPath(
            Path()
              ..moveTo(18, 22)
              ..quadraticBezierTo(40, 8, 62, 28)
              ..quadraticBezierTo(48, 70, 28, 62)
              ..close(),
            paint);
        line(const Offset(22, 24), const Offset(30, 8), const Color(0xFF58A700), 5);
        line(const Offset(30, 18), const Offset(44, 6), const Color(0xFF7AC70C), 5);
      case 'meat':
        oval(const Rect.fromLTWH(14, 28, 40, 28), const Color(0xFFD4654A));
        oval(const Rect.fromLTWH(22, 34, 22, 14), const Color(0xFFFFD2A8));
        round(const Rect.fromLTWH(44, 18, 12, 36), const Color(0xFFF2E2C4), 6);
      case 'icecream':
        paint
          ..color = const Color(0xFFE7B15A)
          ..style = PaintingStyle.fill;
        canvas.drawPath(
            Path()
              ..moveTo(28, 36)
              ..lineTo(40, 70)
              ..lineTo(52, 36)
              ..close(),
            paint);
        oval(const Rect.fromLTWH(22, 16, 36, 28), const Color(0xFFFFF1CE));
        oval(const Rect.fromLTWH(30, 8, 22, 20), const Color(0xFFFFB7D5));
      case 'chocolate':
        round(const Rect.fromLTWH(14, 18, 52, 40), const Color(0xFF7A4A24), 6);
        for (var x = 0; x < 3; x++) {
          for (var y = 0; y < 2; y++) {
            round(Rect.fromLTWH(18 + x * 16, 22 + y * 18, 12, 14),
                const Color(0xFF5C3718), 3);
          }
        }
      case 'salad':
        oval(const Rect.fromLTWH(12, 28, 56, 32), const Color(0xFFD0DEE6));
        oval(const Rect.fromLTWH(18, 22, 44, 26), const Color(0xFF58A700));
        oval(const Rect.fromLTWH(24, 18, 18, 16), const Color(0xFF7AC70C));
        oval(const Rect.fromLTWH(40, 20, 14, 12), const Color(0xFFFF5A5A));
      case 'soup':
        oval(const Rect.fromLTWH(12, 30, 56, 28), const Color(0xFF8FD0E8));
        oval(const Rect.fromLTWH(18, 28, 44, 18), const Color(0xFFFFB15A));
        line(const Offset(30, 24), const Offset(28, 12), const Color(0xFF93A7B2), 3);
        line(const Offset(44, 22), const Offset(48, 10), const Color(0xFF93A7B2), 3);
      case 'eggs':
        oval(const Rect.fromLTWH(12, 28, 28, 34), const Color(0xFFFFF6E4));
        oval(const Rect.fromLTWH(36, 24, 30, 38), const Color(0xFFFFF1CE));
        oval(const Rect.fromLTWH(44, 34, 12, 14), const Color(0xFFFFD36A));
      case 'pasta':
        oval(const Rect.fromLTWH(10, 30, 60, 28), const Color(0xFFD7E4EA));
        paint
          ..color = const Color(0xFFFFD36A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(
            Path()
              ..moveTo(22, 40)
              ..quadraticBezierTo(34, 30, 46, 42)
              ..quadraticBezierTo(56, 50, 60, 38)
              ..moveTo(20, 48)
              ..quadraticBezierTo(36, 40, 54, 50),
            paint);
      case 'dog':
        oval(const Rect.fromLTWH(16, 22, 48, 40), const Color(0xFFC47A3A));
        oval(const Rect.fromLTWH(14, 16, 16, 20), const Color(0xFF8C4E22));
        oval(const Rect.fromLTWH(50, 16, 16, 20), const Color(0xFF8C4E22));
        oval(const Rect.fromLTWH(28, 34, 8, 8), const Color(0xFF2C404B));
        oval(const Rect.fromLTWH(44, 34, 8, 8), const Color(0xFF2C404B));
        oval(const Rect.fromLTWH(34, 44, 12, 10), const Color(0xFF2C404B));
      case 'cat':
        paint
          ..color = const Color(0xFF7A6A8A)
          ..style = PaintingStyle.fill;
        canvas.drawPath(
            Path()
              ..moveTo(18, 36)
              ..lineTo(22, 14)
              ..lineTo(34, 28)
              ..lineTo(46, 14)
              ..lineTo(50, 36)
              ..close(),
            paint);
        oval(const Rect.fromLTWH(18, 28, 44, 34), const Color(0xFF7A6A8A));
        oval(const Rect.fromLTWH(30, 40, 8, 6), const Color(0xFFFFB7D5));
        oval(const Rect.fromLTWH(28, 36, 6, 6), const Color(0xFF2C404B));
        oval(const Rect.fromLTWH(46, 36, 6, 6), const Color(0xFF2C404B));
      case 'house':
        round(const Rect.fromLTWH(16, 32, 48, 32), const Color(0xFFFFB15A), 4);
        paint
          ..color = const Color(0xFFCE4B3A)
          ..style = PaintingStyle.fill;
        canvas.drawPath(
            Path()
              ..moveTo(10, 34)
              ..lineTo(40, 10)
              ..lineTo(70, 34)
              ..close(),
            paint);
        round(const Rect.fromLTWH(34, 44, 14, 20), const Color(0xFF8C4E22), 2);
      case 'bus':
        round(const Rect.fromLTWH(8, 22, 64, 34), const Color(0xFFFFD36A), 8);
        round(const Rect.fromLTWH(14, 28, 16, 12), const Color(0xFFBEE6F8), 3);
        round(const Rect.fromLTWH(34, 28, 16, 12), const Color(0xFFBEE6F8), 3);
        oval(const Rect.fromLTWH(16, 48, 12, 12), const Color(0xFF2C404B));
        oval(const Rect.fromLTWH(50, 48, 12, 12), const Color(0xFF2C404B));
      case 'train':
        round(const Rect.fromLTWH(6, 26, 68, 28), const Color(0xFF3CB371), 8);
        round(const Rect.fromLTWH(12, 32, 14, 10), const Color(0xFFBEE6F8), 2);
        round(const Rect.fromLTWH(32, 32, 14, 10), const Color(0xFFBEE6F8), 2);
        round(const Rect.fromLTWH(52, 32, 14, 10), const Color(0xFFBEE6F8), 2);
        oval(const Rect.fromLTWH(14, 48, 10, 10), const Color(0xFF2C404B));
        oval(const Rect.fromLTWH(54, 48, 10, 10), const Color(0xFF2C404B));
      case 'tram':
        round(const Rect.fromLTWH(14, 24, 52, 32), const Color(0xFF49C0F8), 8);
        round(const Rect.fromLTWH(22, 30, 14, 12), const Color(0xFFE7F7FC), 2);
        round(const Rect.fromLTWH(42, 30, 14, 12), const Color(0xFFE7F7FC), 2);
        line(const Offset(40, 24), const Offset(40, 8), const Color(0xFF52656D), 3);
        line(const Offset(18, 10), const Offset(62, 10), const Color(0xFF52656D), 3);
        oval(const Rect.fromLTWH(22, 50, 10, 10), const Color(0xFF2C404B));
        oval(const Rect.fromLTWH(48, 50, 10, 10), const Color(0xFF2C404B));
      case 'book':
        round(const Rect.fromLTWH(10, 16, 28, 46), const Color(0xFF49C0F8), 4);
        round(const Rect.fromLTWH(42, 16, 28, 46), const Color(0xFF1F8CC4), 4);
        round(const Rect.fromLTWH(16, 22, 18, 34), const Color(0xFFF7FBFC), 2);
        round(const Rect.fromLTWH(46, 22, 18, 34), const Color(0xFFF7FBFC), 2);
      case 'school':
        round(const Rect.fromLTWH(14, 28, 52, 34), const Color(0xFF8E6ADF), 4);
        paint
          ..color = const Color(0xFF5E429C)
          ..style = PaintingStyle.fill;
        canvas.drawPath(
            Path()
              ..moveTo(8, 30)
              ..lineTo(40, 12)
              ..lineTo(72, 30)
              ..close(),
            paint);
        round(const Rect.fromLTWH(34, 40, 12, 22), const Color(0xFFFFE2A0), 2);
        line(const Offset(40, 12), const Offset(40, 4), const Color(0xFF52656D), 3);
        round(const Rect.fromLTWH(40, 4, 12, 8), const Color(0xFFFF7279), 1);
      case 'menu':
        round(const Rect.fromLTWH(20, 10, 40, 54), const Color(0xFFF7FBFC), 4);
        round(const Rect.fromLTWH(26, 18, 28, 4), const Color(0xFF52656D), 2);
        round(const Rect.fromLTWH(26, 28, 22, 3), const Color(0xFF93A7B2), 2);
        round(const Rect.fromLTWH(26, 36, 24, 3), const Color(0xFF93A7B2), 2);
        round(const Rect.fromLTWH(26, 44, 18, 3), const Color(0xFF93A7B2), 2);
      case 'phone':
        round(const Rect.fromLTWH(26, 8, 28, 56), const Color(0xFF2C404B), 8);
        round(const Rect.fromLTWH(30, 14, 20, 40), const Color(0xFF49C0F8), 3);
        oval(const Rect.fromLTWH(36, 56, 8, 4), const Color(0xFF93A7B2));
      case 'sun':
        oval(const Rect.fromLTWH(24, 20, 32, 32), const Color(0xFFFFD36A));
        for (var i = 0; i < 8; i++) {
          final angle = i * 3.14159 / 4;
          line(
              Offset(40 + 18 * math.cos(angle), 36 + 18 * math.sin(angle)),
              Offset(40 + 28 * math.cos(angle), 36 + 28 * math.sin(angle)),
              const Color(0xFFFFD36A),
              4);
        }
      case 'rain':
        oval(const Rect.fromLTWH(14, 18, 28, 22), const Color(0xFFD0DEE6));
        oval(const Rect.fromLTWH(30, 14, 32, 26), const Color(0xFFEEF5F8));
        line(const Offset(28, 44), const Offset(24, 58), const Color(0xFF49C0F8), 4);
        line(const Offset(42, 44), const Offset(38, 60), const Color(0xFF49C0F8), 4);
        line(const Offset(54, 42), const Offset(50, 56), const Color(0xFF49C0F8), 4);
      case 'jacket':
        paint
          ..color = const Color(0xFFCE4B3A)
          ..style = PaintingStyle.fill;
        canvas.drawPath(
            Path()
              ..moveTo(28, 14)
              ..quadraticBezierTo(40, 22, 52, 14)
              ..lineTo(68, 28)
              ..lineTo(56, 36)
              ..lineTo(56, 64)
              ..lineTo(24, 64)
              ..lineTo(24, 36)
              ..lineTo(12, 28)
              ..close(),
            paint);
        line(const Offset(40, 22), const Offset(40, 64), const Color(0xFF8C2E24), 3);
      case 'shoe':
        round(const Rect.fromLTWH(10, 36, 52, 16), const Color(0xFF3D4F59), 8);
        round(const Rect.fromLTWH(40, 24, 24, 22), const Color(0xFF52656D), 8);
        round(const Rect.fromLTWH(14, 48, 50, 8), const Color(0xFF2C404B), 4);
      case 'eye':
        paint
          ..color = const Color(0xFFF7FBFC)
          ..style = PaintingStyle.fill;
        canvas.drawPath(
            Path()
              ..moveTo(8, 40)
              ..quadraticBezierTo(40, 8, 72, 40)
              ..quadraticBezierTo(40, 68, 8, 40)
              ..close(),
            paint);
        oval(const Rect.fromLTWH(30, 26, 20, 24), const Color(0xFF49C0F8));
        oval(const Rect.fromLTWH(36, 32, 8, 10), const Color(0xFF131F24));
      case 'money':
        round(const Rect.fromLTWH(10, 22, 60, 34), const Color(0xFF58A700), 6);
        oval(const Rect.fromLTWH(32, 28, 16, 22), const Color(0xFFD7F5B8));
        round(const Rect.fromLTWH(16, 34, 10, 8), const Color(0xFF7AC70C), 4);
      case 'bread':
      default:
        round(const Rect.fromLTWH(9, 31, 62, 36), const Color(0xFFCE883B), 10);
        oval(const Rect.fromLTWH(8, 13, 64, 43), const Color(0xFFCE883B));
        round(const Rect.fromLTWH(15, 32, 50, 29), const Color(0xFFFFD18A), 7);
        oval(const Rect.fromLTWH(14, 19, 52, 34), const Color(0xFFFFD18A));
        paint
          ..color = const Color(0xFFE6AA5D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(
            Path()
              ..moveTo(26, 28)
              ..lineTo(23, 38)
              ..moveTo(40, 26)
              ..lineTo(37, 36)
              ..moveTo(54, 28)
              ..lineTo(51, 38),
            paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ObjectPainter old) => old.name != name;
}
