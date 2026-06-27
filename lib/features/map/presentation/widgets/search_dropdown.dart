import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/base_card.dart';
import '../../domain/entities/cool_spot.dart';
import '../../domain/entities/crowd_level.dart';
import '../../domain/entities/place.dart';
import '../painters/spot_icon_painter.dart';

class SearchDropdown extends StatefulWidget {
  const SearchDropdown({
    super.key,
    required this.isFocused,
    required this.hasQuery,
    required this.isSearching,
    required this.places,
    required this.coolSpots,
    required this.onSuggestionTap,
    required this.onPlaceTap,
  });

  final bool isFocused;
  final bool hasQuery;
  final bool isSearching;
  final List<Place> places;
  final List<CoolSpot> coolSpots;
  final ValueChanged<String> onSuggestionTap;
  final ValueChanged<Place> onPlaceTap;

  @override
  State<SearchDropdown> createState() => _SearchDropdownState();
}

class _SearchDropdownState extends State<SearchDropdown> {
  int _hovered = -1;

  @override
  Widget build(BuildContext context) {
    if (!widget.isFocused) return const SizedBox.shrink();

    if (!widget.hasQuery) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: TweenAnimationBuilder<double>(
          key: const ValueKey('cool-spots'),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
          ),
          child: _buildSuggestions(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: BaseCard(radius: 26, padding: EdgeInsets.zero, child: _buildResults()),
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
              'LIEUX SYMPAS PRÈS DE CHEZ VOUS',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: appSectionHead,
                letterSpacing: 0.04 * 12,
              ),
            ),
          ),
          ...widget.coolSpots.asMap().entries.map((entry) {
            final i    = entry.key;
            final spot = entry.value;
            final hovered = _hovered == i;
            return MouseRegion(
              onEnter: (_) => setState(() => _hovered = i),
              onExit:  (_) => setState(() => _hovered = -1),
              child: GestureDetector(
                onTap: () => widget.onSuggestionTap(spot.query),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: hovered ? appSuggHover : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: spot.backgroundColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: CustomPaint(
                            size: const Size(22, 22),
                            painter: SpotIconPainter(type: spot.type, color: spot.iconColor),
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
                                color: appFmDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              spot.description,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: appSearchGrey,
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
                            CrowdLevel.calm   => appCrowdGreen,
                            CrowdLevel.medium => appCrowdOrange,
                            CrowdLevel.busy   => appCrowdRed,
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
    if (widget.isSearching) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: appCoral),
            ),
            const SizedBox(height: 12),
            Text(
              'On cherche pour toi… 🔍',
              style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: appInkMid),
            ),
          ],
        ),
      );
    }

    if (widget.places.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            const Text('🌍', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            Text(
              'Aucun endroit trouvé…',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: appInkDark),
            ),
            const SizedBox(height: 4),
            Text(
              'Essaie un autre terme !',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: appInkMid),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: widget.places.asMap().entries.map((entry) {
        final i     = entry.key;
        final place = entry.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onPlaceTap(place),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(color: appPeach, shape: BoxShape.circle),
                      child: const Center(child: Text('📍', style: TextStyle(fontSize: 16))),
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
                          color: appInkDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded, color: appInkMid, size: 18),
                  ],
                ),
              ),
            ),
            if (i < widget.places.length - 1)
              Divider(height: 1, thickness: 1, color: appDivider),
          ],
        );
      }).toList(),
    );
  }
}
