import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../painters/sun_painter.dart';

class WeatherPill extends StatelessWidget {
  const WeatherPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 9, 18, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF28321E).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CustomPaint(size: Size(24, 24), painter: SunPainter()),
          const SizedBox(width: 9),
          Text(
            'Ensoleillé',
            style: GoogleFonts.fredoka(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: appFmDark,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            '28°C',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: appTempGrey,
            ),
          ),
          const SizedBox(width: 9),
          Container(width: 1, height: 16, color: Colors.black.withValues(alpha: 0.10)),
          const SizedBox(width: 9),
          Text(
            'Une excellente journée!',
            style: GoogleFonts.nunito(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: appWarmOrange,
            ),
          ),
        ],
      ),
    );
  }
}
