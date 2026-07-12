import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/spot_comment.dart';

class SpotCommentModel extends SpotComment {
  const SpotCommentModel({
    required super.id,
    required super.zoneId,
    required super.userId,
    required super.userName,
    required super.text,
    required super.createdAt,
  });

  factory SpotCommentModel.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String zoneId,
  ) {
    final data = doc.data();
    final createdAt = data['createdAt'] as Timestamp?;
    return SpotCommentModel(
      id: doc.id,
      zoneId: zoneId,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Utilisateur',
      text: data['text'] as String? ?? '',
      // Pending server timestamps read back as null until the write is
      // acknowledged — treat that as "just now".
      createdAt: createdAt?.toDate() ?? DateTime.now(),
    );
  }
}
