import '../../domain/entities/map_spot.dart';
import '../../domain/repositories/map_spot_repository.dart';
import '../datasources/overpass_datasource.dart';

class MapSpotRepositoryImpl implements MapSpotRepository {
  const MapSpotRepositoryImpl(this._datasource);

  final OverpassDatasource _datasource;

  @override
  Future<List<MapSpot>> fetchSpotsInBounds({
    required double south,
    required double west,
    required double north,
    required double east,
  }) =>
      _datasource.fetchSpots(
        south: south.toStringAsFixed(5),
        west:  west.toStringAsFixed(5),
        north: north.toStringAsFixed(5),
        east:  east.toStringAsFixed(5),
      );
}
