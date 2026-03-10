import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  
  // Entrance animations
  late AnimationController _entranceCtrl;
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subFade;
  late Animation<Offset> _subSlide;
  
  // Background floating animation
  late AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    
    // Background Floating Animation
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Staggered Entrance Animations
    _entranceCtrl = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 2800), // Increased overall time
    );
        
    // Logo comes in first 
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)),
    );

    // Title comes in second (starts much later)
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.4, 0.7, curve: Curves.easeOut)),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero).animate( // Slides from much lower
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.4, 0.7, curve: Curves.easeOutCubic)),
    );

    // Subtitle comes in last (starts after title)
    _subFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );
    _subSlide = Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero).animate( // Slides from much lower
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic)),
    );

    // Start animations slightly after the first frame to prevent dropping beginning of animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _entranceCtrl.forward().then((_) {
            // Route to login after animations finish, holding for a brief moment
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) context.go('/login');
            });
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight, // Soft white/violet bg
      body: Stack(
        children: [
          // ── Floating Decorative Elements (Matching Login) ──
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (context, _) {
              final t = _bgCtrl.value;
              return Stack(
                children: [
                  Positioned(
                    top: -100 + 20 * math.sin(t * math.pi),
                    right: -50 + 10 * math.cos(t * math.pi),
                    child: _GlowCircle(
                      size: 350,
                      color: AppColors.primaryBrand.withValues(alpha: 0.25), // Increased stroke opacity
                    ),
                  ),
                  Positioned(
                    bottom: size.height * 0.1 - 15 * math.sin(t * math.pi),
                    left: -80 + 15 * math.cos(t * math.pi),
                    child: _GlowCircle(
                      size: 250,
                      color: AppColors.primaryBrandLight.withValues(alpha: 0.25), // Increased stroke opacity
                    ),
                  ),
                ],
              );
            },
          ),
          
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo Animation ──
                  FadeTransition(
                    opacity: _logoFade,
                    child: SlideTransition(
                      position: _logoSlide,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6), // Glass effect
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBrandLight.withValues(alpha: 0.15),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        // Removed padding so the logo can fill the circle
                        child: Center(
                          child: Transform.scale(
                            scale: 4, // <--- Increases the size of the inner logo
                            child: Lottie.asset(
                              'assets/lottie/doctor_crm.json',
                              fit: BoxFit.contain,
                              animate: true,
                              repeat: true,
                            ),
                          ),
                        ),
                      ),

                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // ── Typography Title Animation ──
                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: Text(
                        'Doctor CRM',
                        style: GoogleFonts.outfit(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryLight,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // ── Subtitle Animation ──
                  FadeTransition(
                    opacity: _subFade,
                    child: SlideTransition(
                      position: _subSlide,
                      child: Text(
                        'Healthcare Management Platform',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBrand,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 120, // Huge blur for smooth background blend
            spreadRadius: 30,
          ),
        ],
      ),
    );
  }
}
