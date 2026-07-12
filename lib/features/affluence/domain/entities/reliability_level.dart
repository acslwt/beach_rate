/// How much the current [ZoneAffluenceStats.currentLevel] can be trusted,
/// derived from how many (and how consistent) recent reports back it up.
enum ReliabilityLevel {
  insufficient('Données insuffisantes'),
  low('Fiabilité faible'),
  medium('Fiabilité moyenne'),
  high('Fiabilité élevée');

  const ReliabilityLevel(this.label);

  final String label;
}
