import 'dart:ui' as ui;
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

  /// Live affluence level (0-5) reported by users, when available. Overrides
  /// the static [CrowdLevel] styling. `null` means no recent data yet, in
  /// which case the marker falls back to its previous static appearance.
  final double? liveLevel;

  const SpotMarker({
    super.key,
    required this.spot,
    required this.selected,
    required this.onTap,
    this.liveLevel,
  });

  static _SpotStyle _styleFor(CrowdLevel crowd) => switch (crowd) {
    CrowdLevel.calm   => const _SpotStyle(78,  Color(0x4D7BC79C), Color(0x9E7BC79C), appCrowdGreen),
    CrowdLevel.medium => const _SpotStyle(98,  Color(0x52F0B860), Color(0xA3F0B860), appCrowdOrange),
    CrowdLevel.busy   => const _SpotStyle(120, Color(0x52E88678), Color(0xA3E88678), appCrowdRed),
  };

  static _SpotStyle _styleForLevel(double level) {
    final t = (level / 5.0).clamp(0.0, 1.0);
    final color = _colorForLevel(level);
    final size = ui.lerpDouble(70, 130, t)!;
    return _SpotStyle(size, color.withValues(alpha: 0.32), color.withValues(alpha: 0.64), color);
  }

  static Color _colorForLevel(double level) {
    final clamped = level.clamp(0.0, 5.0);
    final lower = clamped.floor().clamp(0, 4);
    final upper = (lower + 1).clamp(0, 5);
    final t = clamped - lower;
    return Color.lerp(
      appAffluenceLevelColors[lower],
      appAffluenceLevelColors[upper],
      t,
    )!;
  }

  static double zoneSize(CrowdLevel crowd) => switch (crowd) {
    CrowdLevel.calm   => 78.0,
    CrowdLevel.medium => 98.0,
    CrowdLevel.busy   => 120.0,
  };

  static double zoneSizeForLevel(double level) =>
      ui.lerpDouble(70, 130, (level / 5.0).clamp(0.0, 1.0))!;

  @override
  Widget build(BuildContext context) {
    final level = liveLevel;
    final s = level != null ? _styleForLevel(level) : _styleFor(spot.crowd);
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
                  // The pill sits inside a fixed-size flutter_map Marker
                  // (zoneSize + 24) — a long real place name (e.g. "Les
                  // Orpelières") can easily exceed that, so it must be able
                  // to shrink and ellipsize instead of overflowing.
                  Flexible(
                    child: Text(
                      spot.name,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: appFmDark,
                      ),
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
