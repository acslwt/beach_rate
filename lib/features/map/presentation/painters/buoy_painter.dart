import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class BuoyPainter extends CustomPainter {
  const BuoyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s  = size.width / 40;
    final cx = 20 * s;
    final cy = 20 * s;

    canvas.drawCircle(Offset(cx, cy), 14 * s, Paint()..color = const Color(0xFFE0786C));

    final wp = Paint()..color = Colors.white;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 10 * s), width: 8 * s, height: 9 * s),
      Radius.circular(4 * s)), wp);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 30 * s), width: 8 * s, height: 9 * s),
      Radius.circular(4 * s)), wp);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(10 * s, cy), width: 9 * s, height: 8 * s),
      Radius.circular(4 * s)), wp);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(30 * s, cy), width: 9 * s, height: 8 * s),
      Radius.circular(4 * s)), wp);

    canvas.drawCircle(Offset(cx, cy), 6.2 * s, Paint()..color = const Color(0xFF8FCAD9));

    final wave = ui.Path()
      ..moveTo((20 - 4) * s, cy)
      ..quadraticBezierTo((20 - 2) * s, cy - 2 * s, cx, cy)
      ..quadraticBezierTo((20 + 2) * s, cy + 2 * s, (20 + 4) * s, cy);
    canvas.drawPath(
      wave,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.6 * s
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
