import 'dart:math' show cos, sin, pi;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../domain/entities/map_spot.dart';

class SpotIconPainter extends CustomPainter {
  final SpotType type;
  final Color color;
  const SpotIconPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final h = size.height;
    switch (type) {
      case SpotType.pool:
        _wave(canvas, p, w, h, 0.38, 0.12);
        _wave(canvas, p, w, h, 0.62, 0.12);
      case SpotType.beach:
        canvas.drawCircle(Offset(w * 0.62, h * 0.36), w * 0.17, p);
        for (int i = 0; i < 6; i++) {
          final a = i * pi / 3;
          canvas.drawLine(
            Offset(w * 0.62 + cos(a) * w * 0.23, h * 0.36 + sin(a) * h * 0.23),
            Offset(w * 0.62 + cos(a) * w * 0.31, h * 0.36 + sin(a) * h * 0.31),
            p,
          );
        }
        canvas.drawLine(Offset(0, h * 0.72), Offset(w, h * 0.72), p);
        _wave(canvas, p, w, h, 0.85, 0.10);
      case SpotType.lake:
        final mt = ui.Path()
          ..moveTo(w * 0.05, h * 0.72)
          ..lineTo(w * 0.38, h * 0.22)
          ..lineTo(w * 0.62, h * 0.50)
          ..lineTo(w * 0.50, h * 0.50)
          ..lineTo(w * 0.75, h * 0.28)
          ..lineTo(w * 0.95, h * 0.72);
        canvas.drawPath(mt, p);
        _wave(canvas, p, w, h, 0.85, 0.08);
      case SpotType.river:
        final rv = ui.Path()
          ..moveTo(w * 0.30, 0)
          ..cubicTo(w * 0.80, h * 0.15, w * 0.10, h * 0.45, w * 0.65, h * 0.55)
          ..cubicTo(w * 0.95, h * 0.62, w * 0.25, h * 0.82, w * 0.65, h);
        canvas.drawPath(rv, p);
    }
  }

  void _wave(Canvas canvas, Paint p, double w, double h, double cy, double amp) {
    final path = ui.Path()
      ..moveTo(0, h * cy)
      ..quadraticBezierTo(w * 0.25, h * (cy - amp), w * 0.50, h * cy)
      ..quadraticBezierTo(w * 0.75, h * (cy + amp), w, h * cy);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(SpotIconPainter old) =>
      old.type != type || old.color != color;
}
