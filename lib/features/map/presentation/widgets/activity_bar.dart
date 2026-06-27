import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/map_state_controller.dart';
import '../painters/buoy_painter.dart';
import '../painters/sunglasses_sun_painter.dart';

class ActivityBar extends StatefulWidget {
  const ActivityBar({super.key, required this.controller});

  final MapStateController controller;

  @override
  State<ActivityBar> createState() => _ActivityBarState();
}

class _ActivityBarState extends State<ActivityBar> {
  int? _pressed;
  int? _hovered;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActivityButton(
                  index: 0,
                  label: 'Bronzette',
                  activeColor: const Color(0xFFFBE3C9),
                  painter: const SunglassesSunPainter(),
                  selected: widget.controller.selectedActivity == 0,
                  pressed: _pressed == 0,
                  hovered: _hovered == 0,
                  onTap: () => widget.controller.toggleActivity(0),
                  onPressedChange: (v) => setState(() => _pressed = v ? 0 : null),
                  onHoverChange: (v) => setState(() => _hovered = v ? 0 : null),
                ),
                const SizedBox(width: 18),
                _ActivityButton(
                  index: 1,
                  label: 'Trempette',
                  activeColor: const Color(0xFFCFE7EE),
                  painter: const BuoyPainter(),
                  selected: widget.controller.selectedActivity == 1,
                  pressed: _pressed == 1,
                  hovered: _hovered == 1,
                  onTap: () => widget.controller.toggleActivity(1),
                  onPressedChange: (v) => setState(() => _pressed = v ? 1 : null),
                  onHoverChange: (v) => setState(() => _hovered = v ? 1 : null),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityButton extends StatelessWidget {
  const _ActivityButton({
    required this.index,
    required this.label,
    required this.activeColor,
    required this.painter,
    required this.selected,
    required this.pressed,
    required this.hovered,
    required this.onTap,
    required this.onPressedChange,
    required this.onHoverChange,
  });

  final int index;
  final String label;
  final Color activeColor;
  final CustomPainter painter;
  final bool selected;
  final bool pressed;
  final bool hovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onPressedChange;
  final ValueChanged<bool> onHoverChange;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHoverChange(true),
      onExit:  (_) => onHoverChange(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown:  (_) => onPressedChange(true),
        onTapUp:    (_) { onPressedChange(false); onTap(); },
        onTapCancel: () => onPressedChange(false),
        child: AnimatedScale(
          scale: pressed ? 1.08 : hovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            width: 96,
            padding: const EdgeInsets.fromLTRB(0, 13, 0, 12),
            decoration: BoxDecoration(
              color: selected ? activeColor : Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF28321E).withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(size: const Size(34, 34), painter: painter),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: appFmDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
