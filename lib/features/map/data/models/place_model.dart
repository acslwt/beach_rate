import 'package:latlong2/latlong.dart';
import '../../domain/entities/place.dart';

class PlaceModel extends Place {
  const PlaceModel({required super.name, required super.location});

  factory PlaceModel.fromJson(Map<String, dynamic> json) => PlaceModel(
        name: json['display_name'] as String,
        location: LatLng(
          double.parse(json['lat'] as String),
          double.parse(json['lon'] as String),
        ),
      );
}
