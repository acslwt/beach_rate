import '../entities/place.dart';
import '../repositories/place_repository.dart';

class SearchPlaces {
  const SearchPlaces(this._repository);

  final PlaceRepository _repository;

  Future<List<Place>> call(String query) => _repository.searchPlaces(query);
}
