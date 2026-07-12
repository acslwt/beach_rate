import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/base_card.dart';
import '../../domain/entities/affluence_level.dart';
import '../../domain/entities/zone_affluence_stats.dart';

/// Detail panel shown when a spot marker is selected: current vs usual
/// affluence, recent report count, data reliability, last update — with a
/// dedicated state for "not enough data yet" rather than a misleading number.
class AffluenceCard extends StatelessWidget {
  const AffluenceCard({
    super.key,
    required this.spotName,
    required this.zoneId,
    required this.stats,
    required this.onClose,
    required this.onShowHistory,
  });

  final String spotName;

  /// The literal `affluence_zones/{zoneId}` document id in Firestore (already
  /// sanitized for `/`) — shown so it can be copied for manually seeding test
  /// data in the Firebase console.
  final String zoneId;
  final ZoneAffluenceStats? stats;
  final VoidCallback onClose;
  final VoidCallback onShowHistory;

  @override
  Widget build(BuildContext context) {
    final s = stats ?? ZoneAffluenceStats.empty(spotName);
    return BaseCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  spotName,
                  style: GoogleFonts.fredoka(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: appFmDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close_rounded, size: 20, color: appSearchGrey),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _LevelBlock(
                  label: 'Actuellement',
                  level: s.currentLevel,
                  emptyHint: 'Pas encore de signalement récent',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LevelBlock(
                  label: 'Habituellement',
                  level: s.usualLevel,
                  emptyHint: 'Historique insuffisant',
                ),
              ),
            ],
          ),
          if (s.deltaFromUsual != null) ...[
            const SizedBox(height: 10),
            _ComparisonBanner(delta: s.deltaFromUsual!),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              _MetaChip(
                icon: Icons.people_alt_rounded,
                label: '${s.recentReportsCount} signalement${s.recentReportsCount > 1 ? 's' : ''}',
              ),
              const SizedBox(width: 8),
              _MetaChip(
                icon: Icons.verified_rounded,
                label: s.reliability.label,
              ),
            ],
          ),
          if (s.lastUpdated != null) ...[
            const SizedBox(height: 10),
            Text(
              'Mis à jour ${_relativeTime(s.lastUpdated!)}',
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: appInkMid,
              ),
            ),
          ],
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onShowHistory,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const Icon(Icons.bar_chart_rounded, size: 16, color: appCoral),
                const SizedBox(width: 6),
                Text(
                  'Voir l\'historique par heure',
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: appCoral,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, size: 18, color: appCoral),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            'ID document Firestore : $zoneId',
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: appInkMid,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBlock extends StatelessWidget {
  const _LevelBlock({
    required this.label,
    required this.level,
    required this.emptyHint,
  });

  final String label;
  final double? level;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    final currentLevel = level;
    final color = currentLevel != null
        ? appAffluenceLevelColors[AffluenceLevel.fromScore(currentLevel).value]
        : appInkMid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: appSuggHover,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: appSearchGrey,
            ),
          ),
          const SizedBox(height: 4),
          if (currentLevel != null)
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
                Expanded(
                  child: Text(
                    AffluenceLevel.fromScore(currentLevel).label,
                    style: GoogleFonts.fredoka(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: appFmDark,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              emptyHint,
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: appInkMid,
              ),
            ),
        ],
      ),
    );
  }
}

class _ComparisonBanner extends StatelessWidget {
  const _ComparisonBanner({required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color color;
    if (delta > 0.5) {
      text = 'Plus fréquenté que d\'habitude';
      color = appCrowdRed;
    } else if (delta < -0.5) {
      text = 'Plus calme que d\'habitude';
      color = appCrowdGreen;
    } else {
      text = 'Comme d\'habitude';
      color = appCrowdOrange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: appClearBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: appClearIcon),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: appMossText,
            ),
          ),
        ],
      ),
    );
  }
}

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'à l\'instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  return 'il y a ${diff.inDays} j';
}
