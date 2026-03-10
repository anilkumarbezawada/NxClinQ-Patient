import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<Animation<double>> _cardAnims = [];

  final List<_AppointmentItem> _appointments = const [
    _AppointmentItem('Dr. Priya Sharma', 'Cardiology', '09:00 AM', 'Rahul Gupta', AppColors.success),
    _AppointmentItem('Dr. Arjun Mehta', 'Orthopedics', '10:30 AM', 'Sneha Patel', AppColors.warning),
    _AppointmentItem('Dr. Kavya Nair', 'Neurology', '11:00 AM', 'Vikram Singh', Color(0xFF4CC9F0)),
    _AppointmentItem('Dr. Rohan Das', 'Dermatology', '12:30 PM', 'Ananya Roy', AppColors.success),
    _AppointmentItem('Dr. Priya Sharma', 'Cardiology', '02:00 PM', 'Mohan Lal', AppColors.error),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    for (int i = 0; i < 4; i++) {
      _cardAnims.add(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(i * 0.12, 0.6 + i * 0.1, curve: Curves.easeOutCubic),
        ),
      );
    }
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 0,
            toolbarHeight: 64,
            backgroundColor: AppColors.primaryBrand,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: AppColors.getPrimaryGradient(theme.colorScheme.primary)),
              ),
            ),
            title: Row(
              children: [
                // Left: greeting + clinic name + role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        auth.activeClinicName.isNotEmpty
                            ? auth.activeClinicName
                            : 'Dashboard',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatRole(auth.userRole),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Avatar with user initial
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
            elevation: 0,
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                
                // Stat cards section
                _StatCardsGrid(cardAnims: _cardAnims),
                const SizedBox(height: 28),

                // Quick actions
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                _QuickActions(),
                const SizedBox(height: 28),

                // Today's appointments
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Appointments",
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    TextButton(
                      onPressed: () => context.go('/admin/reports'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ..._appointments.map((a) => _AppointmentCard(item: a)),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
  /// Converts a raw role string from the API into a human-friendly label.
  String _formatRole(String role) {
    switch (role) {
      case 'clinic_admin': return '✦ Clinic Administrator';
      case 'doctor':       return '✦ Doctor';
      case 'patient':      return '✦ Patient';
      default:             return role.isNotEmpty ? '✦ ${role.replaceAll('_', ' ')}' : '✦ Staff';
    }
  }
}

class _StatCardsGrid extends StatelessWidget {
  final List<Animation<double>> cardAnims;
  const _StatCardsGrid({required this.cardAnims});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCardData(
        icon: Icons.medical_services_rounded,
        label: 'Registered Doctors',
        value: '12',
        sub: '+2 this month',
        color: const Color(0xFF6366F1), // Custom accent color
        gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Vibrant purple gradient
        onTap: () => context.go('/admin/doctors'),
      ),
      _StatCardData(
        icon: Icons.people_alt_rounded,
        label: 'Total Patients',
        value: '248',
        sub: '+14 this week',
        color: AppColors.success,
        gradient: [const Color(0xFF059669), const Color(0xFF10B981)],
        onTap: () => context.go('/admin/patients'),
      ),
      _StatCardData(
        icon: Icons.calendar_today_rounded,
        label: "Today's Appointments",
        value: '18',
        sub: '5 pending confirmation',
        color: AppColors.warning,
        gradient: [const Color(0xFFD97706), const Color(0xFFF59E0B)],
        onTap: () => context.go('/admin/reports'),
      ),
      _StatCardData(
        icon: Icons.description_rounded,
        label: 'Pending Reports',
        value: '4',
        sub: '2 urgent',
        color: AppColors.error,
        gradient: [const Color(0xFFB91C1C), const Color(0xFFEF4444)],
        onTap: () => context.go('/admin/reports'),
      ),
    ];

    final isWide = MediaQuery.sizeOf(context).width > 800;
    if (isWide) {
      return Row(
        children: cards.asMap().entries.map((e) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: e.key == 0 ? 0 : 12),
              child: _animatedCard(e.key, e.value),
            ),
          );
        }).toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: cards.asMap().entries.map((e) => _animatedCard(e.key, e.value)).toList(),
    );
  }

  Widget _animatedCard(int i, _StatCardData data) {
    final anim = i < cardAnims.length ? cardAnims[i] : null;
    if (anim == null) return _StatCard(data: data);
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        return Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - anim.value)),
            child: child,
          ),
        );
      },
      child: _StatCard(data: data),
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: data.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: data.gradient.first.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: Colors.white, size: 20),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 8), // slightly lower to balance with icon
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      data.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      data.label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.sub,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(label: 'Add Doctor', icon: Icons.person_add_rounded, color: AppColors.primaryBrand, path: '/admin/doctors/add'),
      _QuickAction(label: 'Add Patient', icon: Icons.personal_injury_rounded, color: AppColors.success, path: '/admin/patients/add'),
      _QuickAction(label: 'View Reports', icon: Icons.bar_chart_rounded, color: AppColors.warning, path: '/admin/reports'),
      _QuickAction(label: 'Settings', icon: Icons.settings_rounded, color: AppColors.info, path: '/admin/profile'),
    ];

    return Row(
      children: actions.map((a) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: actions.indexOf(a) == 0 ? 0 : 10),
            child: GestureDetector(
              onTap: () => context.go(a.path),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: a.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: a.color.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(a.icon, color: a.color, size: 24),
                    const SizedBox(height: 6),
                    Text(
                      a.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: a.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final _AppointmentItem item;
  const _AppointmentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: item.color.withValues(alpha: 0.12),
            child: Icon(Icons.person_rounded, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.doctorName,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
                Text(
                  '${item.specialty} · ${item.patientName}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.time,
              style: TextStyle(
                color: item.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardData {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _StatCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.gradient,
    required this.onTap,
  });
}

class _AppointmentItem {
  final String doctorName;
  final String specialty;
  final String time;
  final String patientName;
  final Color color;

  const _AppointmentItem(
      this.doctorName, this.specialty, this.time, this.patientName, this.color);
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final String path;
  const _QuickAction({required this.label, required this.icon, required this.color, required this.path});
}

