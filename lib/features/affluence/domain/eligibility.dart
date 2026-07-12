import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import 'entities/nearby_spot.dart';

const _distance = Distance();

/// The nearest spot within [radiusMeters] of [userLocation], or `null` if
/// none is close enough — pure function, easy to unit test.
NearbySpot? nearestEligibleSpot(
  LatLng userLocation,
  List<NearbySpot> spots, {
  double radiusMeters = kAffluenceEligibilityRadiusMeters,
}) {
  NearbySpot? closest;
  var closestDistance = double.infinity;
  for (final spot in spots) {
    final d = _distance.as(LengthUnit.Meter, userLocation, spot.location);
    if (d <= radiusMeters && d < closestDistance) {
      closest = spot;
      closestDistance = d;
    }
  }
  return closest;
}
