import 'package:flutter/material.dart';

/// A small riverside view of Kalemegdan's walls and clock tower.
class BelgradePostcard extends CustomPainter {
  const BelgradePostcard();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 230, size.height / 150);
    canvas.clipPath(Path()
      ..moveTo(0, 150)
      ..cubicTo(47, 148, 21, 112, 56, 90)
      ..quadraticBezierTo(36, 54, 25, 0)
      ..lineTo(230, 0)
      ..lineTo(230, 150)
      ..close());
    final brush = Paint()..isAntiAlias = true;
    void oval(double x, double y, double w, double h, Color color) {
      canvas.drawOval(Rect.fromLTWH(x, y, w, h), brush..color = color);
    }

    void rect(double x, double y, double w, double h, Color color) {
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), brush..color = color);
    }

    void fill(Path path, Color color) =>
        canvas.drawPath(path, brush..color = color);
    void tree(double x, double y, double h, Color leaf) {
      rect(x - 1.5, y - h * .45, 3, h * .45, const Color(0xFF71523E));
      oval(x - h * .19, y - h, h * .38, h * .76, leaf);
    }

    const teal = Color(0xFF4F8273), sage = Color(0xFF8CA88A);
    const stone = Color(0xFFF2C793), shade = Color(0xFFDC9E6E);
    const roof = Color(0xFF9D614A);
    oval(128, 14, 44, 44, const Color(0xFFFFCF83));
    for (final x in [48.0, 178.0]) {
      final y = x < 100 ? 39.0 : 22.0;
      oval(x, y, 41, 7, Colors.white);
      oval(x + 8, y - 5, 18, 10, Colors.white);
    }
    fill(
        Path()
          ..moveTo(0, 115)
          ..quadraticBezierTo(48, 93, 79, 102)
          ..quadraticBezierTo(124, 62, 158, 82)
          ..quadraticBezierTo(199, 60, 230, 72)
          ..lineTo(230, 150)
          ..lineTo(0, 150)
          ..close(),
        const Color(0xFFB9CFBA));
    for (final x in [59.0, 82.0, 170.0, 188.0, 218.0]) {
      tree(x, 117, 38 + x % 18, sage);
    }
    // The gate is a cut-out arch in the outer curtain wall.
    final wall = Path()
      ..moveTo(69, 93)
      ..lineTo(220, 82)
      ..lineTo(222, 115)
      ..lineTo(147, 122)
      ..lineTo(147, 109)
      ..quadraticBezierTo(138, 95, 130, 111)
      ..lineTo(130, 124)
      ..lineTo(69, 129)
      ..close();
    fill(wall, shade);
    for (var i = 0; i < 13; i++) {
      rect(69 + i * 12, 89 - i * .86, 7, 7, stone);
    }
    fill(
        Path()
          ..moveTo(69, 94)
          ..lineTo(220, 82)
          ..lineTo(220, 86)
          ..lineTo(69, 98)
          ..close(),
        stone);
    rect(124, 58, 23, 40, stone);
    rect(141, 58, 6, 40, shade);
    rect(122, 60, 27, 3, roof);
    rect(124, 42, 23, 18, const Color(0xFFFFDFA8));
    fill(
        Path()
          ..moveTo(120, 43)
          ..lineTo(124, 38)
          ..quadraticBezierTo(125, 31, 130, 29)
          ..lineTo(133, 22)
          ..lineTo(135, 16)
          ..lineTo(137, 23)
          ..lineTo(140, 30)
          ..quadraticBezierTo(146, 35, 146, 39)
          ..lineTo(150, 43)
          ..close(),
        teal);
    oval(130, 45, 10, 10, roof);
    oval(131, 46, 8, 8, Colors.white);
    rect(134.5, 47, 1, 4, roof);
    rect(135, 50, 3, 1, roof);
    rect(132, 72, 5, 13, roof);
    fill(
        Path()
          ..moveTo(0, 133)
          ..quadraticBezierTo(40, 119, 68, 121)
          ..quadraticBezierTo(135, 113, 172, 111)
          ..quadraticBezierTo(205, 102, 230, 105)
          ..lineTo(230, 150)
          ..lineTo(0, 150)
          ..close(),
        teal);
    for (final x in [47.0, 60.0, 193.0, 207.0, 224.0]) {
      tree(x, 125 - x * .055, 32 + x % 21, x == 207 ? sage : teal);
    }
    fill(
        Path()
          ..moveTo(0, 140)
          ..cubicTo(72, 132, 87, 126, 142, 126)
          ..quadraticBezierTo(191, 124, 230, 116)
          ..lineTo(230, 150)
          ..lineTo(0, 150)
          ..close(),
        const Color(0xFFA2CFCA));
    for (final x in [42.0, 88.0, 149.0, 171.0, 210.0]) {
      oval(x, 133 + x % 9, 17, 1.8, const Color(0xFFDAE9DB));
    }
  }

  @override
  bool shouldRepaint(BelgradePostcard oldDelegate) => false;
}
