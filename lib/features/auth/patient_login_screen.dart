import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'patient_auth_provider.dart';

// ── Color palette for this screen (teal health theme) ─────────────────────────

// ── Flow Steps ────────────────────────────────────────────────────────────────
enum _AuthStep { mobile, otp, password }

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen>
    with TickerProviderStateMixin {
  _AuthStep _step = _AuthStep.mobile;

  // --- Mobile step ---
  final _mobileCtrl = TextEditingController(text: '');
  bool _isProfileVerified = false; // true = password login, false = first time
  bool _loadingMobile = false;
  String? _mobileError;

  // --- OTP step ---
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());
  bool _loadingOtp = false;
  String? _otpError;
  Timer? _countdownTimer;
  int _secondsRemaining = 180; // 3 minutes
  bool _canResend = false;

  // --- Password step ---
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loadingPass = false;
  String? _passError;

  // --- Animations ---
  late AnimationController _bgCtrl;
  late AnimationController _lottieCtrl;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _lottieCtrl = AnimationController(vsync: this);

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideCtrl.forward();
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _lottieCtrl.dispose();
    _slideCtrl.dispose();
    _mobileCtrl.dispose();
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final fn in _otpFocusNodes) {
      fn.dispose();
    }
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _fullMobile => '+91${_mobileCtrl.text.trim()}';

  void _startCountdown() {
    _secondsRemaining = 180;
    _canResend = false;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  String get _timerText {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _animateToNextStep(_AuthStep next) {
    _slideCtrl.reset();
    setState(() {
      _step = next;
      _mobileError = null;
      _otpError = null;
      _passError = null;
    });
    _slideCtrl.forward();
  }

  // ── Step 1: Check Mobile ──────────────────────────────────────────────────

  Future<void> _handleMobileSubmit() async {
    final raw = _mobileCtrl.text.trim();
    if (raw.length != 10 || !RegExp(r'^\d{10}$').hasMatch(raw)) {
      setState(() => _mobileError = 'Please enter a valid 10-digit mobile number.');
      return;
    }
    setState(() { _loadingMobile = true; _mobileError = null; });

    final auth = context.read<PatientAuthProvider>();
    final result = await auth.checkProfile(_fullMobile);

    if (!mounted) return;
    setState(() => _loadingMobile = false);

    if (result.error != null) {
      setState(() => _mobileError = result.error);
      return;
    }

    final verified = result.data!.isProfileVerified;
    _isProfileVerified = verified;

    if (verified) {
      // Existing patient → jump straight to password
      _animateToNextStep(_AuthStep.password);
    } else {
      // New patient → OTP flow
      _startCountdown();
      _animateToNextStep(_AuthStep.otp);
    }
  }

  // ── Step 2: Verify OTP ────────────────────────────────────────────────────

  String get _enteredOtp => _otpCtrls.map((c) => c.text).join();

  Future<void> _handleOtpSubmit() async {
    final otp = _enteredOtp;
    if (otp.length != 6) {
      setState(() => _otpError = 'Please enter the complete 6-digit OTP.');
      return;
    }
    setState(() { _loadingOtp = true; _otpError = null; });

    final auth = context.read<PatientAuthProvider>();
    final error = await auth.verifyOtp(_fullMobile, otp);

    if (!mounted) return;
    setState(() => _loadingOtp = false);

    if (error != null) {
      setState(() => _otpError = error);
      return;
    }

    _countdownTimer?.cancel();
    _animateToNextStep(_AuthStep.password);
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend) return;
    final auth = context.read<PatientAuthProvider>();
    final error = await auth.resendOtp(_fullMobile);
    if (!mounted) return;
    if (error != null) {
      setState(() => _otpError = error);
    } else {
      // Clear OTP boxes and restart timer
      for (final c in _otpCtrls) {
        c.clear();
      }
      _otpFocusNodes.first.requestFocus();
      _startCountdown();
    }
  }

  // ── Step 3: Password ──────────────────────────────────────────────────────

  String? _validatePassword(String pass) {
    if (pass.length < 8 || pass.length > 12) return 'Must be 8–12 characters.';
    if (!pass.contains(RegExp(r'[A-Z]'))) return 'Must include an uppercase letter.';
    if (!pass.contains(RegExp(r'[a-z]'))) return 'Must include a lowercase letter.';
    if (!pass.contains(RegExp(r'[0-9]'))) return 'Must include a number.';
    if (!pass.contains(RegExp(r'[@#$!]'))) return 'Must include only @, #, \$, or !';
    return null;
  }

  Future<void> _handlePasswordSubmit() async {
    final pass = _passCtrl.text;
    final validationErr = _validatePassword(pass);
    if (validationErr != null) {
      setState(() => _passError = validationErr);
      return;
    }
    // If first time (OTP flow), validate confirm match
    if (!_isProfileVerified && pass != _confirmPassCtrl.text) {
      setState(() => _passError = 'Passwords do not match.');
      return;
    }

    setState(() { _loadingPass = true; _passError = null; });

    final auth = context.read<PatientAuthProvider>();
    final error = await auth.login(
      mobile: _fullMobile,
      password: pass,
      isFirstTimeLogin: _isProfileVerified,
    );

    if (!mounted) return;
    setState(() => _loadingPass = false);

    if (error != null) {
      setState(() => _passError = error);
    } else {
      context.go('/patient/home');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Animated background blobs
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, _) {
              final t = _bgCtrl.value;
              return Stack(
                children: [
                  Positioned(
                    top: -120 + 30 * math.sin(t * math.pi),
                    right: -60 + 15 * math.cos(t * math.pi),
                    child: _blob(320, AppColors.primary.withValues(alpha: 0.18)),
                  ),
                  Positioned(
                    bottom: size.height * 0.05 - 20 * math.sin(t * math.pi),
                    left: -80 + 20 * math.cos(t * math.pi),
                    child: _blob(220, AppColors.primaryLight.withValues(alpha: 0.4)),
                  ),
                  Positioned(
                    top: size.height * 0.4 + 10 * math.cos(t * math.pi),
                    right: -40 + 10 * math.sin(t * math.pi),
                    child: _blob(150, AppColors.primaryDeep.withValues(alpha: 0.08)),
                  ),
                ],
              );
            },
          ),
          // Content
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: MediaQuery.paddingOf(context).top + 24,
                  bottom: MediaQuery.paddingOf(context).bottom + 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight -
                          (MediaQuery.paddingOf(context).top +
                              MediaQuery.paddingOf(context).bottom +
                              48),
                      maxWidth: 500,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeroSection(),
                        const SizedBox(height: 32),
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: _buildCard(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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

  Widget _buildHeroSection() {
    return Column(
      children: [
        // ── Premium NxClinq Text ──
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [
                AppColors.primaryLight,
                AppColors.primary,
                AppColors.primary,
                AppColors.primary,
                AppColors.primaryDeep,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: Text(
            'NxClinq',
            style: GoogleFonts.outfit(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
              shadows: [
                BoxShadow(
                  color: AppColors.primaryDeep.withValues(alpha: 0.2),
                  blurRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 1.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white),
          ),
          child: Text(
            'Your Health, Our Priority',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDeep,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 40,
            spreadRadius: -4,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: switch (_step) {
          _AuthStep.mobile  => _buildMobileStep(),
          _AuthStep.otp     => _buildOtpStep(),
          _AuthStep.password => _buildPasswordStep(),
        },
      ),
    );
  }

  // ── Step 1 UI ─────────────────────────────────────────────────────────────

  Widget _buildMobileStep() {
    return Column(
      key: const ValueKey('mobile'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Welcome!', 'Enter your registered mobile number'),
        const SizedBox(height: 28),
        _fieldLabel('MOBILE NUMBER'),
        Row(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '+91',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDeep,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTextField(
                controller: _mobileCtrl,
                hint: '10 digit mobile number',
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onSubmit: _handleMobileSubmit,
              ),
            ),
          ],
        ),
        if (_mobileError != null) ...[
          const SizedBox(height: 10),
          _errorBanner(_mobileError!),
        ],
        const SizedBox(height: 32),
        _primaryButton(
          label: 'CONTINUE',
          isLoading: _loadingMobile,
          onTap: _handleMobileSubmit,
        ),
      ],
    );
  }

  // ── Step 2 UI ─────────────────────────────────────────────────────────────

  Widget _buildOtpStep() {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Verify OTP', 'A 6-digit OTP was sent to $_fullMobile'),
        const SizedBox(height: 28),
        _fieldLabel('ENTER OTP'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _otpBox(i)),
        ),
        if (_otpError != null) ...[
          const SizedBox(height: 10),
          _errorBanner(_otpError!),
        ],
        const SizedBox(height: 20),
        // Timer / Resend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_canResend) ...[
              const Icon(Icons.timer_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                'Resend in $_timerText',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else ...[
              GestureDetector(
                onTap: _handleResendOtp,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primaryDeep),
                      const SizedBox(width: 6),
                      Text(
                        'Resend OTP',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 28),
        _primaryButton(
          label: 'VERIFY OTP',
          isLoading: _loadingOtp,
          onTap: _handleOtpSubmit,
        ),
        const SizedBox(height: 16),
        _textButton(
          'Change number',
          onTap: () {
            _countdownTimer?.cancel();
            _animateToNextStep(_AuthStep.mobile);
          },
        ),
      ],
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextFormField(
        controller: _otpCtrls[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          }
          if (val.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
          if (index == 5 && val.isNotEmpty) {
            _handleOtpSubmit();
          }
        },
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDeep,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFF0FAFB),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  // ── Step 3 UI ─────────────────────────────────────────────────────────────

  Widget _buildPasswordStep() {
    final isFirstTime = !_isProfileVerified;
    return Column(
      key: const ValueKey('password'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          isFirstTime ? 'Create Password' : 'Welcome Back!',
          isFirstTime
              ? 'Set a secure password for your account'
              : 'Enter your password to sign in',
        ),
        const SizedBox(height: 28),
        _fieldLabel('PASSWORD'),
        _buildTextField(
          controller: _passCtrl,
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscure: _obscurePass,
          suffix: _eyeToggle(_obscurePass, () => setState(() => _obscurePass = !_obscurePass)),
          onSubmit: isFirstTime ? null : _handlePasswordSubmit,
        ),
        if (isFirstTime) ...[
          const SizedBox(height: 16),
          _fieldLabel('CONFIRM PASSWORD'),
          _buildTextField(
            controller: _confirmPassCtrl,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscure: _obscureConfirm,
            suffix: _eyeToggle(_obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
            onSubmit: _handlePasswordSubmit,
          ),
          const SizedBox(height: 12),
          _passwordRules(),
        ],
        if (_passError != null) ...[
          const SizedBox(height: 10),
          _errorBanner(_passError!),
        ],
        const SizedBox(height: 28),
        _primaryButton(
          label: isFirstTime ? 'CREATE ACCOUNT' : 'SIGN IN',
          isLoading: _loadingPass,
          onTap: _handlePasswordSubmit,
        ),
        const SizedBox(height: 12),
        _textButton('<- Back to mobile entry', onTap: () => _animateToNextStep(_AuthStep.mobile)),
      ],
    );
  }

  Widget _passwordRules() {
    const rules = [
      '8–12 characters',
      'One uppercase & lowercase letter',
      'One number (0-9)',
      'One special character: @  #  \$  !',
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password requirements:',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDeep,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...rules.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    r,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared Widgets ────────────────────────────────────────────────────────

  Widget _stepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step progress dots
        Row(
          children: [
            _stepDot(_step.index >= 0),
            const SizedBox(width: 6),
            _stepDot(_step.index >= 1),
            const SizedBox(width: 6),
            _stepDot(_step.index >= 2),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _stepDot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onSubmit,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction:
          onSubmit != null ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: onSubmit != null ? (_) => onSubmit() : null,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textMain,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textMuted.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: const Color(0xFFF0FAFB),
        prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
        suffixIcon: suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
            : null,
        suffixIconConstraints:
            suffix != null ? const BoxConstraints(minWidth: 40, minHeight: 40) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.25), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _eyeToggle(bool obscure, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
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
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.8,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _textButton(String label, {required VoidCallback onTap}) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.redAccent,
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
