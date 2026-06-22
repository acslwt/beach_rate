import 'dart:async';
import 'dart:convert';

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

// Per-chip pastel backgrounds (colorful, warm, playful)
const Color _chipBeach  = Color(0xFFFFE8C8);
const Color _chipPool   = Color(0xFFBFDFFF);
const Color _chipLake   = Color(0xFFBDF5D6);
const Color _chipRiver  = Color(0xFFCDE8FF);

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

  static const List<(String emoji, String label, String query, Color bg)>
      _kSuggestions = [
    ('🏖️', 'Plage',   'plage',   _chipBeach),
    ('🏊', 'Piscine', 'piscine', _chipPool),
    ('🏞️', 'Lac',     'lac',     _chipLake),
    ('🌊', 'Rivière', 'rivière', _chipRiver),
  ];

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
    return _Card(
      radius: 50,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('☀️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            'Temps ensoleillé',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _coral,
            ),
          ),
          if (_isLocating) ...[
            const SizedBox(width: 10),
            const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _coral,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final hasText = _searchCtrl.text.isNotEmpty;
    return _Card(
      radius: 20,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search_rounded, color: _inkMid, size: 20),
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
                  color: _inkDark,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Où veux-tu aller ? 🗺️',
                  hintStyle: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _inkMid,
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
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _peach,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: _coral,
                      size: 14,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 16),
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
      child: _Card(
        radius: 20,
        padding: EdgeInsets.zero,
        child: showSuggestions ? _buildSuggestions() : _buildResults(),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 2),
            child: Text(
              'Explore par catégorie ✨',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _inkMid,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kSuggestions.map((s) {
              final (emoji, label, query, chipBg) = s;
              return GestureDetector(
                onTap: () => _tapSuggestion(query),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 17)),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _inkDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
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
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
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
                    borderRadius: BorderRadius.circular(34),
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
                        style: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
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
