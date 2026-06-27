import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/crowd_level.dart';
import '../../domain/entities/map_spot.dart';

class _SpotStyle {
  final double size;
  final Color fill;
  final Color border;
  final Color dot;
  const _SpotStyle(this.size, this.fill, this.border, this.dot);
}

class SpotMarker extends StatelessWidget {
  final MapSpot spot;
  final bool selected;
  final VoidCallback onTap;

  const SpotMarker({
    super.key,
    required this.spot,
    required this.selected,
    required this.onTap,
  });

  static _SpotStyle _styleFor(CrowdLevel crowd) => switch (crowd) {
    CrowdLevel.calm   => const _SpotStyle(78,  Color(0x4D7BC79C), Color(0x9E7BC79C), appCrowdGreen),
    CrowdLevel.medium => const _SpotStyle(98,  Color(0x52F0B860), Color(0xA3F0B860), appCrowdOrange),
    CrowdLevel.busy   => const _SpotStyle(120, Color(0x52E88678), Color(0xA3E88678), appCrowdRed),
  };

  static double zoneSize(CrowdLevel crowd) => switch (crowd) {
    CrowdLevel.calm   => 78.0,
    CrowdLevel.medium => 98.0,
    CrowdLevel.busy   => 120.0,
  };

  @override
  Widget build(BuildContext context) {
    final s = _styleFor(spot.crowd);
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: s.size,
          height: s.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: s.fill,
            border: Border.all(color: s.border, width: 1.2),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: AnimatedScale(
            scale: selected ? 1.09 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.fromLTRB(9, 7, 12, 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: selected ? s.dot : Colors.black.withValues(alpha: 0.05),
                  width: selected ? 2.0 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF28321E).withValues(alpha: 0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: s.dot),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    spot.name,
                    style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: appFmDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
