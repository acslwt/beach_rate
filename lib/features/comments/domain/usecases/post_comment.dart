import '../repositories/comment_repository.dart';

class PostComment {
  const PostComment(this._repository);

  final CommentRepository _repository;

  Future<void> call({
    required String zoneId,
    required String userId,
    required String userName,
    required String text,
  }) =>
      _repository.postComment(
        zoneId: zoneId,
        userId: userId,
        userName: userName,
        text: text.trim(),
      );
}
