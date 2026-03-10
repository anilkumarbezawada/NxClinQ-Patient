import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme/app_colors.dart';
import 'auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _lottieCtrl;

  // Entrance animations
  late AnimationController _entranceCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  
  // Background floating animation
  late AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();

    _lottieCtrl = AnimationController(vsync: this);
    
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _fadeAnim =
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _entranceCtrl, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _lottieCtrl.dispose();
    _entranceCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final error = await auth.login(_emailCtrl.text, _passCtrl.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      context.go('/admin/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 700;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Premium Violet Background ──
          Positioned.fill(
            child: Container(
              color: AppColors.surfaceLight, // Soft white/violet bg
            ),
          ),

          // ── Floating Decorative Elements ──
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
                        color: AppColors.primaryBrand.withValues(alpha: 0.15)),
                  ),
                  Positioned(
                    bottom: size.height * 0.1 - 15 * math.sin(t * math.pi),
                    left: -80 + 15 * math.cos(t * math.pi),
                    child: _GlowCircle(
                        size: 250,
                        color: AppColors.primaryBrandLight.withValues(alpha: 0.15)),
                  ),
                ],
              );
            },
          ),

          // ── Content Layout ──
          isWide ? _buildWide(context, size) : _buildMobile(context, size),
        ],
      ),
    );
  }

  // ── MOBILE LAYOUT ─────────────────────────────────────────────────────────

  Widget _buildMobile(BuildContext context, Size size) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Hero Section (Lottie) ──
              _buildHeroSection(140),

              const SizedBox(height: 48),

              // ── Glass Form Card ──
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBrand.withValues(alpha: 0.08),
                          blurRadius: 40,
                          spreadRadius: -5,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: _buildForm(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── WIDE / DESKTOP LAYOUT ─────────────────────────────────────────────────

  Widget _buildWide(BuildContext context, Size size) {
    return SafeArea(
      child: Row(
        children: [
          // Left: Hero panel
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeroSection(200),
              ],
            ),
          ),
          // Right: Glass Card
          Expanded(
            flex: 4,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(right: 60, left: 20),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBrand.withValues(alpha: 0.1),
                          blurRadius: 50,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: _buildForm(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HERO ASSET ────────────────────────────────────────────────────────────

  Widget _buildHeroSection(double imageSize) {
    return Column(
      children: [
        // Glass Circle for Lottie
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBrandLight.withValues(alpha: 0.1),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          //padding: const EdgeInsets.all(20),
          child: Lottie.asset(
            'assets/lottie/doctor_crm.json',
            controller: _lottieCtrl,
            fit: BoxFit.contain,
            onLoaded: (comp) {
              _lottieCtrl
                ..duration = comp.duration
                ..repeat();
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Doctor CRM',
          style: GoogleFonts.outfit(
            fontSize: imageSize > 150 ? 46 : 32,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryBrand,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Healthcare Management Platform',
          style: GoogleFonts.inter(
            fontSize: imageSize > 150 ? 15 : 13,
            color: AppColors.primaryBrand, // Primary Violet
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── FORM ELEMENTS ─────────────────────────────────────────────────────────

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Welcome Back',
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to access your dashboard',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 36),

          // Email Field
          _buildFieldLabel('EMAIL OR USERNAME'),
          _Field(
            controller: _emailCtrl,
            hint: 'E.g. admin@clinic.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Password Field
          _buildFieldLabel('PASSWORD'),
          _Field(
            controller: _passCtrl,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePass,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            suffix: GestureDetector(
              onTap: () => setState(() => _obscurePass = !_obscurePass),
              child: Icon(
                _obscurePass
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppColors.textSecondaryLight,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v.length < 4) return 'Too short';
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Error / Forgot Password
          if (_errorMessage != null)
            _ErrorBanner(message: _errorMessage!)
          else
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Forgot password?',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBrand, // Uses primary bright violet
                ),
              ),
            ),

          const SizedBox(height: 36),

          // Login Button
          _LoginButton(
            isLoading: _isLoading,
            onTap: _handleLogin,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBrand,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── SHARED WIDGETS ────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffix,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textPrimaryLight.withValues(alpha: 0.3),
        ),
        filled: true,
        fillColor: const Color(0xFFF9F7FF), // Extremely light violet-tinted field
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondaryLight),
        suffixIcon: suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primaryBrand.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryBrand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _LoginButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: AppColors.getPrimaryGradient(AppColors.primaryBrand).colors),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBrand.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'LOG IN TO SYSTEM',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
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
            blurRadius: 100,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}
