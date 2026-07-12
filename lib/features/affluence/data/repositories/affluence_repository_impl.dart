import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/affluence_level.dart';
import '../../domain/entities/crowd_report.dart';
import '../../domain/entities/hourly_affluence_stat.dart';
import '../../domain/failures/affluence_exception.dart';
import '../../domain/repositories/affluence_repository.dart';
import '../datasources/firestore_affluence_datasource.dart';
import '../models/crowd_report_model.dart';
import '../models/hourly_stat_model.dart';

class AffluenceRepositoryImpl implements AffluenceRepository {
  const AffluenceRepositoryImpl(this._datasource);

  final FirestoreAffluenceDatasource _datasource;

  @override
  Stream<List<CrowdReport>> watchRecentReports(String zoneId, Duration window) {
    final since = DateTime.now().subtract(window);
    return _datasource.watchRecentReports(zoneId, since).map(
          (snapshot) => snapshot.docs
              .map((doc) => CrowdReportModel.fromDoc(doc, zoneId))
              .toList(),
        );
  }

  @override
  Future<HourlyAffluenceStat?> getHourlyStat(String zoneId, DateTime at) async {
    final doc = await _datasource.getHourlyStatDoc(zoneId, _bucketKeyFor(at));
    if (!doc.exists) return null;
    return HourlyAffluenceStatModel.fromDoc(doc);
  }

  @override
  Stream<Map<String, HourlyAffluenceStat>> watchWeeklyProfile(String zoneId) {
    return _datasource.watchAllHourlyStats(zoneId).map((snapshot) {
      final profile = <String, HourlyAffluenceStat>{};
      for (final doc in snapshot.docs) {
        profile[doc.id] = HourlyAffluenceStatModel.fromDoc(doc);
      }
      return profile;
    });
  }

  @override
  Future<DateTime?> lastReportTime(String zoneId, String userId) async {
    final snapshot = await _datasource.lastReportForUser(zoneId, userId);
    if (snapshot.docs.isEmpty) return null;
    final createdAt = snapshot.docs.first.data()['createdAt'] as Timestamp?;
    return createdAt?.toDate();
  }

  @override
  Future<void> submitReport({
    required String zoneId,
    required String userId,
    required AffluenceLevel level,
  }) async {
    final last = await lastReportTime(zoneId, userId);
    if (last != null) {
      final elapsed = DateTime.now().difference(last);
      if (elapsed < kAffluenceReportCooldown) {
        throw AffluenceCooldownException(kAffluenceReportCooldown - elapsed);
      }
    }
    await _datasource.submitReport(
      zoneId: zoneId,
      userId: userId,
      level: level.value,
      bucketKey: _bucketKeyFor(DateTime.now()),
    );
  }

  String _bucketKeyFor(DateTime dt) =>
      '${dt.weekday}_${dt.hour ~/ kAffluenceHourBucketSize}';
}
