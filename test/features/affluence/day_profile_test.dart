import 'package:flutter_test/flutter_test.dart';
import 'package:plage_review/features/affluence/domain/day_profile.dart';
import 'package:plage_review/features/affluence/domain/entities/hourly_affluence_stat.dart';

void main() {
  final now = DateTime(2026, 7, 12, 15, 0);

  test('extracts the 12 buckets for the given weekday only', () {
    final monday14to16 = HourlyAffluenceStat(avgLevel: 3, sampleCount: 5, lastUpdated: now);
    final tuesday14to16 = HourlyAffluenceStat(avgLevel: 1, sampleCount: 4, lastUpdated: now);

    final weekly = {
      '1_7': monday14to16, // Monday, bucket 7 = 14h-16h
      '2_7': tuesday14to16, // Tuesday, same bucket — must not leak in
    };

    final result = dayProfile(weekly, 1);

    expect(result.length, kHourBucketsPerDay);
    expect(result[7], monday14to16);
    expect(result.where((b) => b != null).length, 1);
  });

  test('missing buckets are null rather than a fabricated zero', () {
    final result = dayProfile(const {}, 3);

    expect(result, everyElement(isNull));
  });
}
