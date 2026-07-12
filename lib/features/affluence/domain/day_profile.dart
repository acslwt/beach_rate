import '../../../core/constants/app_constants.dart';
import 'entities/hourly_affluence_stat.dart';

/// Number of 2h buckets in a day (12 with the default bucket size).
int get kHourBucketsPerDay => 24 ~/ kAffluenceHourBucketSize;

/// Extracts the 12 hour-buckets for [weekday] (1 = Monday .. 7 = Sunday) out
/// of a zone's full weekly profile — index `i` covers
/// `[i * kAffluenceHourBucketSize, (i + 1) * kAffluenceHourBucketSize)`.
/// A `null` entry means that bucket has no data yet.
List<HourlyAffluenceStat?> dayProfile(
  Map<String, HourlyAffluenceStat> weeklyProfile,
  int weekday,
) {
  return List.generate(
    kHourBucketsPerDay,
    (bucket) => weeklyProfile['${weekday}_$bucket'],
  );
}
