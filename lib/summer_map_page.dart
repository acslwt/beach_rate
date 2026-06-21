import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Palette été
// ─────────────────────────────────────────────────────────────────────────────
const Color _sunYellow = Color(0xFFFBBF24);
const Color _sunOrange = Color(0xFFF97316);
const Color _amberText = Color(0xFF92400E);
const LatLng _defaultCenter = LatLng(48.8566, 2.3522); // Paris fallback

// ─────────────────────────────────────────────────────────────────────────────
//  Page
// ─────────────────────────────────────────────────────────────────────────────
class SummerMapPage extends StatefulWidget {
  const SummerMapPage({super.key});

  @override
  State<SummerMapPage> createState() => _SummerMapPageState();
}

class _SummerMapPageState extends State<SummerMapPage> {
  final MapController _mapController = MapController();
  LatLng _center = _defaultCenter;
  LatLng? _userLocation;
  bool _isLocating = true;
  bool _buttonPressed = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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
    // Move map after the first frame so the controller is attached
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

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildMap(),
          _buildHeader(),
          _buildButton(),
        ],
      ),
    );
  }

  // ── MAP ────────────────────────────────────────────────────────────────────
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 15.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
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

  // ── HEADER GLASSMORPHISM ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.topCenter,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.85),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _sunYellow.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── BOUTON "JE SUIS ICI" ──────────────────────────────────────────────────
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
//  Marker pulsant
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
              color: _sunOrange.withValues(
                alpha: 0.22 * (1.5 - _pulse.value),
              ),
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
