import 'package:flutter_test/flutter_test.dart';
import 'package:plage_review/features/affluence/domain/entities/affluence_level.dart';
import 'package:plage_review/features/affluence/domain/entities/crowd_report.dart';
import 'package:plage_review/features/affluence/domain/entities/hourly_affluence_stat.dart';
import 'package:plage_review/features/affluence/domain/entities/reliability_level.dart';
import 'package:plage_review/features/affluence/domain/zone_affluence_calculator.dart';

void main() {
  const calculator = ZoneAffluenceCalculator();
  final now = DateTime(2026, 7, 12, 15, 0);
  const window = Duration(hours: 3);

  CrowdReport report({
    required String userId,
    required AffluenceLevel level,
    required Duration age,
  }) =>
      CrowdReport(
        id: 'r-$userId-${level.value}-${age.inSeconds}',
        zoneId: 'zone-1',
        userId: userId,
        level: level,
        createdAt: now.subtract(age),
      );

  group('compute', () {
    test('returns insufficient data when there are no recent reports and no history', () {
      final result = calculator.compute(
        zoneId: 'zone-1',
        recentReports: const [],
        hourlyStat: null,
        now: now,
        window: window,
      );

      expect(result.currentLevel, isNull);
      expect(result.usualLevel, isNull);
      expect(result.recentReportsCount, 0);
      expect(result.reliability, ReliabilityLevel.insufficient);
    });

    test('ignores a historical stat below the minimum sample threshold', () {
      final result = calculator.compute(
        zoneId: 'zone-1',
        recentReports: const [],
        hourlyStat: HourlyAffluenceStat(avgLevel: 3, sampleCount: 1, lastUpdated: now),
        now: now,
        window: window,
      );

      expect(result.usualLevel, isNull);
    });

    test('exposes usual level once enough historical samples exist', () {
      final result = calculator.compute(
        zoneId: 'zone-1',
        recentReports: const [],
        hourlyStat: HourlyAffluenceStat(avgLevel: 2.5, sampleCount: 10, lastUpdated: now),
        now: now,
        window: window,
      );

      expect(result.usualLevel, 2.5);
    });

    test('averages consistent recent reports close to their common level', () {
      final reports = [
        report(userId: 'a', level: AffluenceLevel.medium, age: const Duration(minutes: 5)),
        report(userId: 'b', level: AffluenceLevel.medium, age: const Duration(minutes: 10)),
        report(userId: 'c', level: AffluenceLevel.high, age: const Duration(minutes: 2)),
      ];

      final result = calculator.compute(
        zoneId: 'zone-1',
        recentReports: reports,
        hourlyStat: null,
        now: now,
        window: window,
      );

      expect(result.currentLevel, isNotNull);
      expect(result.currentLevel!, closeTo(3.3, 0.5));
      expect(result.recentReportsCount, 3);
    });

    test('dampens an outlier report instead of ignoring it', () {
      final consensusReports = List.generate(
        4,
        (i) => report(
          userId: 'user$i',
          level: AffluenceLevel.low,
          age: const Duration(minutes: 5),
        ),
      );
      final outlier = report(
        userId: 'outsider',
        level: AffluenceLevel.saturated,
        age: const Duration(minutes: 1),
      );

      final withOutlier = calculator.compute(
        zoneId: 'zone-1',
        recentReports: [...consensusReports, outlier],
        hourlyStat: null,
        now: now,
        window: window,
      );
      final withoutOutlier = calculator.compute(
        zoneId: 'zone-1',
        recentReports: consensusReports,
        hourlyStat: null,
        now: now,
        window: window,
      );

      // The outlier nudges the level up, but nowhere near a naive average
      // ((2+2+2+2+5)/5 = 2.6 vs the ~2.0 consensus) — it's dampened, not ignored.
      expect(withOutlier.currentLevel!, greaterThan(withoutOutlier.currentLevel!));
      expect(withOutlier.currentLevel!, lessThan(2.6));
    });

    test('a lone report is unaffected by its own age-based weight', () {
      final fresh = calculator.compute(
        zoneId: 'zone-1',
        recentReports: [
          report(userId: 'a', level: AffluenceLevel.high, age: const Duration(minutes: 1)),
        ],
        hourlyStat: null,
        now: now,
        window: window,
      );
      final stale = calculator.compute(
        zoneId: 'zone-1',
        recentReports: [
          report(userId: 'a', level: AffluenceLevel.high, age: const Duration(minutes: 179)),
        ],
        hourlyStat: null,
        now: now,
        window: window,
      );

      expect(fresh.currentLevel, stale.currentLevel);
      expect(fresh.currentLevel, AffluenceLevel.high.value.toDouble());
    });

    test('reliability improves with more consistent, multi-user reports', () {
      final fewReports = calculator.compute(
        zoneId: 'zone-1',
        recentReports: [
          report(userId: 'a', level: AffluenceLevel.medium, age: const Duration(minutes: 5)),
        ],
        hourlyStat: null,
        now: now,
        window: window,
      );
      final manyConsistentReports = calculator.compute(
        zoneId: 'zone-1',
        recentReports: List.generate(
          6,
          (i) => report(
            userId: 'user$i',
            level: AffluenceLevel.medium,
            age: Duration(minutes: i),
          ),
        ),
        hourlyStat: null,
        now: now,
        window: window,
      );

      expect(fewReports.reliability, ReliabilityLevel.low);
      expect(manyConsistentReports.reliability, ReliabilityLevel.high);
    });
  });
}
