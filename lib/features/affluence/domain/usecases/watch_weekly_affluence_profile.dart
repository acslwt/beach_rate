import '../entities/hourly_affluence_stat.dart';
import '../repositories/affluence_repository.dart';

class WatchWeeklyAffluenceProfile {
  const WatchWeeklyAffluenceProfile(this._repository);

  final AffluenceRepository _repository;

  Stream<Map<String, HourlyAffluenceStat>> call(String zoneId) =>
      _repository.watchWeeklyProfile(zoneId);
}
