import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/services/user_points_service.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../data/datasources/nominatim_datasource.dart';
import '../../data/datasources/overpass_datasource.dart';
import '../../data/datasources/firestore_community_spot_datasource.dart';
import '../../data/repositories/community_spot_repository_impl.dart';
import '../../data/repositories/map_spot_repository_impl.dart';
import '../../data/repositories/place_repository_impl.dart';
import '../../domain/entities/cool_spot.dart';
import '../../domain/entities/crowd_level.dart';
import '../../domain/entities/map_spot.dart';
import '../../domain/repositories/community_spot_repository.dart';
import '../../domain/usecases/create_community_spot.dart';
import '../../domain/usecases/fetch_spots_in_view.dart';
import '../../domain/usecases/search_places.dart';
import '../../domain/usecases/watch_community_spots.dart';
import '../controllers/map_state_controller.dart';
import '../widgets/activity_bar.dart';
import '../widgets/add_spot_button.dart';
import '../widgets/add_spot_form.dart';
import '../widgets/map_view.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/search_dropdown.dart';
import '../widgets/weather_pill.dart';
import '../../../auth/data/datasources/firebase_auth_datasource.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/usecases/sign_in_usecase.dart';
import '../../../auth/domain/usecases/sign_in_with_google_usecase.dart';
import '../../../auth/domain/usecases/sign_out_usecase.dart';
import '../../../auth/domain/usecases/sign_up_usecase.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/widgets/profile_button.dart';
import '../../../affluence/data/datasources/firestore_affluence_datasource.dart'
    show FirestoreAffluenceDatasource, firestoreZoneDocId;
import '../../../affluence/data/repositories/affluence_repository_impl.dart';
import '../../../affluence/domain/entities/nearby_spot.dart';
import '../../../affluence/domain/usecases/submit_affluence_report.dart';
import '../../../affluence/domain/usecases/watch_weekly_affluence_profile.dart';
import '../../../affluence/domain/usecases/watch_zone_affluence.dart';
import '../../../affluence/presentation/controllers/affluence_controller.dart';
import '../../../affluence/presentation/widgets/affluence_card.dart';
import '../../../affluence/presentation/widgets/affluence_history_chart.dart';
import '../../../affluence/presentation/widgets/report_affluence_button.dart';

