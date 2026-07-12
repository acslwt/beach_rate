import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:plage_review/features/map/domain/entities/place.dart';
import 'package:plage_review/features/map/domain/sort_places_by_proximity.dart';

void main() {
  // Roughly Marseille.
  const from = LatLng(43.2965, 5.3698);

  test('orders places nearest-first regardless of input order', () {
    const far = Place(name: 'Plage lointaine', location: LatLng(45.75, 4.85)); // ~Lyon
    const near = Place(name: 'Plage proche', location: LatLng(43.30, 5.37));
    const mid = Place(name: 'Plage moyenne', location: LatLng(43.50, 5.10));

    final result = sortPlacesByProximity([far, mid, near], from);

    expect(result.map((p) => p.name), ['Plage proche', 'Plage moyenne', 'Plage lointaine']);
  });

  test('does not mutate the input list', () {
    const a = Place(name: 'A', location: LatLng(44.0, 5.0));
    const b = Place(name: 'B', location: LatLng(43.30, 5.37));
    final input = [a, b];

    sortPlacesByProximity(input, from);

    expect(input, [a, b]);
  });

  test('a single place is trivially "sorted"', () {
    const only = Place(name: 'Seule', location: LatLng(43.31, 5.40));

    final result = sortPlacesByProximity([only], from);

    expect(result, [only]);
  });
}
