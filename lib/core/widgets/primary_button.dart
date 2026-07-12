import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-width rounded call-to-action button. Reused across modals
/// (auth, affluence reporting) — pass `onTap: null` to render disabled.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: enabled ? backgroundColor : backgroundColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
