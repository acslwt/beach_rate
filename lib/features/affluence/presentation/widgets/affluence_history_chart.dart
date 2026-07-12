import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/day_profile.dart';
import '../../domain/entities/affluence_level.dart';
import '../../domain/entities/hourly_affluence_stat.dart';
import '../../domain/usecases/watch_weekly_affluence_profile.dart';

const _kDayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

/// Modal showing a spot's usual affluence as a bar chart across the day's
/// 2h buckets, with a day-of-week switcher. Reuses [HourlyAffluenceStat] —
/// the same aggregate already computed for the "affluence habituelle" stat
/// on [AffluenceCard], just for every bucket instead of just the current one.
class AffluenceHistoryChart extends StatefulWidget {
  const AffluenceHistoryChart({
    super.key,
    required this.spotName,
    required this.zoneId,
    required this.watchWeeklyProfile,
    required this.onClose,
  });

  final String spotName;
  final String zoneId;
  final WatchWeeklyAffluenceProfile watchWeeklyProfile;
  final VoidCallback onClose;

  @override
  State<AffluenceHistoryChart> createState() => _AffluenceHistoryChartState();
}

class _AffluenceHistoryChartState extends State<AffluenceHistoryChart> {
  late int _selectedWeekday = DateTime.now().weekday;
  int? _selectedBucket = DateTime.now().hour ~/ kAffluenceHourBucketSize;
  Map<String, HourlyAffluenceStat>? _profile;
  StreamSubscription<Map<String, HourlyAffluenceStat>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.watchWeeklyProfile(widget.zoneId).listen((profile) {
      if (mounted) setState(() => _profile = profile);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _selectWeekday(int weekday) {
    setState(() {
      _selectedWeekday = weekday;
      _selectedBucket = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final buckets = profile != null ? dayProfile(profile, _selectedWeekday) : null;
    final hasAnyData = buckets != null &&
        buckets.any((b) => b != null && b.sampleCount >= kMinHistoricalSamples);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF283223).withValues(alpha: 0.22),
            blurRadius: 44,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Affluence habituelle',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: appFmDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onClose,
                child: const Icon(Icons.close_rounded, size: 20, color: appSearchGrey),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            widget.spotName,
            style: GoogleFonts.nunito(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: appSearchGrey,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: List.generate(7, (i) {
              final weekday = i + 1;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _DayChip(
                    label: _kDayLabels[i],
                    selected: _selectedWeekday == weekday,
                    onTap: () => _selectWeekday(weekday),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 22),
          if (buckets == null)
            const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(color: appCoral)),
            )
          else if (!hasAnyData)
            const _EmptyState()
          else
            _BarChart(
              buckets: buckets,
              selectedBucket: _selectedBucket,
              onBarTap: (i) => setState(() => _selectedBucket = i),
            ),
          const SizedBox(height: 12),
          _DetailCaption(
            bucket: _selectedBucket,
            stat: (_selectedBucket != null && buckets != null)
                ? buckets[_selectedBucket!]
                : null,
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.buckets,
    required this.selectedBucket,
    required this.onBarTap,
  });

  final List<HourlyAffluenceStat?> buckets;
  final int? selectedBucket;
  final ValueChanged<int> onBarTap;

  static const _chartHeight = 110.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: _chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(buckets.length, (i) {
              final stat = buckets[i];
              final hasData = stat != null && stat.sampleCount >= kMinHistoricalSamples;
              final barHeight = hasData
                  ? (stat.avgLevel / 5.0).clamp(0.06, 1.0) * _chartHeight
                  : 10.0;
              final color = hasData
                  ? appAffluenceLevelColors[stat.avgLevel.round().clamp(0, 5)]
                  : Colors.transparent;
              final selected = selectedBucket == i;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onBarTap(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: color,
                            border: hasData
                                ? (selected ? Border.all(color: appFmDark, width: 1.4) : null)
                                : Border.all(
                                    color: selected ? appFmDark : appInkMid,
                                    width: 1,
                                  ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(buckets.length, (i) {
            return Expanded(
              child: Text(
                i.isEven ? '${i * kAffluenceHourBucketSize}h' : '',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: appInkMid,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? appCoral : appSuggHover,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : appFmDark,
          ),
        ),
      ),
    );
  }
}

class _DetailCaption extends StatelessWidget {
  const _DetailCaption({required this.bucket, required this.stat});

  final int? bucket;
  final HourlyAffluenceStat? stat;

  @override
  Widget build(BuildContext context) {
    final b = bucket;
    if (b == null) {
      return Text(
        'Touche une barre pour le détail.',
        style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: appInkMid),
      );
    }

    final startHour = b * kAffluenceHourBucketSize;
    final endHour = startHour + kAffluenceHourBucketSize;
    final range = '${startHour}h-${endHour}h';
    final s = stat;

    if (s == null || s.sampleCount < kMinHistoricalSamples) {
      return Text(
        '$range — pas assez de données',
        style: GoogleFonts.nunito(fontSize: 12.5, fontWeight: FontWeight.w700, color: appInkMid),
      );
    }

    final level = AffluenceLevel.fromScore(s.avgLevel);
    final count = s.sampleCount;
    return Text(
      '$range — ${level.label} ($count signalement${count > 1 ? 's' : ''})',
      style: GoogleFonts.nunito(fontSize: 12.5, fontWeight: FontWeight.w700, color: appFmDark),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          'Pas encore assez de données pour ce jour.',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: appInkMid),
        ),
      ),
    );
  }
}
