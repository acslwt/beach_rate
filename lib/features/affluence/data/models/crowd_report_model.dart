import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/affluence_level.dart';
import '../../domain/entities/crowd_report.dart';

class CrowdReportModel extends CrowdReport {
  const CrowdReportModel({
    required super.id,
    required super.zoneId,
    required super.userId,
    required super.level,
    required super.createdAt,
  });

  factory CrowdReportModel.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String zoneId,
  ) {
    final data = doc.data();
    final createdAt = data['createdAt'] as Timestamp?;
    return CrowdReportModel(
      id: doc.id,
      zoneId: zoneId,
      userId: data['userId'] as String? ?? '',
      level: AffluenceLevel.fromValue((data['level'] as num?)?.toInt() ?? 0),
      // Pending server timestamps read back as null until the write is
      // acknowledged — treat that as "just now".
      createdAt: createdAt?.toDate() ?? DateTime.now(),
    );
  }
}
