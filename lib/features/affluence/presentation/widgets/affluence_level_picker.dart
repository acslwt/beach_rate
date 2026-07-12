import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/affluence_level.dart';
import '../controllers/affluence_controller.dart';

/// Modal content for choosing a 0-5 affluence level and submitting it.
class AffluenceLevelPicker extends StatefulWidget {
  const AffluenceLevelPicker({
    super.key,
    required this.controller,
    required this.spotName,
    required this.onClose,
  });

  final AffluenceController controller;
  final String spotName;
  final VoidCallback onClose;

  @override
  State<AffluenceLevelPicker> createState() => _AffluenceLevelPickerState();
}

class _AffluenceLevelPickerState extends State<AffluenceLevelPicker> {
  AffluenceLevel? _selected;
  bool _success = false;

  Future<void> _submit() async {
    final level = _selected;
    if (level == null) return;
    final ok = await widget.controller.submit(level);
    if (!mounted) return;
    if (ok) {
      setState(() => _success = true);
      await Future.delayed(const Duration(milliseconds: 1100));
      if (mounted) widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
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
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: _success ? const _SuccessBody() : _buildForm(),
        );
      },
    );
  }

  Widget _buildForm() {
    final error = widget.controller.submitError;
    final isSubmitting = widget.controller.isSubmitting;
    final loggedIn = widget.controller.loggedIn;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.spotName,
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: appFmDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Comment est l\'affluence en ce moment ?',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: appSearchGrey,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: AffluenceLevel.values
              .map((level) => _LevelChip(
                    level: level,
                    selected: _selected == level,
                    onTap: () => setState(() => _selected = level),
                  ))
              .toList(),
        ),
        if (!loggedIn || error != null) ...[
          const SizedBox(height: 14),
          Text(
            loggedIn ? error! : 'Connecte-toi pour signaler l\'affluence.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.red.shade400,
            ),
          ),
        ],
        const SizedBox(height: 22),
        PrimaryButton(
          label: isSubmitting ? 'Envoi…' : 'Envoyer (+$kAffluencePointsPerReport pts)',
          backgroundColor: appCoral,
          textColor: Colors.white,
          onTap: (!loggedIn || _selected == null || isSubmitting) ? null : _submit,
        ),
      ],
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final AffluenceLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = appAffluenceLevelColors[level.value];
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : appSuggHover,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              level.label,
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: appFmDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(color: appPeach, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: appCoral, size: 34),
        ),
        const SizedBox(height: 16),
        Text(
          'Merci pour ton signalement !',
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: appFmDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '+$kAffluencePointsPerReport points',
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: appFmGreen,
          ),
        ),
      ],
    );
  }
}
