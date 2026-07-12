import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/hourly_affluence_stat.dart';

class HourlyAffluenceStatModel extends HourlyAffluenceStat {
  const HourlyAffluenceStatModel({
    required super.avgLevel,
    required super.sampleCount,
    required super.lastUpdated,
  });

  factory HourlyAffluenceStatModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final lastUpdated = data['lastUpdated'] as Timestamp?;
    return HourlyAffluenceStatModel(
      avgLevel: (data['avgLevel'] as num?)?.toDouble() ?? 0,
      sampleCount: (data['sampleCount'] as num?)?.toInt() ?? 0,
      lastUpdated: lastUpdated?.toDate() ?? DateTime.now(),
    );
  }
}
