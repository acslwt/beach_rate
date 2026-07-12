import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/affluence_level.dart';
import '../../domain/entities/nearby_spot.dart';
import '../../domain/entities/zone_affluence_stats.dart';
import '../../domain/eligibility.dart';
import '../../domain/failures/affluence_exception.dart';
import '../../domain/repositories/affluence_repository.dart';
import '../../domain/usecases/submit_affluence_report.dart';
import '../../domain/usecases/watch_zone_affluence.dart';

class AffluenceController extends ChangeNotifier {
  AffluenceController({
    required this._repository,
    required this._submitAffluenceReport,
    required this._watchZoneAffluence,
  });

  final AffluenceRepository _repository;
  final SubmitAffluenceReport _submitAffluenceReport;
  final WatchZoneAffluence _watchZoneAffluence;

  String? _userId;
  NearbySpot? eligibleSpot;
  bool isSubmitting = false;
  String? submitError;

  DateTime? _cooldownUntil;
  Timer? _cooldownTicker;

  final _statsByZone = <String, ZoneAffluenceStats>{};
  final _subscriptions = <String, StreamSubscription<ZoneAffluenceStats>>{};

  bool get loggedIn => _userId != null;

  ZoneAffluenceStats? statsForZone(String zoneId) => _statsByZone[zoneId];

  double? liveLevelForSpot(String zoneId) => _statsByZone[zoneId]?.currentLevel;

  bool get canReportNow => eligibleSpot != null && cooldownRemaining == null;

  Duration? get cooldownRemaining {
    final until = _cooldownUntil;
    if (until == null) return null;
    final remaining = until.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  void setUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    unawaited(_refreshCooldown());
  }

  /// Called whenever the user's GPS position or the set of visible spots
  /// changes (mirrors `MapStateController.fetchSpotsInView`'s refresh cadence).
  void updateContext({
    required LatLng? userLocation,
    required List<NearbySpot> spots,
  }) {
    _syncSubscriptions(spots);

    final nearest = userLocation != null
        ? nearestEligibleSpot(userLocation, spots)
        : null;
    debugPrint(
      '[affluence] userLocation=$userLocation, ${spots.length} spot(s) visible, '
      'eligible=${nearest?.name ?? "none"}',
    );
    if (nearest?.id != eligibleSpot?.id) {
      eligibleSpot = nearest;
      unawaited(_refreshCooldown());
    } else {
      notifyListeners();
    }
  }

  void _syncSubscriptions(List<NearbySpot> spots) {
    final visibleIds = spots.map((s) => s.id).toSet();

    final stale = _subscriptions.keys.where((id) => !visibleIds.contains(id)).toList();
    for (final id in stale) {
      _subscriptions.remove(id)?.cancel();
      _statsByZone.remove(id);
    }

    for (final spot in spots) {
      if (_subscriptions.containsKey(spot.id)) continue;
      _subscriptions[spot.id] = _watchZoneAffluence(spot.id).listen(
        (stats) {
          _statsByZone[spot.id] = stats;
          notifyListeners();
        },
        onError: (Object e) {
          debugPrint('[affluence] watchZoneAffluence failed for ${spot.id}: $e');
        },
      );
    }
  }

  Future<void> _refreshCooldown() async {
    _cooldownTicker?.cancel();
    _cooldownUntil = null;

    final userId = _userId;
    final zone = eligibleSpot;
    if (userId == null || zone == null) {
      notifyListeners();
      return;
    }

    try {
      final last = await _repository.lastReportTime(zone.id, userId);
      final until = last?.add(kAffluenceReportCooldown);
      if (until != null && until.isAfter(DateTime.now())) {
        _startCooldownTicker(until);
      }
    } catch (e) {
      // Don't let a failed cooldown check (e.g. Firestore rules/index not
      // deployed yet) hide the report button — surface it in logs instead.
      debugPrint('[affluence] lastReportTime failed for ${zone.id}: $e');
    } finally {
      notifyListeners();
    }
  }

  void _startCooldownTicker(DateTime until) {
    _cooldownUntil = until;
    _cooldownTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (cooldownRemaining == null) _cooldownTicker?.cancel();
      notifyListeners();
    });
  }

  Future<bool> submit(AffluenceLevel level) async {
    final userId = _userId;
    final zone = eligibleSpot;
    if (userId == null || zone == null) return false;

    isSubmitting = true;
    submitError = null;
    notifyListeners();

    try {
      await _submitAffluenceReport(zoneId: zone.id, userId: userId, level: level);
      await _refreshCooldown();
      return true;
    } on AffluenceCooldownException catch (e) {
      _startCooldownTicker(DateTime.now().add(e.remaining));
      submitError = 'Tu as déjà signalé cette zone récemment.';
      return false;
    } catch (_) {
      submitError = 'Une erreur est survenue. Réessaie.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _cooldownTicker?.cancel();
    super.dispose();
  }
}
