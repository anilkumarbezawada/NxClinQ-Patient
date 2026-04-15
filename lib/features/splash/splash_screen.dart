import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Background floating animation
  late AnimationController _bgCtrl;

  // Text animations
  late AnimationController _textCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _shimmerAnim;

  // Subtitle animation
  late Animation<double> _subFade;
  late Animation<Offset> _subSlide;

  @override
  void initState() {
    super.initState();

    // Background Floating Animation
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Text & Subtitle Animations
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _shimmerAnim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOutSine),
      ),
    );

    _subFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
      ),
    );

    _subSlide = Tween<Offset>(begin: const Offset(0, 1.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _textCtrl.forward().then((_) {
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) context.go('/login');
            });
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // ── Background Blobs ──
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (context, _) {
              final t = _bgCtrl.value;
              return Stack(
                children: [
                  Positioned(
                    top: -100 + 30 * math.sin(t * math.pi),
                    right: -50 + 15 * math.cos(t * math.pi),
                    child: _blob(350, AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  Positioned(
                    bottom: size.height * 0.1 - 20 * math.sin(t * math.pi),
                    left: -80 + 20 * math.cos(t * math.pi),
                    child: _blob(280, AppColors.primaryLight.withValues(alpha: 0.35)),
                  ),
                  Positioned(
                    top: size.height * 0.4 + 10 * math.cos(t * math.pi),
                    right: -40 + 10 * math.sin(t * math.pi),
                    child: _blob(150, AppColors.primaryDeep.withValues(alpha: 0.1)),
                  ),
                ],
              );
            },
          ),

          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _textCtrl,
                builder: (context, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Premium NxClinq Text ──
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Transform.scale(
                          scale: _scaleAnim.value,
                          child: ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: const [
                                  AppColors.primaryDeep,
                                  AppColors.primary,
                                  AppColors.white,
                                  AppColors.primary,
                                  AppColors.primaryDeep,
                                ],
                                stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                                begin: Alignment(_shimmerAnim.value - 1, 0),
                                end: Alignment(_shimmerAnim.value + 1, 0),
                              ).createShader(bounds);
                            },
                            child: Text(
                              'NxClinq',
                              style: GoogleFonts.outfit(
                                fontSize: 64,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -2.0,
                                shadows: [
                                  BoxShadow(
                                    color: AppColors.primaryDeep.withValues(alpha: 0.3),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Subtitle ──
                      FadeTransition(
                        opacity: _subFade,
                        child: SlideTransition(
                          position: _subSlide,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.white),
                            ),
                            child: Text(
                              'Your Health, Our Priority',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDeep,
                                letterSpacing: 2.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 20)],
      ),
    );
  }
}
