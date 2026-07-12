import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:plage_review/features/affluence/domain/eligibility.dart';
import 'package:plage_review/features/affluence/domain/entities/nearby_spot.dart';

void main() {
  const userLocation = LatLng(43.2965, 5.3698);

  test('returns the nearest spot within the eligibility radius', () {
    const near = NearbySpot(
      id: 'near',
      name: 'Plage proche',
      location: LatLng(43.29655, 5.36985),
    );
    const far = NearbySpot(
      id: 'far',
      name: 'Plage loin',
      location: LatLng(43.31, 5.40),
    );

    final result = nearestEligibleSpot(userLocation, [far, near], radiusMeters: 60);

    expect(result?.id, 'near');
  });

  test('returns null when no spot is within radius', () {
    const far = NearbySpot(
      id: 'far',
      name: 'Plage loin',
      location: LatLng(43.31, 5.40),
    );

    final result = nearestEligibleSpot(userLocation, [far], radiusMeters: 60);

    expect(result, isNull);
  });

  test('returns null when there are no spots', () {
    final result = nearestEligibleSpot(userLocation, const [], radiusMeters: 60);

    expect(result, isNull);
  });
}
