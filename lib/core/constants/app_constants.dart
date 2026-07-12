import 'package:latlong2/latlong.dart';

const LatLng kDefaultCenter = LatLng(48.8566, 2.3522);
const String kNominatimUserAgent = 'PlageApp/1.0 (com.example.plage_review)';

/// Half-width (degrees) of the soft viewbox sent to Nominatim to bias search
/// results toward the user — ~1.5° is roughly 150km, wide enough that a real
/// nearby match outside a tighter box still comes back (it's a preference,
/// not a hard filter: no `bounded=1`).
const double kSearchProximityBiasDegrees = 1.5;

/// How many results to fetch from Nominatim before sorting by distance and
/// trimming to the displayed count — a bigger pool means the nearest match
/// is less likely to be sorted-away by simply not having been fetched.
const int kSearchFetchLimit = 8;

/// How many results are actually shown after sorting by proximity.
const int kSearchDisplayLimit = 5;

/// Minimum movement (meters) before a new live GPS fix triggers a marker
/// update — filters out GPS jitter without needing a debounce timer.
const int kLocationDistanceFilterMeters = 5;

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

// ── Commentaires ──────────────────────────────────────────────────────────────
/// Longueur maximale d'un commentaire.
const int kMaxCommentLength = 300;

/// Nombre de commentaires récents chargés pour un spot.
const int kCommentsFetchLimit = 50;
