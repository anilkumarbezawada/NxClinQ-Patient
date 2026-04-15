import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/ai_bot_icon.dart';

// ── Color palette ─────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF00BFA5);
const _kPrimaryDeep = Color(0xFF00897B);
const _kSurface = Color(0xFFF0FBFF);
const _kInactive = Color(0xFFB0BEC5);

class PatientShell extends StatelessWidget {
  final Widget child;
  const PatientShell({super.key, required this.child});

  static const _tabs = [
    _ShellTab(label: 'Doctors', icon: Icons.medical_services_outlined, activeIcon: Icons.medical_services_rounded, path: '/patient/home'),
    _ShellTab(label: 'Appointments', icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, path: '/patient/appointments'),
    // AI button placeholder (index -1)
    _ShellTab(label: 'Vitals', icon: Icons.favorite_outline_rounded, activeIcon: Icons.favorite_rounded, path: '/patient/vitals'),
    _ShellTab(label: 'Profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, path: '/patient/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/patient/ai-assistant')) return -1; // AI tab
    for (int i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kSurface,
      body: child,
      // Solid professional bottom bar with rounded top
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Solid Container (Bar Background)
          Container(
            height: 85 + bottomPadding,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
          ),
          
          // 2. Navigation Items Layer
          SafeArea(
            top: false,
            child: SizedBox(
              height: 85,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildTab(_tabs[0], 0 == current, () => context.go(_tabs[0].path))),
                    Expanded(child: _buildTab(_tabs[1], 1 == current, () => context.go(_tabs[1].path))),
                    
                    // AI Bot centered INSIDE the bar
                    _AiFloatingButton(
                      isActive: current == -1,
                      onTap: () => context.go('/patient/ai-assistant'),
                    ),

                    Expanded(child: _buildTab(_tabs[2], 2 == current, () => context.go(_tabs[2].path))),
                    Expanded(child: _buildTab(_tabs[3], 3 == current, () => context.go(_tabs[3].path))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(_ShellTab tab, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? tab.activeIcon : tab.icon,
              color: isActive ? _kPrimaryDeep : _kInactive,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? _kPrimaryDeep : _kInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Floating AI Button (Raised, Glowing Center FAB) ──────────────────────────
class _AiFloatingButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _AiFloatingButton({required this.isActive, required this.onTap});

  @override
  State<_AiFloatingButton> createState() => _AiFloatingButtonState();
}

class _AiFloatingButtonState extends State<_AiFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _glowCtrl,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnim.value,
                  child: Transform.translate(
                    offset: const Offset(0, -6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: widget.isActive ? 66 : 62,
                      height: widget.isActive ? 66 : 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: _kPrimary.withValues(
                              alpha: widget.isActive ? 0.18 : 0.08,
                            ),
                            blurRadius: widget.isActive ? 18 : 12,
                            spreadRadius: widget.isActive ? 2 : 0,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: AiBotIcon(
                          size: widget.isActive ? 66 : 62,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ShellTab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
  const _ShellTab({required this.label, required this.icon, required this.activeIcon, required this.path});
}
