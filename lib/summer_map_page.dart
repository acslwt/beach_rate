import 'dart:async';
import 'dart:convert';
import 'dart:math' show cos, sin, pi;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Design tokens — Playful Minimalist palette
// ─────────────────────────────────────────────────────────────────────────────
const Color _coral     = Color(0xFFFF8C69); // primary: button, accents, marker
const Color _peach     = Color(0xFFFFDDD0); // button hover / chip tints
const Color _cream     = Color(0xFFFFF8F5); // card / pill background
const Color _inkDark   = Color(0xFF2C2C2C); // main text
const Color _inkMid    = Color(0xFFADB5BD); // hints, secondary text, icons
const Color _divider   = Color(0xFFF0EDE8); // list dividers

// Weather pill
const Color _sunYellow  = Color(0xFFF7C948);
const Color _tempGrey   = Color(0xFF8A9377);
const Color _warmOrange = Color(0xFFE0976C);

// Search bar — Playful Minimalist
const Color _searchGrey   = Color(0xFF9AA088);
const Color _fmGreen      = Color(0xFF2E8B57);
const Color _fmDark       = Color(0xFF2B2E26);
const Color _clearBg      = Color(0xFFF0F1E6);
const Color _clearIconCol = Color(0xFF7A8169);
const Color _sectionHead  = Color(0xFFA7AD95);
const Color _suggHover    = Color(0xFFF5F6EC);
const Color _crowdGreen   = Color(0xFF2FA76B);
const Color _crowdOrange  = Color(0xFFE59B36);
const Color _crowdRed     = Color(0xFFE0786C);

const LatLng _defaultCenter = LatLng(48.8566, 2.3522);

// ─────────────────────────────────────────────────────────────────────────────
//  Model
// ─────────────────────────────────────────────────────────────────────────────
class _Place {
  final String name;
  final double lat;
  final double lon;
  const _Place(this.name, this.lat, this.lon);
}

enum _Crowd { calm, medium, busy }

class _CoolSpot {
  final String name;
  final String description;
  final String query;
  final Color bg;
  final int iconType; // 0=pool 1=beach 2=lake 3=river
  final Color iconColor;
  final _Crowd crowd;
  const _CoolSpot(this.name, this.description, this.query, this.bg,
      this.iconType, this.iconColor, this.crowd);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Page
// ─────────────────────────────────────────────────────────────────────────────
class SummerMapPage extends StatefulWidget {
  const SummerMapPage({super.key});

  @override
  State<SummerMapPage> createState() => _SummerMapPageState();
}

class _SummerMapPageState extends State<SummerMapPage> {
  // ── Map state ──────────────────────────────────────────────────────────────
  final MapController _mapController = MapController();
  LatLng _center = _defaultCenter;
  LatLng? _userLocation;
  bool _isLocating = true;
  bool _buttonPressed = false;

  // ── Search state ───────────────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _searchFocused = false;
  List<_Place> _places = [];
  bool _searching = false;
  Timer? _debounce;

  static const List<_CoolSpot> _kCoolSpots = [
    _CoolSpot('Swimming pools', '8 nearby · mostly quiet',  'piscine',
        Color(0xFFD6EAF8), 0, Color(0xFF4A90D9), _Crowd.calm),
    _CoolSpot('Beaches',        '5 nearby · getting busy',  'plage',
        Color(0xFFFFF0CC), 1, Color(0xFFD4820A), _Crowd.medium),
    _CoolSpot('Lakes',          '12 nearby · mostly quiet', 'lac',
        Color(0xFFD5F5E3), 2, Color(0xFF2D8653), _Crowd.calm),
    _CoolSpot('Rivers',         '6 nearby · moderate flow', 'rivière',
        Color(0xFFD0EAF0), 3, Color(0xFF2E7D9B), _Crowd.medium),
  ];

  int _hoveredSpot = -1;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _searchFocus.addListener(
      () => setState(() => _searchFocused = _searchFocus.hasFocus),
    );
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Location ───────────────────────────────────────────────────────────────
  Future<void> _fetchLocation() async {
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
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _finishLocating(LatLng(pos.latitude, pos.longitude));
    } catch (_) {
      _finishLocating(null);
    }
  }

