/// Running average of reported affluence for a zone, for a given weekday +
/// hour bucket (e.g. "this beach, Saturdays 14h-16h"). Updated incrementally
/// each time a new report lands in that bucket — this is the "usual
/// affluence" baseline.
class HourlyAffluenceStat {
  final double avgLevel;
  final int sampleCount;
  final DateTime lastUpdated;

  const HourlyAffluenceStat({
    required this.avgLevel,
    required this.sampleCount,
    required this.lastUpdated,
  });
}
