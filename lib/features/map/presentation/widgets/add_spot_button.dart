import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

/// Floating pill shown when the user isn't close enough to any known spot to
/// report affluence — lets them create one instead (e.g. a pool, which OSM
/// never has).
class AddSpotButton extends StatefulWidget {
  const AddSpotButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<AddSpotButton> createState() => _AddSpotButtonState();
}

class _AddSpotButtonState extends State<AddSpotButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: appCoral, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF28321E).withValues(alpha: 0.14),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_location_alt_rounded, size: 18, color: appCoral),
              const SizedBox(width: 8),
              Text(
                'Ajouter un spot ici',
                style: GoogleFonts.fredoka(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: appCoral,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
