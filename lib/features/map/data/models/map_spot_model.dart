import 'package:latlong2/latlong.dart';
import '../../domain/entities/crowd_level.dart';
import '../../domain/entities/map_spot.dart';

class MapSpotModel extends MapSpot {
  const MapSpotModel({
    required super.name,
    required super.location,
    required super.type,
    required super.crowd,
  });

  /// Returns null if the element cannot be mapped to a known spot type.
  static MapSpotModel? fromOverpassElement(Map<String, dynamic> element) {
    final tags = (element['tags'] as Map<String, dynamic>?) ?? {};
    final natural  = tags['natural']  as String?;
    final waterway = tags['waterway'] as String?;
    final waterTag = tags['water']    as String?;

    final SpotType type;
    if (natural == 'beach') {
      type = SpotType.beach;
    } else if (natural == 'water') {
      type = (waterTag == 'river' || waterTag == 'stream')
          ? SpotType.river
          : SpotType.lake;
    } else if (waterway == 'river') {
      type = SpotType.river;
    } else {
      return null;
    }

    final double? lat;
    final double? lon;
    if (element['type'] == 'node') {
      lat = (element['lat'] as num?)?.toDouble();
      lon = (element['lon'] as num?)?.toDouble();
    } else {
      final center = element['center'] as Map<String, dynamic>?;
      lat = (center?['lat'] as num?)?.toDouble();
      lon = (center?['lon'] as num?)?.toDouble();
    }
    if (lat == null || lon == null) return null;

    final name = (tags['name'] as String?) ??
        switch (type) {
          SpotType.beach => 'Plage',
          SpotType.lake  => 'Lac',
          SpotType.river => 'Rivière',
          SpotType.pool  => 'Piscine',
        };

    return MapSpotModel(
      name: name,
      location: LatLng(lat, lon),
      type: type,
      crowd: CrowdLevel.calm,
    );
  }
}
