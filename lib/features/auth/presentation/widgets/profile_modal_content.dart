import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import 'mascot_widget.dart';

enum _AuthView { idle, login, signup }

class ProfileModalContent extends StatelessWidget {
  const ProfileModalContent({
    super.key,
    required this.controller,
    required this.onClose,
  });

  final AuthController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => controller.loggedIn
          ? _ConnectedCard(controller: controller, onClose: onClose)
          : _DisconnectedCard(controller: controller),
    );
  }
}

// ── Disconnected ──────────────────────────────────────────────────────────────

class _DisconnectedCard extends StatefulWidget {
  const _DisconnectedCard({required this.controller});
  final AuthController controller;

  @override
  State<_DisconnectedCard> createState() => _DisconnectedCardState();
}

class _DisconnectedCardState extends State<_DisconnectedCard> {
  _AuthView _view = _AuthView.idle;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (_view == _AuthView.login) {
      widget.controller.signInWithEmailAndPassword(email, password);
    } else {
      widget.controller.signUpWithEmailAndPassword(email, password);
    }
  }

  void _back() {
    widget.controller.clearError();
    setState(() => _view = _AuthView.idle);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return _Card(
          child: widget.controller.isLoading
              ? const _LoadingBody()
              : _view == _AuthView.idle
                  ? _IdleBody(
                      onLogin: () => setState(() => _view = _AuthView.login),
                      onSignup: () => setState(() => _view = _AuthView.signup),
                    )
                  : _FormBody(
                      view: _view,
                      emailCtrl: _emailCtrl,
                      passwordCtrl: _passwordCtrl,
                      obscurePassword: _obscurePassword,
                      error: widget.controller.error,
                      onToggleObscure: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onSubmit: _submit,
                      onGoogleSignIn: widget.controller.signInWithGoogle,
                      onBack: _back,
                    ),
        );
      },
    );
  }
}

// ── Idle body (mascot + two buttons) ─────────────────────────────────────────

class _IdleBody extends StatelessWidget {
  const _IdleBody({required this.onLogin, required this.onSignup});

  final VoidCallback onLogin;
  final VoidCallback onSignup;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MascotWidget(),
        const SizedBox(height: 20),
        Text(
          'Bienvenue !',
          style: GoogleFonts.fredoka(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: appFmDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connecte-toi pour garder tes spots favoris\net suivre l\'affluence.',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: appSearchGrey,
          ),
        ),
        const SizedBox(height: 24),
        _ActionButton(
          label: 'Se connecter',
          backgroundColor: appFmGreen,
          textColor: Colors.white,
          onTap: onLogin,
        ),
        const SizedBox(height: 10),
        _ActionButton(
          label: 'Créer un compte',
          backgroundColor: appClearBg,
          textColor: appMossText,
          onTap: onSignup,
        ),
      ],
    );
  }
}

// ── Form body (email/password + Google) ──────────────────────────────────────

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.view,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.error,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onGoogleSignIn,
    required this.onBack,
  });

  final _AuthView view;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final String? error;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onBack;

  bool get _isLogin => view == _AuthView.login;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: appSearchGrey),
            ),
            const SizedBox(width: 8),
            Text(
              _isLogin ? 'Se connecter' : 'Créer un compte',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: appFmDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _TextField(
          controller: emailCtrl,
          hint: 'Email',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _TextField(
          controller: passwordCtrl,
          hint: 'Mot de passe',
          obscureText: obscurePassword,
          suffixIcon: GestureDetector(
            onTap: onToggleObscure,
            child: Icon(
              obscurePassword ? Icons.visibility_off : Icons.visibility,
              size: 18,
              color: appSearchGrey,
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.red.shade400,
            ),
          ),
        ],
        const SizedBox(height: 20),
        _ActionButton(
          label: _isLogin ? 'Se connecter' : 'Créer mon compte',
          backgroundColor: appFmGreen,
          textColor: Colors.white,
          onTap: onSubmit,
        ),
        if (_isLogin) ...[
          const SizedBox(height: 16),
          _OrDivider(),
          const SizedBox(height: 16),
          _GoogleButton(onTap: onGoogleSignIn),
        ],
      ],
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: CircularProgressIndicator(color: appFmGreen),
      ),
    );
  }
}

// ── Connected ─────────────────────────────────────────────────────────────────

class _ConnectedCard extends StatelessWidget {
  const _ConnectedCard({required this.controller, required this.onClose});

  final AuthController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile!;
    return _Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LargeAvatar(initial: profile.initial),
          const SizedBox(height: 16),
          Text(
            profile.firstName,
            style: GoogleFonts.fredoka(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: appFmDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: appSearchGrey,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Favoris',
                  value: '${profile.favorites}',
                  valueColor: appFmGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Visites',
                  value: '${profile.visits}',
                  valueColor: appWarmOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ActionButton(
            label: 'Se déconnecter',
            backgroundColor: appClearBg,
            textColor: appMossText,
            onTap: () {
              controller.logout();
              onClose();
            },
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

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
      child: child,
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: appSearchGrey,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: appSuggHover,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: appSuggHover, thickness: 1.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: appSearchGrey,
            ),
          ),
        ),
        const Expanded(child: Divider(color: appSuggHover, thickness: 1.5)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: appSuggHover, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoogleLogo(),
            const SizedBox(width: 10),
            Text(
              'Continuer avec Google',
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: appFmDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = rect.center;
    final radius = size.width / 2;

    const segments = [
      (Color(0xFF4285F4), -0.3, 0.5),  // blue
      (Color(0xFF34A853), 0.5, 1.1),   // green
      (Color(0xFFFBBC05), 1.1, 1.6),   // yellow
      (Color(0xFFEA4335), 1.6, 2.4),   // red
    ];

    final paint = Paint()..style = PaintingStyle.fill;
    for (final (color, start, end) in segments) {
      paint.color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start * 3.14159,
        (end - start) * 3.14159,
        true,
        paint,
      );
    }

    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, paint);

    // "G" cut
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - radius * 0.18,
          radius * 0.9, radius * 0.36),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LargeAvatar extends StatelessWidget {
  const _LargeAvatar({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: const BoxDecoration(
        color: appLavender,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.fredoka(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: appMarkerInk,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: appSuggHover,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: appSearchGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
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
