import 'reliability_level.dart';

/// Computed affluence snapshot for a zone, ready for display.
class ZoneAffluenceStats {
  final String zoneId;

  /// Weighted-average of recent reports (0-5), or `null` if there isn't
  /// enough recent data yet.
  final double? currentLevel;

  /// Historical average for this zone at the current weekday/hour, or `null`
  /// if there isn't enough historical data yet.
  final double? usualLevel;

  final int recentReportsCount;
  final ReliabilityLevel reliability;
  final DateTime? lastUpdated;

  const ZoneAffluenceStats({
    required this.zoneId,
    required this.currentLevel,
    required this.usualLevel,
    required this.recentReportsCount,
    required this.reliability,
    required this.lastUpdated,
  });

  factory ZoneAffluenceStats.empty(String zoneId) => ZoneAffluenceStats(
        zoneId: zoneId,
        currentLevel: null,
        usualLevel: null,
        recentReportsCount: 0,
        reliability: ReliabilityLevel.insufficient,
        lastUpdated: null,
      );

  bool get hasCurrentData => currentLevel != null;
  bool get hasUsualData => usualLevel != null;

  /// Positive → plus fréquenté que d'habitude, négatif → plus calme.
  double? get deltaFromUsual => (currentLevel != null && usualLevel != null)
      ? currentLevel! - usualLevel!
      : null;
}
