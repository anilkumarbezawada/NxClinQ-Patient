import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/auth_provider.dart';
import '../models/org_dashboard_response.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/shimmer_loading.dart';

class OrgDashboardScreen extends StatefulWidget {
  const OrgDashboardScreen({super.key});

  @override
  State<OrgDashboardScreen> createState() => _OrgDashboardScreenState();
}

class _OrgDashboardScreenState extends State<OrgDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<Animation<double>> _cardAnims = [];
  late Future<OrgDashboardResponse> _dashboardFuture;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    for (int i = 0; i < 3; i++) {
      _cardAnims.add(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(i * 0.15, 0.65 + i * 0.1, curve: Curves.easeOutCubic),
        ),
      );
    }
    _animController.forward();
  }

  Future<void> _fetchData() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final future = ApiService.instance.getOrgDashboardOverview();
      setState(() {
        _dashboardFuture = future;
      });
      await future;
    } catch (e) {
      if (!mounted) return;
      final errorString = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorString),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _isFetching = false;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<OrgDashboardResponse>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const DashboardShimmerLayout();
          }

          final data = snapshot.data?.data;
          final orgName = data?.orgName ?? 'Organisation Name';
          final stats = data?.overview;

          return NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                // App Bar
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  expandedHeight: 0,
                  toolbarHeight: 64,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.getPrimaryGradient(themeProvider.seedColor),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              orgName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '✦ Organiser Dashboard',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : 'O',
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
              ];
            },
            body: RefreshIndicator(
              onRefresh: _fetchData,
              color: const Color(0xFF0EA5E9),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Welcome banner
                      _WelcomeBanner(userName: auth.userName),
                      const SizedBox(height: 24),

                      // Stat cards
                      _buildStatCards(context, stats),
                      const SizedBox(height: 28),

                      // Quick actions
                      Text(
                        'Quick Actions',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 14),
                      _QuickActions(),
                      const SizedBox(height: 28),

                      // Recent clinics header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Clinics',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          TextButton(
                            onPressed: () => context.go('/org/clinics'),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _RecentClinicsList(
                        clinics: stats?.clinics ?? [],
                        onRefresh: _fetchData,
                      ),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
            ),
          );
      },
      ),
    );
  }

  Widget _buildStatCards(BuildContext context, OrgOverview? stats) {
    final clinicCount = stats?.clinics.length ?? 0;
    final doctorCount = stats?.doctors.length ?? 0;

    final cards = [
      _StatCardData(
        icon: Icons.local_hospital_rounded,
        label: 'Total Clinics',
        value: clinicCount.toString(),
        sub: 'Added to org',
        gradient: const [Color(0xFF0369A1), Color(0xFF0EA5E9)],
        onTap: () => context.go('/org/clinics'),
      ),
      _StatCardData(
        icon: Icons.medical_services_rounded,
        label: 'Total Doctors',
        value: doctorCount.toString(),
        sub: 'Across clinics',
        gradient: const [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
        onTap: () => context.go('/org/doctors'),
      ),
      _StatCardData(
        icon: Icons.pending_actions_rounded,
        label: 'Pending Requests',
        value: '3',
        sub: 'Needs attention',
        gradient: [const Color(0xFFD97706), const Color(0xFFF59E0B)],
        onTap: () {},
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
      childAspectRatio: 1.7,
      children: cards.take(2).toList().asMap().entries
          .map((e) => _animatedCard(e.key, e.value))
          .toList(),
    );
  }

  Widget _animatedCard(int i, _StatCardData data) {
    final anim = i < _cardAnims.length ? _cardAnims[i] : null;
    if (anim == null) return _StatCard(data: data);
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: Offset(0, 20 * (1 - anim.value)), child: child),
      ),
      child: _StatCard(data: data),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final String userName;
  const _WelcomeBanner({required this.userName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0C4A6E), const Color(0xFF0369A1)]
              : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF0EA5E9).withValues(alpha: 0.3)
              : const Color(0xFF7DD3FC),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.waving_hand_rounded, color: Color(0xFF0EA5E9), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $userName!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0C4A6E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage your organisation, clinics and doctors',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? const Color(0xFF7DD3FC)
                        : const Color(0xFF0369A1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                padding: const EdgeInsets.only(top: 8),
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
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.sub,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
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
      _QuickAction(
        label: 'Create Clinic',
        icon: Icons.add_business_rounded,
        color: const Color(0xFF0EA5E9),
        onTap: () => context.push('/org/clinics/create'),
      ),
      _QuickAction(
        label: 'Add Doctor',
        icon: Icons.person_add_rounded,
        color: const Color(0xFF8B5CF6),
        onTap: () => context.push('/org/doctors/add'),
      ),
      _QuickAction(
        label: 'View Clinics',
        icon: Icons.local_hospital_rounded,
        color: AppColors.success,
        onTap: () => context.go('/org/clinics'),
      ),
      _QuickAction(
        label: 'Org Profile',
        icon: Icons.settings_rounded,
        color: AppColors.warning,
        onTap: () => context.go('/org/profile'),
      ),
    ];

    return Row(
      children: actions.asMap().entries.map((e) {
        final a = e.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: e.key == 0 ? 0 : 10),
            child: GestureDetector(
              onTap: a.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: a.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: a.color.withValues(alpha: 0.15)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(a.icon, color: a.color, size: 28),
                    const SizedBox(height: 6),
                    Text(
                      a.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
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

class _RecentClinicsList extends StatelessWidget {
  final List<OrgClinic> clinics;
  final VoidCallback onRefresh;
  const _RecentClinicsList({required this.clinics, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (clinics.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/no_clinics.png',
              width: 140,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.business_rounded, size: 64, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'No clinics were created.',
              style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    // Show up to 3 most recent clinics (assuming API returns latest first, or just take first 3)
    final displayList = clinics.take(3).toList();

    return Column(
      children: displayList.map((c) => _ClinicCard(
        item: c,
        onRefresh: onRefresh,
      )).toList(),
    );
  }
}

class _ClinicCard extends StatelessWidget {
  final OrgClinic item;
  final VoidCallback onRefresh;
  const _ClinicCard({required this.item, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    final doctorsCountStr = item.avalibleDoctors?.toString() ?? '0';
    final doctorsCount = int.tryParse(doctorsCountStr) ?? 0;
    final doctorText = doctorsCount == 0 ? 'No doctors' : '$doctorsCount Doctors';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark 
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: theme.brightness == Brightness.light ? [
          BoxShadow(
            color: themeProvider.seedColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ] : null,
        border: Border.all(
          color: themeProvider.seedColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: themeProvider.seedColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.getPrimaryGradient(themeProvider.seedColor),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.seedColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_city_rounded, size: 14, color: themeProvider.seedColor.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Text(
                            item.clinicLocation,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: themeProvider.seedColor,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.medical_services_rounded, size: 14, color: themeProvider.seedColor.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Text(
                            doctorText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: themeProvider.seedColor,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _StatCardData {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _StatCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.gradient,
    required this.onTap,
  });
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
