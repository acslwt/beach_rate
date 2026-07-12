/// Affluence reported by a user for a zone, on a 0-5 scale.
enum AffluenceLevel {
  empty(0, 'Vide'),
  veryLow(1, 'Très faible'),
  low(2, 'Faible'),
  medium(3, 'Moyenne'),
  high(4, 'Forte'),
  saturated(5, 'Saturée');

  const AffluenceLevel(this.value, this.label);

  final int value;
  final String label;

  static AffluenceLevel fromValue(int value) => AffluenceLevel.values
      .firstWhere((level) => level.value == value, orElse: () => AffluenceLevel.medium);

  /// Nearest level for a continuous 0-5 score (e.g. a computed average).
  static AffluenceLevel fromScore(double score) =>
      fromValue(score.round().clamp(0, 5));
}
