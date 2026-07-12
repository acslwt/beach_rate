import 'dart:math' as math;
import '../../../core/constants/app_constants.dart';
import 'entities/crowd_report.dart';
import 'entities/hourly_affluence_stat.dart';
import 'entities/reliability_level.dart';
import 'entities/zone_affluence_stats.dart';

/// Pure aggregation logic for turning raw reports + historical stats into a
/// displayable [ZoneAffluenceStats]. No I/O — fully unit-testable.
class ZoneAffluenceCalculator {
  const ZoneAffluenceCalculator();

  ZoneAffluenceStats compute({
    required String zoneId,
    required List<CrowdReport> recentReports,
    required HourlyAffluenceStat? hourlyStat,
    required DateTime now,
    Duration window = kAffluenceRecentWindow,
  }) {
    final usualLevel =
        (hourlyStat != null && hourlyStat.sampleCount >= kMinHistoricalSamples)
            ? hourlyStat.avgLevel
            : null;

    if (recentReports.isEmpty) {
      return ZoneAffluenceStats(
        zoneId: zoneId,
        currentLevel: null,
        usualLevel: usualLevel,
        recentReportsCount: 0,
        reliability: ReliabilityLevel.insufficient,
        lastUpdated: hourlyStat?.lastUpdated,
      );
    }

    final sortedLevels = recentReports.map((r) => r.level.value.toDouble()).toList()
      ..sort();
    final median = _median(sortedLevels);

    var weightedSum = 0.0;
    var weightTotal = 0.0;
    for (final report in recentReports) {
      final age = now.difference(report.createdAt);
      final weight = _timeWeight(age, window) * _outlierWeight(report.level.value.toDouble(), median);
      weightedSum += report.level.value * weight;
      weightTotal += weight;
    }
    final currentLevel = weightTotal > 0 ? weightedSum / weightTotal : median;

    final distinctUsers = recentReports.map((r) => r.userId).toSet().length;
    final mean = sortedLevels.reduce((a, b) => a + b) / sortedLevels.length;
    final stdev = _stdev(sortedLevels, mean);

    final lastUpdated = recentReports
        .map((r) => r.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return ZoneAffluenceStats(
      zoneId: zoneId,
      currentLevel: currentLevel.clamp(0.0, 5.0),
      usualLevel: usualLevel,
      recentReportsCount: recentReports.length,
      reliability: _classifyReliability(
        reportsCount: recentReports.length,
        distinctUsers: distinctUsers,
        stdev: stdev,
      ),
      lastUpdated: lastUpdated,
    );
  }

  /// Decays linearly with age within [window]; never drops below 0.15 so an
  /// about-to-expire report still counts a little.
  double _timeWeight(Duration age, Duration window) {
    final t = age.inSeconds / window.inSeconds;
    return (1 - t).clamp(0.15, 1.0);
  }

  /// Dampens (never zeroes) reports far from the current median — an outlier
  /// still contributes, just less, until other reports confirm it (which
  /// shifts the median toward it on the next computation).
  double _outlierWeight(double level, double median) {
    final distance = (level - median).abs();
    return (1 - distance * 0.25).clamp(0.3, 1.0);
  }

  ReliabilityLevel _classifyReliability({
    required int reportsCount,
    required int distinctUsers,
    required double stdev,
  }) {
    if (reportsCount == 0) return ReliabilityLevel.insufficient;
    if (reportsCount < 3 || distinctUsers < 2) return ReliabilityLevel.low;
    if (stdev <= 1.0 && reportsCount >= 5) return ReliabilityLevel.high;
    return ReliabilityLevel.medium;
  }

  double _median(List<double> sortedValues) {
    final n = sortedValues.length;
    if (n.isOdd) return sortedValues[n ~/ 2];
    return (sortedValues[n ~/ 2 - 1] + sortedValues[n ~/ 2]) / 2;
  }

  double _stdev(List<double> values, double mean) {
    if (values.length < 2) return 0;
    final variance = values
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        values.length;
    return math.sqrt(variance);
  }
}
