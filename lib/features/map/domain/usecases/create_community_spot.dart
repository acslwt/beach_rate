import 'package:latlong2/latlong.dart';
import '../entities/map_spot.dart';
import '../repositories/community_spot_repository.dart';

class CreateCommunitySpot {
  const CreateCommunitySpot(this._repository);

  final CommunitySpotRepository _repository;

  Future<void> call({
    required String name,
    required SpotType type,
    required LatLng location,
    required String userId,
  }) =>
      _repository.createSpot(
        name: name,
        type: type,
        location: location,
        userId: userId,
      );
}
