import 'package:latlong2/latlong.dart';

const LatLng kDefaultCenter = LatLng(48.8566, 2.3522);
const String kNominatimUserAgent = 'PlageApp/1.0 (com.example.plage_review)';

const List<String> kOverpassMirrors = [
  'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
];

// ── Affluence collaborative ──────────────────────────────────────────────────
/// Distance à un spot en dessous de laquelle l'utilisateur peut y signaler l'affluence.
const double kAffluenceEligibilityRadiusMeters = 60.0;

/// Délai minimum entre deux signalements d'un même utilisateur sur une même zone.
const Duration kAffluenceReportCooldown = Duration(minutes: 30);

/// Fenêtre glissante prise en compte pour calculer l'affluence "actuelle" d'une zone.
const Duration kAffluenceRecentWindow = Duration(hours: 3);

/// Nombre minimum d'échantillons historiques pour afficher une affluence "habituelle".
const int kMinHistoricalSamples = 3;

/// Points gagnés par l'utilisateur pour chaque signalement valide.
const int kAffluencePointsPerReport = 10;

/// Largeur (en heures) des créneaux horaires utilisés pour l'historique d'affluence.
const int kAffluenceHourBucketSize = 2;
