import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/map_state_controller.dart';
import '../widgets/spot_marker.dart';
import '../widgets/user_marker.dart';

class MapView extends StatelessWidget {
  const MapView({
    super.key,
    required this.controller,
    required this.onTap,
    required this.onPositionChanged,
  });

  final MapStateController controller;
  final void Function(TapPosition, LatLng) onTap;
  final void Function(MapCamera, bool) onPositionChanged;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller.mapController,
      options: MapOptions(
        initialCenter: controller.center,
        initialZoom: 15.0,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
        onTap: onTap,
        onPositionChanged: onPositionChanged,
      ),
      children: [
        TileLayer(
          urlTemplate: kOsmTileTemplate,
          userAgentPackageName: kOsmPackageName,
          maxZoom: 19,
        ),
        MarkerLayer(
          markers: controller.mapSpots.map((spot) {
            final size = SpotMarker.zoneSize(spot.crowd) + 24;
            return Marker(
              point: spot.location,
              width: size,
              height: size,
              alignment: Alignment.center,
              child: SpotMarker(
                spot: spot,
                selected: controller.selectedSpotName == spot.name,
                onTap: () => controller.toggleSpot(spot.name),
              ),
            );
          }).toList(),
        ),
        if (controller.userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: controller.userLocation!,
                width: 90,
                height: 140,
                alignment: Alignment.center,
                child: const UserMarker(),
              ),
            ],
          ),
      ],
    );
  }
}
