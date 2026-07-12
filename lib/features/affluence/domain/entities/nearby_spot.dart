import 'package:latlong2/latlong.dart';

/// Minimal spot info the affluence feature needs to evaluate report
/// eligibility and identify a zone — kept independent from the `map`
/// feature's own `MapSpot` entity so neither feature depends on the other's
/// domain layer. The composition root (`MapPage`) maps between the two.
class NearbySpot {
  final String id;
  final String name;
  final LatLng location;

  const NearbySpot({
    required this.id,
    required this.name,
    required this.location,
  });
}
