import '../../../../core/constants/app_constants.dart';
import '../entities/zone_affluence_stats.dart';
import '../repositories/affluence_repository.dart';
import '../zone_affluence_calculator.dart';

class WatchZoneAffluence {
  const WatchZoneAffluence(
    this._repository, {
    this._calculator = const ZoneAffluenceCalculator(),
  });

  final AffluenceRepository _repository;
  final ZoneAffluenceCalculator _calculator;

  Stream<ZoneAffluenceStats> call(String zoneId) {
    return _repository
        .watchRecentReports(zoneId, kAffluenceRecentWindow)
        .asyncMap((reports) async {
      final now = DateTime.now();
      final hourlyStat = await _repository.getHourlyStat(zoneId, now);
      return _calculator.compute(
        zoneId: zoneId,
        recentReports: reports,
        hourlyStat: hourlyStat,
        now: now,
      );
    });
  }
}
