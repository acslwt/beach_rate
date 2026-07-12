import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class UserMarker extends StatefulWidget {
  const UserMarker({super.key, this.photoUrl, this.initial});

  /// Signed-in user's profile photo, when the sign-in provider has one.
  final String? photoUrl;

  /// Fallback letter shown in a colored circle when there's no photo.
  /// `null` means no signed-in user at all — keeps the original generic
  /// illustration instead of an avatar.
  final String? initial;

  @override
  State<UserMarker> createState() => _UserMarkerState();
}

class _UserMarkerState extends State<UserMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    final curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale   = Tween<double>(begin: 0.85, end: 1.7).animate(curved);
    _opacity = Tween<double>(begin: 0.55, end: 0.0).animate(curved);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) => Opacity(
                opacity: _opacity.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF9C97E6),
                    ),
                  ),
                ),
              ),
            ),
            _Avatar(photoUrl: widget.photoUrl, initial: widget.initial),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF3B3960),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "Ça c'est bibi",
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.initial});

  final String? photoUrl;
  final String? initial;

  @override
  Widget build(BuildContext context) {
    final letter = initial;
    if (letter == null) {
      // No signed-in user — keep the original friendly default illustration.
      return Image.asset(
        'moi.png',
        width: 78,
        height: 104,
        fit: BoxFit.contain,
      );
    }

    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: appLavender,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _InitialLabel(letter),
              )
            : _InitialLabel(letter),
      ),
    );
  }
}

class _InitialLabel extends StatelessWidget {
  const _InitialLabel(this.letter);

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        letter,
        style: GoogleFonts.fredoka(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: appMarkerInk,
        ),
      ),
    );
  }
}
