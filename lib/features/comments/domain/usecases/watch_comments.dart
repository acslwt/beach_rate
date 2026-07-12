import '../entities/spot_comment.dart';
import '../repositories/comment_repository.dart';

class WatchComments {
  const WatchComments(this._repository);

  final CommentRepository _repository;

  Stream<List<SpotComment>> call(String zoneId) => _repository.watchComments(zoneId);
}
