import 'package:latlong2/latlong.dart';
import '../entities/place.dart';

abstract interface class PlaceRepository {
  /// [near], when given, biases results toward that location.
  Future<List<Place>> searchPlaces(String query, {LatLng? near});
}
