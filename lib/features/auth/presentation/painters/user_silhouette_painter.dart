import 'package:flutter/material.dart';

class UserSilhouettePainter extends CustomPainter {
  final Color color;

  const UserSilhouettePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;

    // Head
    canvas.drawCircle(Offset(cx, size.height * 0.30), size.width * 0.20, paint);

    // Shoulders
    final path = Path()
      ..moveTo(size.width * 0.04, size.height * 0.98)
      ..cubicTo(
        size.width * 0.04, size.height * 0.68,
        size.width * 0.22, size.height * 0.56,
        cx, size.height * 0.56,
      )
      ..cubicTo(
        size.width * 0.78, size.height * 0.56,
        size.width * 0.96, size.height * 0.68,
        size.width * 0.96, size.height * 0.98,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(UserSilhouettePainter old) => old.color != color;
}
