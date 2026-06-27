import 'package:latlong2/latlong.dart';
import 'crowd_level.dart';

enum SpotType { pool, beach, lake, river }

class MapSpot {
  final String name;
  final LatLng location;
  final SpotType type;
  final CrowdLevel crowd;

  const MapSpot({
    required this.name,
    required this.location,
    required this.type,
    required this.crowd,
  });
}
