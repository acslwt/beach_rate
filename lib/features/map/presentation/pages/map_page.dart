import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/nominatim_datasource.dart';
import '../../data/datasources/overpass_datasource.dart';
import '../../data/repositories/map_spot_repository_impl.dart';
import '../../data/repositories/place_repository_impl.dart';
import '../../domain/entities/cool_spot.dart';
import '../../domain/entities/crowd_level.dart';
import '../../domain/entities/map_spot.dart';
import '../../domain/usecases/fetch_spots_in_view.dart';
import '../../domain/usecases/search_places.dart';
import '../controllers/map_state_controller.dart';
import '../widgets/activity_bar.dart';
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
    _ctrl = MapStateController(
      searchPlaces: SearchPlaces(
        PlaceRepositoryImpl(NominatimDatasource(client)),
      ),
      fetchSpotsInView: FetchSpotsInView(
        MapSpotRepositoryImpl(OverpassDatasource(client)),
      ),
    );

    _searchFocus.addListener(
      () => setState(() => _searchFocused = _searchFocus.hasFocus),
    );
    _searchCtrl.addListener(() => setState(() {}));

    _ctrl.init().then((_) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _ctrl.fetchSpotsInView(),
        );
      }
    });
  }

  @override
  void dispose() {
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
        listenable: _ctrl,
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
            ),
            _buildTopOverlay(),
            ActivityBar(controller: _ctrl),
          ],
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
                  ProfileButton(controller: _authCtrl),
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
