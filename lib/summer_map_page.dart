import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Design tokens
// ─────────────────────────────────────────────────────────────────────────────
const Color _sunYellow = Color(0xFFFBBF24);
const Color _sunOrange = Color(0xFFF97316);
const Color _amberText = Color(0xFF92400E);
const Color _grey500   = Color(0xFF6B7280);
const Color _grey200   = Color(0xFFE5E7EB);
const Color _ink       = Color(0xFF374151);
const LatLng _defaultCenter = LatLng(48.8566, 2.3522);

// Grayscale ColorFilter used on suggestion emojis
const ColorFilter _greyscale = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0,      0,      0,      1, 0,
]);

// ─────────────────────────────────────────────────────────────────────────────
//  Model
// ─────────────────────────────────────────────────────────────────────────────
class _Place {
  final String name;
  final double lat;
  final double lon;
  const _Place(this.name, this.lat, this.lon);
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

  static const List<(String emoji, String label, String query)> _kSuggestions = [
    ('🏖️', 'Plage',   'plage'),
    ('🏊', 'Piscine', 'piscine'),
    ('🏞️', 'Lac',     'lac'),
    ('🌊', 'Rivière', 'rivière'),
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _searchFocus.addListener(
      () => setState(() => _searchFocused = _searchFocus.hasFocus),
    );
    _searchCtrl.addListener(() => setState(() {})); // rebuild on text change
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
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
      setState(() { _places = []; _searching = false; });
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
    setState(() { _places = []; _searching = true; });
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
    setState(() { _places = []; _searching = false; });
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
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
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

  // ── Top overlay (weather pill + search bar + dropdown) ─────────────────────
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
    return _GlassContainer(
      radius: 22,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😊', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Text(
            'Temps ensoleillé',
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _amberText,
              letterSpacing: 0.1,
            ),
          ),
          if (_isLocating) ...[
            const SizedBox(width: 10),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _sunOrange,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final hasText = _searchCtrl.text.isNotEmpty;
    return _GlassContainer(
      radius: 16,
      padding: EdgeInsets.zero,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.search_rounded, color: _grey500, size: 20),
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
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Rechercher un lieu…',
                  hintStyle: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _grey500,
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (hasText)
              GestureDetector(
                onTap: _clearSearch,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.close_rounded, color: _grey500, size: 18),
                ),
              )
            else
              const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    final showSuggestions = _searchFocused && _searchCtrl.text.isEmpty;
    final showResults     = _searchFocused && _searchCtrl.text.isNotEmpty;

    if (!showSuggestions && !showResults) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _GlassContainer(
        radius: 18,
        bg: Colors.white.withValues(alpha: 0.88),
        padding: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: 0.09),
        child: showSuggestions ? _buildSuggestions() : _buildResults(),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _kSuggestions.map((s) {
          final (emoji, label, query) = s;
          return GestureDetector(
            onTap: () => _tapSuggestion(query),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: _grey200,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ColorFiltered(
                    colorFilter: _greyscale,
                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _grey500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResults() {
    if (_searching) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: _sunOrange),
          ),
        ),
      );
    }

    if (_places.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Aucun résultat — essaie un autre terme 🌍',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _grey500,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _places.asMap().entries.map((entry) {
        final i = entry.key;
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
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: _sunOrange,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < _places.length - 1)
              Divider(height: 1, thickness: 1, color: _grey200),
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
                scale: _buttonPressed ? 0.93 : 1.0,
                duration: const Duration(milliseconds: 130),
                curve: Curves.easeOut,
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_sunYellow, _sunOrange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: [
                      BoxShadow(
                        color: _sunOrange.withValues(alpha: 0.42),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: _sunYellow.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.my_location_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Je suis ici',
                        style: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
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
//  Shared glassmorphism container
// ─────────────────────────────────────────────────────────────────────────────
class _GlassContainer extends StatelessWidget {
  const _GlassContainer({
    required this.child,
    this.radius = 20,
    this.padding,
    this.bg,
    this.shadowColor,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final Color? bg;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            color: bg ?? Colors.white.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.88),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor ?? _sunYellow.withValues(alpha: 0.15),
                blurRadius: 22,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
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
              color: _sunOrange.withValues(alpha: 0.22 * (1.5 - _pulse.value)),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _sunOrange,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: _sunOrange.withValues(alpha: 0.5),
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
