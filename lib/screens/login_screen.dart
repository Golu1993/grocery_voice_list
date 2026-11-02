import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/auth_service.dart';

const _navy = Color(0xFF102B43);
const _green = Color(0xFF008E50);
const _muted = Color(0xFF718096);

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.signIn,
    this.setupStatus,
    this.setupError,
    this.onSetupRetry,
  });

  final Future<void> Function()? signIn;
  final String? setupStatus;
  final String? setupError;
  final VoidCallback? onSetupRetry;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSigningIn = false;
  String? _error;

  bool get _isSettingUp =>
      widget.setupStatus != null || widget.setupError != null;

  String? get _visibleError => widget.setupError ?? _error;

  Future<void> _handleSignIn() async {
    if (_isSigningIn) return;
    setState(() {
      _isSigningIn = true;
      _error = null;
    });
    try {
      await (widget.signIn ?? AuthService.signInWithGoogle)();
    } catch (error) {
      if (mounted) {
        final message = AuthService.errorMessage(error);
        setState(() => _error = message.isEmpty ? null : message);
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFCFDFC),
    body: SafeArea(
      child: Stack(
        children: [
          const Positioned(
            top: -160,
            left: -150,
            child: _SoftCircle(size: 300, color: Color(0xFFE8F6EA)),
          ),
          const Positioned(
            bottom: -155,
            right: -140,
            child: _SoftCircle(size: 280, color: Color(0xFFFFF1D7)),
          ),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 360,
                height: 730,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const _Brand(),
                      const SizedBox(height: 8),
                      const _ListsIllustration(),
                      const SizedBox(height: 8),
                      const Text(
                        'Lists for every part\nof your life',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _navy,
                          fontSize: 24,
                          height: 1.13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        height: 42,
                        child: Center(
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              _visibleError ??
                                  (_isSettingUp
                                      ? 'Preparing your Vocart account securely.'
                                      : 'Create any type of list, add items with voice,\nand share them as a PDF.'),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _visibleError == null
                                    ? _muted
                                    : const Color(0xFFB53828),
                                fontSize: _visibleError == null ? 12 : 11,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _Features(),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: _isSettingUp
                              ? (widget.setupError == null
                                    ? null
                                    : widget.onSetupRetry)
                              : (_isSigningIn ? null : _handleSignIn),
                          style: FilledButton.styleFrom(
                            backgroundColor: _green,
                            disabledBackgroundColor: _green.withValues(
                              alpha: 0.65,
                            ),
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            elevation: 6,
                            shadowColor: _green.withValues(alpha: 0.28),
                          ),
                          child: Row(
                            children: [
                              if (_isSettingUp)
                                Icon(
                                  widget.setupError == null
                                      ? Icons.cloud_upload_rounded
                                      : Icons.error_outline_rounded,
                                )
                              else
                                const _GoogleMark(),
                              Expanded(
                                child: Text(
                                  widget.setupError != null
                                      ? 'Retry setup'
                                      : widget.setupStatus ??
                                            'Continue with Google',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              widget.setupError != null
                                  ? const Icon(Icons.refresh_rounded)
                                  : (_isSigningIn || _isSettingUp)
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 20,
                            color: _muted,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Your data is safe and private',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _muted, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Voc',
                style: TextStyle(color: _navy),
              ),
              TextSpan(
                text: 'art',
                style: TextStyle(color: _green),
              ),
            ],
          ),
          style: TextStyle(
            fontSize: 46,
            fontWeight: FontWeight.w900,
            letterSpacing: -4,
            height: 1,
          ),
        ),
      ),
      SizedBox(height: 3),
      Text(
        'Speak. Add. Get things done.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _muted,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    ],
  );
}

class _ListsIllustration extends StatelessWidget {
  const _ListsIllustration();

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.85,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final cardWidth = math.min(width * 0.36, 150.0);
        final cardHeight = height * 0.63;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: width * 0.08,
              top: height * 0.18,
              child: _ListCard(
                label: 'Groceries',
                icon: Icons.shopping_cart_rounded,
                color: const Color(0xFFF5A500),
                background: const Color(0xFFFFF0BD),
                width: cardWidth,
                height: cardHeight,
                angle: -0.22,
              ),
            ),
            Positioned(
              right: width * 0.08,
              top: height * 0.20,
              child: _ListCard(
                label: 'To Do',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFFDE4249),
                background: const Color(0xFFFFE1E2),
                width: cardWidth,
                height: cardHeight,
                angle: 0.18,
              ),
            ),
            Positioned(
              left: width * 0.04,
              top: height * 0.42,
              child: _ListCard(
                label: 'Home',
                icon: Icons.home_rounded,
                color: const Color(0xFF168DE5),
                background: const Color(0xFFDDF1FF),
                width: cardWidth,
                height: cardHeight,
                angle: -0.16,
              ),
            ),
            Positioned(
              right: width * 0.04,
              top: height * 0.43,
              child: _ListCard(
                label: 'Travel',
                icon: Icons.flight_rounded,
                color: const Color(0xFF0C9859),
                background: const Color(0xFFDFF8E7),
                width: cardWidth,
                height: cardHeight,
                angle: 0.18,
              ),
            ),
            Positioned(
              left: (width - cardWidth) / 2,
              top: height * 0.39,
              child: _ListCard(
                label: 'Work',
                icon: Icons.work_rounded,
                color: const Color(0xFF6234D0),
                background: const Color(0xFFE9DFFF),
                width: cardWidth,
                height: cardHeight,
                angle: 0.03,
              ),
            ),
            Positioned(
              left: width * 0.07,
              right: width * 0.07,
              bottom: 0,
              height: height * 0.38,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA8E5AF), Color(0xFF72CC95)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3000874A),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: (width - height * 0.33) / 2,
              bottom: height * 0.01,
              width: height * 0.33,
              height: height * 0.33,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x22064835), blurRadius: 8),
                  ],
                ),
                child: Icon(
                  Icons.mic_rounded,
                  color: _green,
                  size: height * 0.20,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
    required this.width,
    required this.height,
    required this.angle,
  });
  final String label;
  final IconData icon;
  final Color color;
  final Color background;
  final double width;
  final double height;
  final double angle;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var row = 0; row < 2; row++) ...[
            Row(
              children: [
                Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    border: Border.all(color: color.withValues(alpha: 0.55)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
          ],
        ],
      ),
    ),
  );
}

class _Features extends StatelessWidget {
  const _Features();

  @override
  Widget build(BuildContext context) => const Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Feature(
        icon: Icons.mic_rounded,
        iconColor: _green,
        circleColor: Color(0xFFE1F7E5),
        title: 'Add with Voice',
        description: 'Just speak and it’s added.',
      ),
      _Feature(
        icon: Icons.people_alt_rounded,
        iconColor: Color(0xFF087FDC),
        circleColor: Color(0xFFE3F2FF),
        title: 'Stay Organized',
        description: 'Keep all your lists together.',
      ),
      _Feature(
        icon: Icons.picture_as_pdf_rounded,
        iconColor: Color(0xFFF15C2D),
        circleColor: Color(0xFFFFF0E0),
        title: 'Export & Share',
        description: 'Share your lists as a PDF.',
      ),
    ],
  );
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.iconColor,
    required this.circleColor,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final Color iconColor;
  final Color circleColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _navy,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 10, height: 1.2),
        ),
      ],
    ),
  );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 32,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
    child: const Text(
      'G',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
