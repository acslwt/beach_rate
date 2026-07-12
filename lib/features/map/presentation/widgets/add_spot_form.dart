import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/map_spot.dart';
import '../painters/spot_icon_painter.dart';

const _kTypeLabels = {
  SpotType.pool: 'Piscine',
  SpotType.beach: 'Plage',
  SpotType.lake: 'Lac',
  SpotType.river: 'Rivière',
};

/// Modal content for creating a new spot (type + optional name) at the
/// user's current location.
class AddSpotForm extends StatefulWidget {
  const AddSpotForm({
    super.key,
    required this.loggedIn,
    required this.onSubmit,
    required this.onClose,
  });

  final bool loggedIn;
  final Future<bool> Function(String name, SpotType type) onSubmit;
  final VoidCallback onClose;

  @override
  State<AddSpotForm> createState() => _AddSpotFormState();
}

class _AddSpotFormState extends State<AddSpotForm> {
  SpotType? _selectedType;
  final _nameCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final type = _selectedType;
    if (type == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final typed = _nameCtrl.text.trim();
    final name = typed.isEmpty ? _kTypeLabels[type]! : typed;
    final ok = await widget.onSubmit(name, type);

    if (!mounted) return;
    if (ok) {
      setState(() {
        _success = true;
        _submitting = false;
      });
      await Future.delayed(const Duration(milliseconds: 1100));
      if (mounted) widget.onClose();
    } else {
      setState(() {
        _submitting = false;
        _error = 'Une erreur est survenue. Réessaie.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ajouter un spot',
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: appFmDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'À l\'endroit où tu es en ce moment',
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
          children: SpotType.values
              .map((type) => _TypeChip(
                    type: type,
                    label: _kTypeLabels[type]!,
                    selected: _selectedType == type,
                    onTap: () => setState(() => _selectedType = type),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameCtrl,
          style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: 'Nom (optionnel)',
            hintStyle: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: appSearchGrey,
            ),
            filled: true,
            fillColor: appSuggHover,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (!widget.loggedIn || _error != null) ...[
          const SizedBox(height: 14),
          Text(
            widget.loggedIn ? _error! : 'Connecte-toi pour ajouter un spot.',
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
          label: _submitting ? 'Ajout…' : 'Ajouter ce lieu',
          backgroundColor: appFmGreen,
          textColor: Colors.white,
          onTap: (!widget.loggedIn || _selectedType == null || _submitting) ? null : _submit,
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.type,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final SpotType type;
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? appPeach : appSuggHover,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? appCoral : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: const Size(26, 26),
              painter: SpotIconPainter(
                type: type,
                color: selected ? appCoral : appSearchGrey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
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
          'Spot ajouté !',
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: appFmDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Il apparaît sur la carte pour tout le monde.',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: appSearchGrey,
          ),
        ),
      ],
    );
  }
}
