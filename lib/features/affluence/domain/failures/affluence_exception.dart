/// Thrown by [AffluenceRepository.submitReport] when the user already
/// reported on this zone within [kAffluenceReportCooldown].
class AffluenceCooldownException implements Exception {
  const AffluenceCooldownException(this.remaining);

  final Duration remaining;
}
