import '../../domain/entities/place.dart';
import '../../domain/repositories/place_repository.dart';
import '../datasources/nominatim_datasource.dart';

class PlaceRepositoryImpl implements PlaceRepository {
  const PlaceRepositoryImpl(this._datasource);

  final NominatimDatasource _datasource;

  @override
  Future<List<Place>> searchPlaces(String query) =>
      _datasource.search(query);
}
