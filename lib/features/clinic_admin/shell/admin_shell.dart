import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/auth_provider.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  static const List<_NavItem> _navItems = [
    _NavItem(label: 'Doctors', icon: Icons.medical_services_rounded, path: '/admin/doctors'),
    _NavItem(label: 'Patients', icon: Icons.people_alt_rounded, path: '/admin/patients'),
    _NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, path: '/admin/dashboard'),
    _NavItem(label: 'Reports', icon: Icons.analytics_rounded, path: '/admin/reports'),
    _NavItem(label: 'Profile', icon: Icons.account_circle_rounded, path: '/admin/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].path)) return i;
    }
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    context.go(_navItems[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final currentIndex = _currentIndex(context);

    if (width >= 1200) {
      // Full sidebar for Desktop/Web
      return _WideLayout(
        navItems: _navItems,
        currentIndex: currentIndex,
        onNavigate: (i) => _navigate(context, i),
        child: child,
      );
    } else {
      // Bottom nav for Mobile and Tablet
      return _MobileLayout(
        navItems: _navItems,
        currentIndex: currentIndex,
        onNavigate: (i) => _navigate(context, i),
        child: child,
      );
    }
  }
}

// ── Mobile: Bottom Navigation ─────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final List<_NavItem> navItems;
  final int currentIndex;
  final void Function(int) onNavigate;
  final Widget child;

  const _MobileLayout({
    required this.navItems,
    required this.currentIndex,
    required this.onNavigate,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onNavigate,
          items: navItems
              .map((n) => BottomNavigationBarItem(
                    icon: Icon(n.icon),
                    label: n.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}


// ── Web/Desktop: Full Sidebar ─────────────────────────────────────────────────
class _WideLayout extends StatelessWidget {
  final List<_NavItem> navItems;
  final int currentIndex;
  final void Function(int) onNavigate;
  final Widget child;

  const _WideLayout({
    required this.navItems,
    required this.currentIndex,
    required this.onNavigate,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.read<AuthProvider>();

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDarkCard : Colors.white,
              border: Border(
                right: BorderSide(
                  color: theme.dividerTheme.color ?? Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Logo area
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: _SidebarLogo(compact: false),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 1),
                ),
                const SizedBox(height: 12),
                // Nav items
                ...navItems.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final isSelected = i == currentIndex;
                  return _SidebarItem(
                    item: item,
                    isSelected: isSelected,
                    onTap: () => onNavigate(i),
                  );
                }),
                const Spacer(),
                // User info at bottom
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            auth.userName.isNotEmpty
                                ? auth.userName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                auth.userName,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Clinic Admin',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 11,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected ? theme.colorScheme.primary : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          dense: true,
          onTap: onTap,
          leading: Icon(item.icon, color: color, size: 22),
          title: Text(
            item.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: color ?? theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _SidebarLogo extends StatelessWidget {
  final bool compact;
  const _SidebarLogo({required this.compact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (compact) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.local_hospital_rounded,
          color: Colors.white,
          size: 22,
        ),
      );
    }
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.local_hospital_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Doctor CRM',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            Text(
              'Clinic Management',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 11,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String path;
  const _NavItem({required this.label, required this.icon, required this.path});
}

