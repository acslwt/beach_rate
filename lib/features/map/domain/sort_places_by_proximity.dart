import 'package:latlong2/latlong.dart';
import 'entities/place.dart';

const _distance = Distance();

/// Nearest-first ordering of [places] relative to [from]. Pure & testable —
/// mirrors the geo-helper pattern already used in
/// `affluence/domain/eligibility.dart`.
List<Place> sortPlacesByProximity(List<Place> places, LatLng from) {
  final withDistance = places
      .map((p) => (place: p, meters: _distance.as(LengthUnit.Meter, from, p.location)))
      .toList()
    ..sort((a, b) => a.meters.compareTo(b.meters));
  return withDistance.map((e) => e.place).toList();
}
