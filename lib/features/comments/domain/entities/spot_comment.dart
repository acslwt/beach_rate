/// A free-text comment posted by a user on a spot.
class SpotComment {
  final String id;
  final String zoneId;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  const SpotComment({
    required this.id,
    required this.zoneId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });
}
