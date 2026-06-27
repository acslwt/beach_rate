import '../entities/place.dart';

abstract interface class PlaceRepository {
  Future<List<Place>> searchPlaces(String query);
}
