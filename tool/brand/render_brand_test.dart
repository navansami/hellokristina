// Renders the brand masters from code, so the icons stay crisp and on-brand.
//
//   flutter test tool/brand/render_brand_test.dart
//   python scripts/export-brand-assets.py
//
// Writes, under assets/branding/:
//   app-icon-source.png      1024² full-bleed app icon (Kristina, heart bubble)
//   app-icon-maskable.png    1024² with the extras inside Android's safe circle
//   favicon-source.png       512² happy speech bubble, transparent corners
// It lives outside test/ so normal `flutter test` runs never rewrite assets.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_kristina/widgets/animated_kristina.dart';

const _gradient = [Color(0xFFFF9A4D), Color(0xFFF2622E), Color(0xFFD9431F)];

/// The warm orange brand field with soft light bubbles and a glow.
class _Field extends CustomPainter {
  const _Field();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _gradient)
              .createShader(rect));
    final s = size.width;
    canvas.drawCircle(Offset(s * .9, s * .08), s * .32,
        Paint()..color = Colors.white.withValues(alpha: .1));
    canvas.drawCircle(Offset(s * .02, s * .98), s * .3,
        Paint()..color = Colors.white.withValues(alpha: .08));
    final glow = Offset(s * .48, s * .5);
    canvas.drawCircle(
        glow,
        s * .42,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFFFD2A8).withValues(alpha: .5),
            const Color(0xFFFFD2A8).withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: glow, radius: s * .42)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Four-point sparkles at (x, y, radius), as fractions of the width.
class _Sparkles extends CustomPainter {
  const _Sparkles(this.points);
  final List<(double, double, double)> points;
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    for (final (x, y, r) in points) {
      final c = Offset(x * s, y * s), radius = r * s;
      final path = Path();
      for (var i = 0; i < 8; i++) {
        final len = i.isEven ? radius : radius * .32;
        final a = -math.pi / 2 + i * math.pi / 4;
        final p = c + Offset(math.cos(a) * len, math.sin(a) * len);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
          path..close(), Paint()..color = Colors.white.withValues(alpha: .92));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// A chunky white speech bubble with a soft ledge and a curved tail,
/// holding either a heart or a smiling face.
class _Bubble extends CustomPainter {
  const _Bubble({this.face = false});
  final bool face;
  static const ledge = Color(0xFFFFC7A3);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = h * .8;
    final rect = Rect.fromLTWH(0, 0, w, body);
    final radius = Radius.circular(body * .42);
    final tail = Path()
      ..moveTo(w * .2, body * .6)
      ..lineTo(w * .2, body * .96)
      ..quadraticBezierTo(w * .2, h * .92, w * .08, h)
      ..quadraticBezierTo(w * .32, h * .97, w * .46, body * .96)
      ..lineTo(w * .46, body * .6)
      ..close();
    // Ledge first, then the white bubble on top.
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect.shift(Offset(0, h * .07)), radius),
        Paint()..color = ledge);
    canvas.drawPath(tail.shift(Offset(0, h * .04)), Paint()..color = ledge);
    canvas.drawPath(tail, Paint()..color = Colors.white);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius), Paint()..color = Colors.white);

    if (face) {
      const ink = Color(0xFF221C3F);
      for (final x in [w * .35, w * .65]) {
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(x, body * .4),
                width: w * .13,
                height: body * .27),
            Paint()..color = ink);
        canvas.drawCircle(Offset(x - w * .02, body * .34), w * .028,
            Paint()..color = Colors.white);
      }
      canvas.drawPath(
          Path()
            ..moveTo(w * .33, body * .66)
            ..quadraticBezierTo(w * .5, body * .86, w * .67, body * .66),
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = w * .075);
      for (final x in [w * .18, w * .82]) {
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(x, body * .62),
                width: w * .14,
                height: body * .12),
            Paint()..color = const Color(0x66FF6B7A));
      }
    } else {
      final c = Offset(w * .5, body * .5), s = body * .28;
      canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy + s * .9)
            ..cubicTo(c.dx - s * 1.3, c.dy, c.dx - s * .8, c.dy - s * .95, c.dx,
                c.dy - s * .35)
            ..cubicTo(c.dx + s * .8, c.dy - s * .95, c.dx + s * 1.3, c.dy, c.dx,
                c.dy + s * .9)
            ..close(),
          Paint()..color = const Color(0xFFFF4D6D));
      canvas.drawCircle(c + Offset(-s * .45, -s * .3), s * .16,
          Paint()..color = Colors.white.withValues(alpha: .7));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Kristina (head and shoulders), her heart bubble and sparkles. [safe]
/// pulls the bubble and sparkles into Android's central safe circle.
Widget _iconArt(double s, {bool safe = false}) => Stack(children: [
      Positioned(
          left: -s * .118,
          top: safe ? s * .02 : -s * .046,
          width: s * 1.196,
          height: s * 1.235,
          child: const AnimatedKristina(
              width: 400,
              height: 400,
              mood: 'happy',
              framing: TutorFraming.bust,
              gaze: Offset(.15, -.05))),
      Positioned(
          right: safe ? s * .22 : s * .05,
          top: safe ? s * .22 : s * .06,
          width: s * (safe ? .22 : .3),
          height: s * (safe ? .18 : .25),
          child: const CustomPaint(painter: _Bubble())),
      Positioned.fill(
          child: CustomPaint(
              painter: _Sparkles(safe
                  ? const [(.22, .24, .032), (.8, .68, .024)]
                  : const [
                      (.1, .14, .04),
                      (.93, .64, .03),
                      (.07, .62, .022)
                    ]))),
    ]);

Widget appIcon(double s, {bool maskable = false}) => SizedBox(
    width: s,
    height: s,
    child: ClipRect(
        child: Stack(children: [
      const Positioned.fill(child: CustomPaint(painter: _Field())),
      Positioned.fill(child: _iconArt(s, safe: maskable)),
    ])));

Widget favicon(double s) => SizedBox(
    width: s,
    height: s,
    child: ClipRRect(
        borderRadius: BorderRadius.circular(s * .24),
        child: Stack(children: [
          const Positioned.fill(child: CustomPaint(painter: _Field())),
          Positioned(
              left: s * .1,
              top: s * .14,
              width: s * .8,
              height: s * .76,
              child: const CustomPaint(painter: _Bubble(face: true))),
        ])));

Future<void> _render(
    WidgetTester tester, Widget child, double size, String path) async {
  final key = GlobalKey();
  await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
              child: RepaintBoundary(
                  key: key,
                  child: SizedBox(width: size, height: size, child: child))))));
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 4);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('render brand masters', (tester) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // 256 logical px × pixelRatio 4 = 1024 px masters.
    await _render(
        tester, appIcon(256), 256, 'assets/branding/app-icon-source.png');
    await _render(tester, appIcon(256, maskable: true), 256,
        'assets/branding/app-icon-maskable.png');
    await _render(
        tester, favicon(128), 128, 'assets/branding/favicon-source.png');
  });
}
