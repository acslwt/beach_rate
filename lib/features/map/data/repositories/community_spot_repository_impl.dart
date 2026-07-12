import 'package:latlong2/latlong.dart';
import '../../domain/entities/map_spot.dart';
import '../../domain/repositories/community_spot_repository.dart';
import '../datasources/firestore_community_spot_datasource.dart';
import '../models/community_spot_model.dart';

class CommunitySpotRepositoryImpl implements CommunitySpotRepository {
  const CommunitySpotRepositoryImpl(this._datasource);

  final FirestoreCommunitySpotDatasource _datasource;

  @override
  Stream<List<MapSpot>> watchSpots() => _datasource.watchSpots().map(
        (snapshot) => snapshot.docs.map(CommunitySpotModel.fromDoc).toList(),
      );

  @override
  Future<void> createSpot({
    required String name,
    required SpotType type,
    required LatLng location,
    required String userId,
  }) =>
      _datasource.createSpot(
        CommunitySpotModel.toCreatePayload(
          name: name,
          type: type,
          location: location,
          userId: userId,
        ),
      );
}
