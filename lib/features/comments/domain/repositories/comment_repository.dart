import '../entities/spot_comment.dart';

abstract interface class CommentRepository {
  /// Recent comments for [zoneId], newest first, updated live.
  Stream<List<SpotComment>> watchComments(String zoneId);

  Future<void> postComment({
    required String zoneId,
    required String userId,
    required String userName,
    required String text,
  });
}
