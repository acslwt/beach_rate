import '../entities/map_spot.dart';
import '../repositories/community_spot_repository.dart';

class WatchCommunitySpots {
  const WatchCommunitySpots(this._repository);

  final CommunitySpotRepository _repository;

  Stream<List<MapSpot>> call() => _repository.watchSpots();
}
