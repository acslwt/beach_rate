import '../entities/map_spot.dart';

abstract interface class MapSpotRepository {
  Future<List<MapSpot>> fetchSpotsInBounds({
    required double south,
    required double west,
    required double north,
    required double east,
  });
}
