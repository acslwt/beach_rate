import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/spot_comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../datasources/firestore_comment_datasource.dart';
import '../models/spot_comment_model.dart';

class CommentRepositoryImpl implements CommentRepository {
  const CommentRepositoryImpl(this._datasource);

  final FirestoreCommentDatasource _datasource;

  @override
  Stream<List<SpotComment>> watchComments(String zoneId) {
    return _datasource.watchComments(zoneId).map(
          (snapshot) => snapshot.docs
              .map((doc) => SpotCommentModel.fromDoc(doc, zoneId))
              .toList(),
        );
  }

  @override
  Future<void> postComment({
    required String zoneId,
    required String userId,
    required String userName,
    required String text,
  }) {
    return _datasource.postComment(zoneId, {
      'userId': userId,
      'userName': userName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
