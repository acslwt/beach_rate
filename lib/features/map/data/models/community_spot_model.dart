import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/crowd_level.dart';
import '../../domain/entities/map_spot.dart';

class CommunitySpotModel extends MapSpot {
  const CommunitySpotModel({
    required super.id,
    required super.name,
    required super.location,
    required super.type,
    required super.crowd,
  });

  factory CommunitySpotModel.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final typeIndex =
        (data['type'] as num?)?.toInt().clamp(0, SpotType.values.length - 1) ?? 1;
    return CommunitySpotModel(
      // Prefixed so it can never collide with an OSM-derived MapSpot.id.
      id: 'community/${doc.id}',
      name: (data['name'] as String?) ?? 'Spot',
      location: LatLng(
        (data['lat'] as num).toDouble(),
        (data['lng'] as num).toDouble(),
      ),
      type: SpotType.values[typeIndex],
      crowd: CrowdLevel.calm,
    );
  }

  static Map<String, dynamic> toCreatePayload({
    required String name,
    required SpotType type,
    required LatLng location,
    required String userId,
  }) =>
      {
        'name': name,
        'type': type.index,
        'lat': location.latitude,
        'lng': location.longitude,
        'createdBy': userId,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
