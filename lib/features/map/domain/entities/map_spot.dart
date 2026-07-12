import 'package:latlong2/latlong.dart';
import 'crowd_level.dart';

enum SpotType { pool, beach, lake, river }

class MapSpot {
  /// Stable identity for this spot, e.g. `"node/123456"`. Used as the
  /// affluence zone key so live reports and this spot stay attached to the
  /// same real-world place across re-fetches.
  final String id;
  final String name;
  final LatLng location;
  final SpotType type;
  final CrowdLevel crowd;

  const MapSpot({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.crowd,
  });
}
