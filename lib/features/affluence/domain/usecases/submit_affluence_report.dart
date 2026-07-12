import '../entities/affluence_level.dart';
import '../repositories/affluence_repository.dart';

class SubmitAffluenceReport {
  const SubmitAffluenceReport(this._repository);

  final AffluenceRepository _repository;

  /// Throws [AffluenceCooldownException] if the user is still in cooldown.
  Future<void> call({
    required String zoneId,
    required String userId,
    required AffluenceLevel level,
  }) =>
      _repository.submitReport(zoneId: zoneId, userId: userId, level: level);
}
