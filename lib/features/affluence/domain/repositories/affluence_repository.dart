import '../entities/affluence_level.dart';
import '../entities/crowd_report.dart';
import '../entities/hourly_affluence_stat.dart';

abstract interface class AffluenceRepository {
  /// Reports for [zoneId] created within [window] of now, updated live.
  Stream<List<CrowdReport>> watchRecentReports(String zoneId, Duration window);

  /// Historical average for [zoneId] at the weekday/hour bucket [at] falls
  /// into, or `null` if that bucket has no data yet.
  Future<HourlyAffluenceStat?> getHourlyStat(String zoneId, DateTime at);

  /// Every historical bucket for [zoneId], keyed by `"weekday_hourBucket"`
  /// (see [kAffluenceHourBucketSize]) — the full week's profile, updated
  /// live. Missing keys mean that bucket has no data yet.
  Stream<Map<String, HourlyAffluenceStat>> watchWeeklyProfile(String zoneId);

  /// When [userId] last reported on [zoneId], or `null` if never — used to
  /// show the cooldown state before the user attempts to submit.
  Future<DateTime?> lastReportTime(String zoneId, String userId);

  /// Submits a report, updates the zone's hourly stat, and credits the user
  /// with [kAffluencePointsPerReport] points, atomically.
  ///
  /// Throws [AffluenceCooldownException] if [userId] already reported on
  /// [zoneId] within [kAffluenceReportCooldown].
  Future<void> submitReport({
    required String zoneId,
    required String userId,
    required AffluenceLevel level,
  });
}
