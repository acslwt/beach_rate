import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/map_spot.dart';
import '../../domain/entities/place.dart';
import '../../domain/usecases/fetch_spots_in_view.dart';
import '../../domain/usecases/search_places.dart';

class MapStateController extends ChangeNotifier {
  MapStateController({
    required this._searchPlaces,
    required this._fetchSpotsInView,
  });

  final SearchPlaces _searchPlaces;
  final FetchSpotsInView _fetchSpotsInView;

  // ── Map ─────────────────────────────────────────────────────────────────────
  final mapController = MapController();
  LatLng center = kDefaultCenter;
  LatLng? userLocation;
  bool isLocating = true;

  // ── Activity bar ─────────────────────────────────────────────────────────────
  int? selectedActivity;

  // ── Search ───────────────────────────────────────────────────────────────────
  List<Place> places = [];
  bool isSearching = false;
  Timer? _searchDebounce;

  // ── Spots ────────────────────────────────────────────────────────────────────
  List<MapSpot> mapSpots = [];
  String? selectedSpotName;
  Timer? _spotDebounce;

  // ── Lifecycle ─────────────────────────────────────────────────────────────────
  Future<void> init() async {
    await fetchLocation();
  }

  @override
  void dispose() {
    mapController.dispose();
    _searchDebounce?.cancel();
    _spotDebounce?.cancel();
    super.dispose();
  }

  // ── Location ─────────────────────────────────────────────────────────────────
  Future<void> fetchLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return _finishLocating(null);
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return _finishLocating(null);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _finishLocating(LatLng(pos.latitude, pos.longitude));
    } catch (_) {
      _finishLocating(null);
    }
  }

  void _finishLocating(LatLng? loc) {
    userLocation = loc;
    if (loc != null) center = loc;
    isLocating = false;
    notifyListeners();
    if (loc != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mapController.move(loc, 15.0);
      });
    }
  }

  // ── Search ───────────────────────────────────────────────────────────────────
  void onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      places = [];
      isSearching = false;
      notifyListeners();
      return;
    }
    isSearching = true;
    notifyListeners();
    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _doSearch(query),
    );
  }

  Future<void> _doSearch(String query) async {
    try {
      final results = await _searchPlaces(query);
      places = results;
    } catch (_) {
      places = [];
    }
    isSearching = false;
    notifyListeners();
  }

  void tapSuggestion(String keyword, TextEditingController searchCtrl) {
    searchCtrl.text = keyword;
    searchCtrl.selection = TextSelection.collapsed(offset: keyword.length);
    places = [];
    isSearching = true;
    notifyListeners();
    _doSearch(keyword);
  }

  void selectPlace(Place place) {
    mapController.move(place.location, 14.0);
    places = [];
    notifyListeners();
    HapticFeedback.selectionClick();
  }

  void clearSearch() {
    places = [];
    isSearching = false;
    notifyListeners();
  }

  // ── Activity ─────────────────────────────────────────────────────────────────
  void toggleActivity(int index) {
    selectedActivity = selectedActivity == index ? null : index;
    notifyListeners();
    HapticFeedback.selectionClick();
  }

  // ── Spots ────────────────────────────────────────────────────────────────────
  void scheduleSpotFetch() {
    _spotDebounce?.cancel();
    _spotDebounce =
        Timer(const Duration(milliseconds: 700), fetchSpotsInView);
  }

  Future<void> fetchSpotsInView() async {
    try {
      final bounds = mapController.camera.visibleBounds;
      final spots = await _fetchSpotsInView(
        south: bounds.south,
        west:  bounds.west,
        north: bounds.north,
        east:  bounds.east,
      );
      mapSpots = spots;
      if (!spots.any((s) => s.name == selectedSpotName)) {
        selectedSpotName = null;
      }
      notifyListeners();
    } catch (_) {
      // Camera not ready yet — will retry on next map move.
    }
  }

  void toggleSpot(String name) {
    selectedSpotName = selectedSpotName == name ? null : name;
    notifyListeners();
  }

  void clearSelectedSpot() {
    selectedSpotName = null;
    notifyListeners();
  }
}
