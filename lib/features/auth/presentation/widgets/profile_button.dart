import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_modal.dart';
import '../controllers/auth_controller.dart';
import '../painters/user_silhouette_painter.dart';
import 'profile_modal_content.dart';

class ProfileButton extends StatefulWidget {
  const ProfileButton({
    super.key,
    required this.controller,
    required this.points,
  });

  final AuthController controller;

  /// Affluence points, shown in the profile modal's stats row.
  final ValueListenable<int> points;

  @override
  State<ProfileButton> createState() => _ProfileButtonState();
}

class _ProfileButtonState extends State<ProfileButton> {
  bool _pressed = false;

  void _showModal() {
    showAppModal(
      context,
      (ctx) => ValueListenableBuilder<int>(
        valueListenable: widget.points,
        builder: (context, points, _) => ProfileModalContent(
          controller: widget.controller,
          onClose: () => Navigator.of(ctx).pop(),
          points: points,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final loggedIn = widget.controller.loggedIn;
        final profile = widget.controller.profile;

        return GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            _showModal();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: loggedIn
                    ? Border.all(color: appLavender, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF283223).withValues(alpha: 0.14),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: loggedIn && profile != null
                  ? _SmallAvatar(initial: profile.initial)
                  : const _SilhouetteIcon(),
            ),
          ),
        );
      },
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: appLavender,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initial,
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: appMarkerInk,
            ),
          ),
        ),
      ),
    );
  }
}

class _SilhouetteIcon extends StatelessWidget {
  const _SilhouetteIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: const Size(22, 22),
        painter: UserSilhouettePainter(color: appClearIcon),
      ),
    );
  }
}
