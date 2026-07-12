import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreCommunitySpotDatasource {
  FirestoreCommunitySpotDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('community_spots');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSpots() =>
      _collection.snapshots();

  Future<void> createSpot(Map<String, dynamic> payload) =>
      _collection.add(payload);
}
