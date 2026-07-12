import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/user_points_service.dart';

/// `MapSpot.id`/`NearbySpot.id` look like `"node/123456"` — the `/` is part
/// of the OSM id and is meaningful for the app, but Firestore's `.doc(path)`
/// treats `/` as a path separator, which turns a single document id into a
/// multi-segment path and trips the SDK's `isDocument()` assertion. This is
/// the one place that mapping happens, so every Firestore document built
/// from a zoneId goes through it.
String firestoreZoneDocId(String zoneId) => zoneId.replaceAll('/', '_');

class FirestoreAffluenceDatasource {
  FirestoreAffluenceDatasource(this._firestore, this._pointsService);

  final FirebaseFirestore _firestore;
  final UserPointsService _pointsService;

  CollectionReference<Map<String, dynamic>> _reports(String zoneId) => _firestore
      .collection('affluence_zones')
      .doc(firestoreZoneDocId(zoneId))
      .collection('reports');

  CollectionReference<Map<String, dynamic>> _hourlyStats(String zoneId) =>
      _firestore
          .collection('affluence_zones')
          .doc(firestoreZoneDocId(zoneId))
          .collection('hourly_stats');

  DocumentReference<Map<String, dynamic>> _hourlyStatDoc(
    String zoneId,
    String bucketKey,
  ) =>
      _hourlyStats(zoneId).doc(bucketKey);

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRecentReports(
    String zoneId,
    DateTime since,
  ) {
    return _reports(zoneId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(since))
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getHourlyStatDoc(
    String zoneId,
    String bucketKey,
  ) =>
      _hourlyStatDoc(zoneId, bucketKey).get();

  /// All buckets for a zone at once — at most 7 * (24 / bucket size) docs
  /// (84 with the default 2h buckets), cheap enough to fetch in one shot
  /// rather than querying per weekday.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchAllHourlyStats(String zoneId) =>
      _hourlyStats(zoneId).snapshots();

  Future<QuerySnapshot<Map<String, dynamic>>> lastReportForUser(
    String zoneId,
    String userId,
  ) {
    return _reports(zoneId)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
  }

  /// Writes the report, updates the zone's hourly running average, and
  /// credits the user's points — all in one transaction.
  Future<void> submitReport({
    required String zoneId,
    required String userId,
    required int level,
    required String bucketKey,
  }) async {
    final reportDoc = _reports(zoneId).doc();
    final statDoc = _hourlyStatDoc(zoneId, bucketKey);

    await _firestore.runTransaction((transaction) async {
      final statSnap = await transaction.get(statDoc);
      final currentPoints = await _pointsService.readPoints(transaction, userId);

      final prevAvg = (statSnap.data()?['avgLevel'] as num?)?.toDouble() ?? 0.0;
      final prevCount = (statSnap.data()?['sampleCount'] as num?)?.toInt() ?? 0;
      final newCount = prevCount + 1;
      final newAvg = (prevAvg * prevCount + level) / newCount;

      transaction.set(reportDoc, {
        'userId': userId,
        'level': level,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(statDoc, {
        'avgLevel': newAvg,
        'sampleCount': newCount,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _pointsService.commitAward(
        transaction,
        userId,
        currentPoints,
        kAffluencePointsPerReport,
      );
    });
  }
}
