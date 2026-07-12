import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class MascotWidget extends StatefulWidget {
  const MascotWidget({super.key});

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _float.value),
        child: child,
      ),
      child: Container(
        width: 84,
        height: 84,
        decoration: const BoxDecoration(
          color: appMascotBg,
          shape: BoxShape.circle,
        ),
        child: CustomPaint(painter: _MascotFacePainter()),
      ),
    );
  }
}

class _MascotFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Face
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.38,
      Paint()
        ..color = appLavender
        ..style = PaintingStyle.fill,
    );

    // Eyes
    final eyePaint = Paint()
      ..color = appMarkerInk
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 7, cy - 2), 2.5, eyePaint);
    canvas.drawCircle(Offset(cx + 7, cy - 2), 2.5, eyePaint);

    // Smile
    final smilePath = Path()
      ..moveTo(cx - 8, cy + 5)
      ..quadraticBezierTo(cx, cy + 13, cx + 8, cy + 5);
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = appMarkerInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Rosy cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFFFB5C8).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 12, cy + 6), 5.5, cheekPaint);
    canvas.drawCircle(Offset(cx + 12, cy + 6), 5.5, cheekPaint);
  }

  @override
  bool shouldRepaint(_MascotFacePainter old) => false;
}
