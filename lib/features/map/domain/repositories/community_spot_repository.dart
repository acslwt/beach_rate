import 'package:latlong2/latlong.dart';
import '../entities/map_spot.dart';

/// Spots added by users at their own location (e.g. pools, which OSM/Overpass
/// never returns — see `overpass_datasource.dart`'s `water!=pool` filter).
abstract interface class CommunitySpotRepository {
  /// All community spots, updated live as other users add new ones.
  Stream<List<MapSpot>> watchSpots();

  Future<void> createSpot({
    required String name,
    required SpotType type,
    required LatLng location,
    required String userId,
  });
}
