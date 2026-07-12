import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/map_state_controller.dart';
import '../widgets/spot_marker.dart';
import '../widgets/user_marker.dart';

const _mapAttributions = [
  TextSourceAttribution('OpenStreetMap contributors'),
];

class MapView extends StatelessWidget {
  const MapView({
    super.key,
    required this.controller,
    required this.onTap,
    required this.onPositionChanged,
    this.liveLevelForSpot,
  });

  final MapStateController controller;
  final void Function(TapPosition, LatLng) onTap;
  final void Function(MapCamera, bool) onPositionChanged;

  /// Looks up the live affluence level (0-5) for a spot id, when available.
  /// Kept as an injected callback so this feature doesn't depend on `affluence`.
  final double? Function(String spotId)? liveLevelForSpot;

  @override
  Widget build(BuildContext context) {
    final style = controller.mapStyle;
    if (style == null) {
      return const ColoredBox(
        color: appMapBackground,
        child: Center(child: CircularProgressIndicator(color: appCoral)),
      );
    }

    return FlutterMap(
      mapController: controller.mapController,
      options: MapOptions(
        initialCenter: controller.center,
        initialZoom: 15.0,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
        backgroundColor: appMapBackground,
        onTap: onTap,
        onPositionChanged: onPositionChanged,
      ),
      children: [
        VectorTileLayer(
          theme: style.theme,
          sprites: style.sprites,
          tileProviders: style.providers,
        ),
        MarkerLayer(
          markers: controller.mapSpots.map((spot) {
            final liveLevel = liveLevelForSpot?.call(spot.id);
            final zoneSize = liveLevel != null
                ? SpotMarker.zoneSizeForLevel(liveLevel)
                : SpotMarker.zoneSize(spot.crowd);
            final size = zoneSize + 24;
            return Marker(
              point: spot.location,
              width: size,
              height: size,
              alignment: Alignment.center,
              child: SpotMarker(
                spot: spot,
                selected: controller.selectedSpotName == spot.name,
                onTap: () => controller.toggleSpot(spot.name),
                liveLevel: liveLevel,
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
        const RichAttributionWidget(attributions: _mapAttributions),
      ],
    );
  }
}
