import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_modal.dart';
import '../controllers/affluence_controller.dart';
import 'affluence_level_picker.dart';

/// Floating pill that appears automatically once the user is within
/// [kAffluenceEligibilityRadiusMeters] of a spot. Tapping it opens the
/// [AffluenceLevelPicker] modal, unless a cooldown is active — in which
/// case it shows the remaining wait time instead.
class ReportAffluenceButton extends StatefulWidget {
  const ReportAffluenceButton({super.key, required this.controller});

  final AffluenceController controller;

  @override
  State<ReportAffluenceButton> createState() => _ReportAffluenceButtonState();
}

class _ReportAffluenceButtonState extends State<ReportAffluenceButton> {
  bool _pressed = false;

  void _showPicker() {
    final spot = widget.controller.eligibleSpot;
    if (spot == null) return;
    showAppModal(
      context,
      (ctx) => AffluenceLevelPicker(
        controller: widget.controller,
        spotName: spot.name,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  String _formatCooldown(Duration remaining) {
    final minutes = remaining.inMinutes + 1;
    return minutes > 1 ? 'Réessaie dans $minutes min' : 'Réessaie dans 1 min';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final spot = widget.controller.eligibleSpot;
        if (spot == null) return const SizedBox.shrink();

        final canReport = widget.controller.canReportNow;
        final remaining = widget.controller.cooldownRemaining;

        return GestureDetector(
          onTapDown: canReport ? (_) => setState(() => _pressed = true) : null,
          onTapUp: canReport
              ? (_) {
                  setState(() => _pressed = false);
                  _showPicker();
                }
              : null,
          onTapCancel: canReport ? () => setState(() => _pressed = false) : null,
          child: AnimatedScale(
            scale: _pressed ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                color: canReport ? appCoral : Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF28321E).withValues(alpha: 0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.campaign_rounded,
                    size: 18,
                    color: canReport ? Colors.white : appSearchGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    canReport
                        ? 'Signaler l\'affluence'
                        : _formatCooldown(remaining ?? Duration.zero),
                    style: GoogleFonts.fredoka(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: canReport ? Colors.white : appSearchGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
