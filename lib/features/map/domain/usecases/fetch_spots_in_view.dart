import '../entities/map_spot.dart';
import '../repositories/map_spot_repository.dart';

class FetchSpotsInView {
  const FetchSpotsInView(this._repository);

  final MapSpotRepository _repository;

  Future<List<MapSpot>> call({
    required double south,
    required double west,
    required double north,
    required double east,
  }) =>
      _repository.fetchSpotsInBounds(
        south: south,
        west: west,
        north: north,
        east: east,
      );
}
