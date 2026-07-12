import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../entities/place.dart';
import '../repositories/place_repository.dart';
import '../sort_places_by_proximity.dart';

class SearchPlaces {
  const SearchPlaces(this._repository);

  final PlaceRepository _repository;

  /// Searches [query], biased toward [near] when known, and returns the
  /// [kSearchDisplayLimit] nearest matches (nearest first).
  Future<List<Place>> call(String query, {LatLng? near}) async {
    final results = await _repository.searchPlaces(query, near: near);
    final ordered = near != null ? sortPlacesByProximity(results, near) : results;
    return ordered.take(kSearchDisplayLimit).toList();
  }
}
