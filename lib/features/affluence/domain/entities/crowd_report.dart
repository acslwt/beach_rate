import 'affluence_level.dart';

/// A single user-submitted affluence report for a zone.
class CrowdReport {
  final String id;
  final String zoneId;
  final String userId;
  final AffluenceLevel level;
  final DateTime createdAt;

  const CrowdReport({
    required this.id,
    required this.zoneId,
    required this.userId,
    required this.level,
    required this.createdAt,
  });
}
