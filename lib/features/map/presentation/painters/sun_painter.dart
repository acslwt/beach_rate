import 'dart:math' show cos, sin, pi;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SunPainter extends CustomPainter {
  const SunPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final rayPaint = Paint()
      ..color = appSunYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final a = i * pi / 4;
      canvas.drawLine(
        Offset(cx + cos(a) * 7.5, cy + sin(a) * 7.5),
        Offset(cx + cos(a) * 11.5, cy + sin(a) * 11.5),
        rayPaint,
      );
    }
    canvas.drawCircle(Offset(cx, cy), 5.5, Paint()..color = appSunYellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