const List<CoolSpot> _kCoolSpots = [
  CoolSpot(
    name: 'Plages',
    description: '5 proche',
    query: 'plage',
    backgroundColor: Color(0xFFFFF0CC),
    type: SpotType.beach,
    iconColor: Color(0xFFD4820A),
    crowd: CrowdLevel.medium,
  ),
  CoolSpot(
    name: 'Lacs',
    description: '12 proche',
    query: 'lac',
    backgroundColor: Color(0xFFD5F5E3),
    type: SpotType.lake,
    iconColor: Color(0xFF2D8653),
    crowd: CrowdLevel.calm,
  ),
  CoolSpot(
    name: 'Rivières',
    description: '6 proche',
    query: 'rivière',
    backgroundColor: Color(0xFFD0EAF0),
    type: SpotType.river,
    iconColor: Color(0xFF2E7D9B),
    crowd: CrowdLevel.medium,
  ),
];

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final MapStateController _ctrl;
  late final AuthController _authCtrl;
  late final AffluenceController _affluenceCtrl;
  late final UserPointsService _pointsService;
  late final CreateCommunitySpot _createCommunitySpot;
  late final WatchWeeklyAffluenceProfile _watchWeeklyAffluenceProfile;
  final _points = ValueNotifier<int>(0);
  StreamSubscription<int>? _pointsSub;
  final _searchCtrl  = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();

    final authDataSource = FirebaseAuthDataSourceImpl();
    final authRepository = AuthRepositoryImpl(authDataSource);
    _authCtrl = AuthController(
      repository: authRepository,
      signIn: SignInUseCase(authRepository),
      signUp: SignUpUseCase(authRepository),
      signInWithGoogle: SignInWithGoogleUseCase(authRepository),
      signOut: SignOutUseCase(authRepository),
    );

    final client = http.Client();
    final CommunitySpotRepository communitySpotRepository = CommunitySpotRepositoryImpl(
      FirestoreCommunitySpotDatasource(FirebaseFirestore.instance),
    );
    _createCommunitySpot = CreateCommunitySpot(communitySpotRepository);

    _ctrl = MapStateController(
      searchPlaces: SearchPlaces(
        PlaceRepositoryImpl(NominatimDatasource(client)),
      ),
      fetchSpotsInView: FetchSpotsInView(
        MapSpotRepositoryImpl(OverpassDatasource(client)),
      ),
      watchCommunitySpots: WatchCommunitySpots(communitySpotRepository),
    );

    _pointsService = UserPointsService();
    final affluenceRepository = AffluenceRepositoryImpl(
      FirestoreAffluenceDatasource(FirebaseFirestore.instance, _pointsService),
    );
    _affluenceCtrl = AffluenceController(
      repository: affluenceRepository,
      submitAffluenceReport: SubmitAffluenceReport(affluenceRepository),
      watchZoneAffluence: WatchZoneAffluence(affluenceRepository),
    );
    _watchWeeklyAffluenceProfile = WatchWeeklyAffluenceProfile(affluenceRepository);

    _searchFocus.addListener(
      () => setState(() => _searchFocused = _searchFocus.hasFocus),
    );
    _searchCtrl.addListener(() => setState(() {}));

    _authCtrl.addListener(_syncUser);
    _ctrl.addListener(_syncAffluenceContext);
    _syncUser();

    _ctrl.init().then((_) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _ctrl.fetchSpotsInView(),
        );
      }
    });
  }

  void _syncUser() {
    final profile = _authCtrl.profile;
    _affluenceCtrl.setUser(profile?.uid);
    _pointsSub?.cancel();
    if (profile == null) {
      _points.value = 0;
      return;
    }
    _pointsSub = _pointsService.watchPoints(profile.uid).listen((value) {
      _points.value = value;
    });
  }

  void _syncAffluenceContext() {
    _affluenceCtrl.updateContext(
      userLocation: _ctrl.userLocation,
      spots: _ctrl.mapSpots
          .map((s) => NearbySpot(id: s.id, name: s.name, location: s.location))
          .toList(),
    );
  }

  MapSpot? _spotByName(String? name) {
    if (name == null) return null;
    for (final spot in _ctrl.mapSpots) {
      if (spot.name == name) return spot;
    }
    return null;
  }

  Future<bool> _submitNewSpot(String name, SpotType type) async {
    final location = _ctrl.userLocation;
    final userId = _authCtrl.profile?.uid;
    if (location == null || userId == null) return false;
    try {
      await _createCommunitySpot(
        name: name,
        type: type,
        location: location,
        userId: userId,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void _showAddSpotForm() {
    showAppModal(
      context,
      (ctx) => AddSpotForm(
        loggedIn: _authCtrl.loggedIn,
        onSubmit: _submitNewSpot,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showHistoryChart(MapSpot spot) {
    showAppModal(
      context,
      (ctx) => AffluenceHistoryChart(
        spotName: spot.name,
        zoneId: spot.id,
        watchWeeklyProfile: _watchWeeklyAffluenceProfile,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.removeListener(_syncAffluenceContext);
    _authCtrl.removeListener(_syncUser);
    _pointsSub?.cancel();
    _points.dispose();
    _affluenceCtrl.dispose();
    _ctrl.dispose();
    _authCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _clearAndUnfocus() {
    _searchCtrl.clear();
    _searchFocus.unfocus();
    _ctrl.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: ListenableBuilder(
        listenable: Listenable.merge([_ctrl, _affluenceCtrl]),
        builder: (context, child) => Stack(
          fit: StackFit.expand,
          children: [
            MapView(
              controller: _ctrl,
              onTap: (tapPos, point) {
                _searchFocus.unfocus();
                _ctrl.clearSelectedSpot();
              },
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) _searchFocus.unfocus();
                _ctrl.scheduleSpotFetch();
              },
              liveLevelForSpot: _affluenceCtrl.liveLevelForSpot,
            ),
            _buildTopOverlay(),
            _buildBottomOverlay(),
            ActivityBar(controller: _ctrl),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    final selectedSpot = _spotByName(_ctrl.selectedSpotName);
    final canAddSpot = _ctrl.userLocation != null && _affluenceCtrl.eligibleSpot == null;
    // Bottom offset must clear ActivityBar's own height (28 padding + ~82
    // button) *inside* the same SafeArea it uses — a raw Positioned bottom
    // value ignores the device's safe-area inset (home indicator / gesture
    // bar) and drifts into the activity buttons on devices that have one.
    return Positioned(
      left: 16,
      right: 16,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 126),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedSpot != null) ...[
                AffluenceCard(
                  spotName: selectedSpot.name,
                  zoneId: firestoreZoneDocId(selectedSpot.id),
                  stats: _affluenceCtrl.statsForZone(selectedSpot.id),
                  onClose: _ctrl.clearSelectedSpot,
                  onShowHistory: () => _showHistoryChart(selectedSpot),
                ),
                const SizedBox(height: 10),
              ],
              if (canAddSpot)
                AddSpotButton(onTap: _showAddSpotForm)
              else
                ReportAffluenceButton(controller: _affluenceCtrl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: SearchBarWidget(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      isFocused: _searchFocused,
                      onChanged: _ctrl.onSearchChanged,
                      onSubmitted: (q) => _ctrl.onSearchChanged(q),
                      onClear: _clearAndUnfocus,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ProfileButton(controller: _authCtrl, points: _points),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: SearchDropdown(
                  isFocused: _searchFocused,
                  hasQuery: _searchCtrl.text.isNotEmpty,
                  isSearching: _ctrl.isSearching,
                  places: _ctrl.places,
                  coolSpots: _kCoolSpots,
                  onSuggestionTap: (keyword) =>
                      _ctrl.tapSuggestion(keyword, _searchCtrl),
                  onPlaceTap: (place) {
                    _ctrl.selectPlace(place);
                    _clearAndUnfocus();
                  },
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: const WeatherPill(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
