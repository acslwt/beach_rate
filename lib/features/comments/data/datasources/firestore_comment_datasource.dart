import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/firestore_ids.dart';

class FirestoreCommentDatasource {
  FirestoreCommentDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _comments(String zoneId) => _firestore
      .collection('spot_comments')
      .doc(firestoreZoneDocId(zoneId))
      .collection('comments');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchComments(String zoneId) {
    return _comments(zoneId)
        .orderBy('createdAt', descending: true)
        .limit(kCommentsFetchLimit)
        .snapshots();
  }

  Future<void> postComment(String zoneId, Map<String, dynamic> payload) =>
      _comments(zoneId).add(payload);
}