  void _finishLocating(LatLng? loc) {
    if (!mounted) return;
    setState(() {
      _userLocation = loc;
      if (loc != null) _center = loc;
      _isLocating = false;
    });
    if (loc != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.move(loc, 15.0);
      });
    }
  }

  void _centerOnUser() {
    if (_userLocation == null) return;
    _mapController.move(_userLocation!, 15.0);
    HapticFeedback.lightImpact();
  }

  // ── Search ─────────────────────────────────────────────────────────────────
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _places = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _doSearch(query),
    );
  }

  Future<void> _doSearch(String query) async {
    if (!mounted) return;
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q':               query,
        'format':          'json',
        'limit':           '5',
        'accept-language': 'fr',
      });
      final res = await http.get(uri, headers: {
        'User-Agent': 'PlageApp/1.0 (com.example.plage_review)',
      });
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        setState(() {
          _places = data
              .map((e) => _Place(
                    e['display_name'] as String,
                    double.parse(e['lat'] as String),
                    double.parse(e['lon'] as String),
                  ))
              .toList();
          _searching = false;
        });
      } else {
        setState(() => _searching = false);
      }
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _tapSuggestion(String keyword) {
    _searchCtrl.text = keyword;
    _searchCtrl.selection =
        TextSelection.collapsed(offset: keyword.length);
    setState(() {
      _places = [];
      _searching = true;
    });
    _doSearch(keyword);
  }

  void _selectPlace(_Place place) {
    _mapController.move(LatLng(place.lat, place.lon), 14.0);
    _searchFocus.unfocus();
    _searchCtrl.clear();
    setState(() => _places = []);
    HapticFeedback.selectionClick();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() {
      _places = [];
      _searching = false;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildMap(),
          _buildTopOverlay(),
          _buildButton(),
        ],
      ),
    );
  }

  // ── Map ────────────────────────────────────────────────────────────────────
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 15.0,
        interactionOptions:
            const InteractionOptions(flags: InteractiveFlag.all),
        onTap: (tapPos, point) => _searchFocus.unfocus(),
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture) _searchFocus.unfocus();
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.plage_review',
          maxZoom: 19,
        ),
        if (_userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _userLocation!,
                width: 44,
                height: 44,
                child: const _PulsingMarker(),
              ),
            ],
          ),
      ],
    );
  }

  // ── Top overlay ────────────────────────────────────────────────────────────
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
              _buildSearchBar(),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: _buildDropdown(),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.topCenter,
                child: _buildWeatherPill(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherPill() {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 9, 18, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF28321E).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomPaint(
            size: const Size(24, 24),
            painter: _SunPainter(),
          ),
          const SizedBox(width: 9),
          Text(
            'Ensoleillé',
            style: GoogleFonts.fredoka(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _fmDark,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            '42°',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _tempGrey,
            ),
          ),
          const SizedBox(width: 9),
          Container(
            width: 1,
            height: 16,
            color: Colors.black.withValues(alpha: 0.10),
          ),
          const SizedBox(width: 9),
          Text(
            'Une excellente journée!',
            style: GoogleFonts.nunito(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _warmOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _searchFocused ? _fmGreen : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF28321E).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CustomPaint(
            size: const Size(20, 20),
            painter: _SearchIconPainter(color: _searchGrey),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: _doSearch,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _fmDark,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: _searchFocused
                    ? 'Pools, beaches, lakes, rivers…'
                    : 'Search a place to cool off…',
                hintStyle: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _searchGrey,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchFocused)
            GestureDetector(
              onTap: _clearSearch,
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: _clearBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: _clearIconCol,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    final showSuggestions = _searchFocused && _searchCtrl.text.isEmpty;
    final showResults     = _searchFocused && _searchCtrl.text.isNotEmpty;

    if (!showSuggestions && !showResults) return const SizedBox.shrink();

    if (showSuggestions) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: TweenAnimationBuilder<double>(
          key: const ValueKey('cool-spots'),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - t)),
              child: child,
            ),
          ),
          child: _buildSuggestions(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: _Card(
        radius: 26,
        padding: EdgeInsets.zero,
        child: _buildResults(),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF28321E).withValues(alpha: 0.16),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Text(
              'COOL SPOTS NEAR YOU',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _sectionHead,
                letterSpacing: 0.04 * 12,
              ),
            ),
          ),
          ..._kCoolSpots.asMap().entries.map((entry) {
            final i    = entry.key;
            final spot = entry.value;
            final hovered = _hoveredSpot == i;
            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredSpot = i),
              onExit:  (_) => setState(() => _hoveredSpot = -1),
              child: GestureDetector(
                onTap: () => _tapSuggestion(spot.query),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: hovered ? _suggHover : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: spot.bg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: CustomPaint(
                            size: const Size(22, 22),
                            painter: _SpotIconPainter(
                              type: spot.iconType,
                              color: spot.iconColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spot.name,
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _fmDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              spot.description,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _searchGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: switch (spot.crowd) {
                            _Crowd.calm   => _crowdGreen,
                            _Crowd.medium => _crowdOrange,
                            _Crowd.busy   => _crowdRed,
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_searching) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _coral,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'On cherche pour toi… 🔍',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _inkMid,
              ),
            ),
          ],
        ),
      );
    }

    if (_places.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            const Text('🌍', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            Text(
              'Aucun endroit trouvé…',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _inkDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Essaie un autre terme !',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _inkMid,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _places.asMap().entries.map((entry) {
        final i     = entry.key;
        final place = entry.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _selectPlace(place),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: _peach,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('📍', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fredoka(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _inkDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _inkMid,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            if (i < _places.length - 1)
              Divider(height: 1, thickness: 1, color: _divider),
          ],
        );
      }).toList(),
    );
  }

  // ── Bottom button ──────────────────────────────────────────────────────────
  Widget _buildButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => setState(() => _buttonPressed = true),
              onTapUp: (_) {
                setState(() => _buttonPressed = false);
                _centerOnUser();
              },
              onTapCancel: () => setState(() => _buttonPressed = false),
              child: AnimatedScale(
                scale: _buttonPressed ? 0.94 : 1.0,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  decoration: BoxDecoration(
                    color: _coral,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: _coral.withValues(alpha: 0.30),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📍', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Text(
                        'Je suis ici !',
                        style: GoogleFonts.fredoka(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared minimal card — clean white surface, soft shadow, rounded corners
// ─────────────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.radius = 20,
    this.padding,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Pulsing location marker
// ─────────────────────────────────────────────────────────────────────────────
class _PulsingMarker extends StatefulWidget {
  const _PulsingMarker();

  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44 * _pulse.value,
            height: 44 * _pulse.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _coral.withValues(alpha: 0.18 * (1.5 - _pulse.value)),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _coral,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: _coral.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Stroke magnifying-glass icon
// ─────────────────────────────────────────────────────────────────────────────
class _SearchIconPainter extends CustomPainter {
  final Color color;
  const _SearchIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final cx = size.width * 0.40;
    final cy = size.height * 0.40;
    final r  = size.width * 0.30;
    canvas.drawCircle(Offset(cx, cy), r, paint);
    final startX = cx + r * cos(pi * 0.75);
    final startY = cy + r * sin(pi * 0.75);
    canvas.drawLine(
      Offset(startX, startY),
      Offset(size.width * 0.92, size.height * 0.92),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SearchIconPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Stroke spot illustrations
// ─────────────────────────────────────────────────────────────────────────────
class _SpotIconPainter extends CustomPainter {
  final int type;
  final Color color;
  const _SpotIconPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final h = size.height;
    switch (type) {
      case 0: // pool — two wave lines
        _wave(canvas, p, w, h, 0.38, 0.12);
        _wave(canvas, p, w, h, 0.62, 0.12);
      case 1: // beach — sun + horizon
        canvas.drawCircle(Offset(w * 0.62, h * 0.36), w * 0.17, p);
        for (int i = 0; i < 6; i++) {
          final a = i * pi / 3;
          canvas.drawLine(
            Offset(w * 0.62 + cos(a) * w * 0.23, h * 0.36 + sin(a) * h * 0.23),
            Offset(w * 0.62 + cos(a) * w * 0.31, h * 0.36 + sin(a) * h * 0.31),
            p,
          );
        }
        canvas.drawLine(Offset(0, h * 0.72), Offset(w, h * 0.72), p);
        _wave(canvas, p, w, h, 0.85, 0.10);
      case 2: // lake — mountain + water
        final mt = ui.Path()
          ..moveTo(w * 0.05, h * 0.72)
          ..lineTo(w * 0.38, h * 0.22)
          ..lineTo(w * 0.62, h * 0.50)
          ..lineTo(w * 0.50, h * 0.50)
          ..lineTo(w * 0.75, h * 0.28)
          ..lineTo(w * 0.95, h * 0.72);
        canvas.drawPath(mt, p);
        _wave(canvas, p, w, h, 0.85, 0.08);
      case 3: // river — flowing curve
        final rv = ui.Path()
          ..moveTo(w * 0.30, 0)
          ..cubicTo(w * 0.80, h * 0.15, w * 0.10, h * 0.45, w * 0.65, h * 0.55)
          ..cubicTo(w * 0.95, h * 0.62, w * 0.25, h * 0.82, w * 0.65, h);
        canvas.drawPath(rv, p);
    }
  }

  void _wave(Canvas canvas, Paint p, double w, double h, double cy, double amp) {
    final path = ui.Path()
      ..moveTo(0, h * cy)
      ..quadraticBezierTo(w * 0.25, h * (cy - amp), w * 0.50, h * cy)
      ..quadraticBezierTo(w * 0.75, h * (cy + amp), w, h * cy);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_SpotIconPainter old) =>
      old.type != type || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sun icon — filled disc + 8 stroke rays
// ─────────────────────────────────────────────────────────────────────────────
class _SunPainter extends CustomPainter {
  const _SunPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const color = _sunYellow;
    final cx = size.width / 2;
    final cy = size.height / 2;

    final rayPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final a = i * pi / 4;
      canvas.drawLine(
        Offset(cx + cos(a) * 7.5, cy + sin(a) * 7.5),
        Offset(cx + cos(a) * 11.5, cy + sin(a) * 11.5),
        rayPaint,
      );
    }

    canvas.drawCircle(
      Offset(cx, cy),
      5.5,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_SunPainter old) => false;
}
