import 'dart:math' show cos, sin, pi;
import 'package:flutter/material.dart';

class SearchIconPainter extends CustomPainter {
  final Color color;
  const SearchIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final cx = size.width * 0.40;
    final cy = size.height * 0.40;
    final r  = size.width * 0.30;
    canvas.drawCircle(Offset(cx, cy), r, paint);
    final startX = cx + r * cos(pi * 0.75);
    final startY = cy + r * sin(pi * 0.75);
    canvas.drawLine(
      Offset(startX, startY),
      Offset(size.width * 0.92, size.height * 0.92),
      paint,
    );
  }

  @override
  bool shouldRepaint(SearchIconPainter old) => old.color != color;
}
