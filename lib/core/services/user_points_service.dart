import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared wrapper around the `users/{uid}.points` document.
///
/// Used by the `auth` feature (read-only, to display the stat in the profile)
/// and by the `affluence` feature (read + write, inside its report-submission
/// transaction) — kept here in `core` so neither feature depends on the other.
class UserPointsService {
  UserPointsService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  Stream<int> watchPoints(String uid) => _userDoc(uid)
      .snapshots()
      .map((doc) => (doc.data()?['points'] as num?)?.toInt() ?? 0);

  /// Reads the current point total for [uid] within [transaction].
  /// Firestore transactions require all reads before any write, so callers
  /// must call this before [commitAward].
  Future<int> readPoints(Transaction transaction, String uid) async {
    final snap = await transaction.get(_userDoc(uid));
    return (snap.data()?['points'] as num?)?.toInt() ?? 0;
  }

  /// Queues the write that credits [amount] points on top of [currentPoints]
  /// (as returned by [readPoints]) within [transaction].
  void commitAward(
    Transaction transaction,
    String uid,
    int currentPoints,
    int amount,
  ) {
    transaction.set(
      _userDoc(uid),
      {'points': currentPoints + amount},
      SetOptions(merge: true),
    );
  }
}
