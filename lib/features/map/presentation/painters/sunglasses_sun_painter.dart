import 'dart:math' show cos, sin, pi;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SunglassesSunPainter extends CustomPainter {
  const SunglassesSunPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s  = size.width / 40;
    final cx = 20 * s;
    final cy = 20 * s;

    canvas.drawCircle(Offset(cx, cy), 11 * s, Paint()..color = const Color(0xFFF7C948));

    final ray = Paint()
      ..color = const Color(0xFFF2A93C)
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final a = i * pi / 4;
      canvas.drawLine(
        Offset(cx + cos(a) * 13 * s, cy + sin(a) * 13 * s),
        Offset(cx + cos(a) * 18 * s, cy + sin(a) * 18 * s),
        ray,
      );
    }

    final lens = Paint()..color = const Color(0xFF3B3960);
    for (final lx in [14.0, 26.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(lx * s, 19 * s), width: 6.2 * s, height: 5 * s),
          Radius.circular(2.5 * s),
        ),
        lens,
      );
    }

    canvas.drawLine(
      Offset(17.1 * s, 19 * s),
      Offset(22.9 * s, 19 * s),
      Paint()
        ..color = const Color(0xFF3B3960)
        ..strokeWidth = 1.4 * s
        ..strokeCap = StrokeCap.round,
    );

    final smile = ui.Path()
      ..moveTo(15 * s, 24.5 * s)
      ..quadraticBezierTo(cx, 29 * s, 25 * s, 24.5 * s);
    canvas.drawPath(
      smile,
      Paint()
        ..color = const Color(0xFF3B3960)
        ..strokeWidth = 1.8 * s
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
