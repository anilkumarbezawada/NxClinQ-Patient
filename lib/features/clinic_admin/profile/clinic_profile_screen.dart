import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.getPrimaryGradient(themeProvider.seedColor)),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Profile & Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.2)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Premium Profile Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark 
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: theme.brightness == Brightness.light ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ] : null,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Decorative abstract circles in background
                Positioned(
                  top: -10,
                  right: -10,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  right: 20,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                // Content
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Text(
                          auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : 'A',
                          style: TextStyle(color: theme.colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  auth.userName,
                                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 3),
                                    Text(
                                      _formatRole(auth.userRole),
                                      style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auth.userEmail,
                            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          if (auth.activeClinicName.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.business_rounded, color: theme.colorScheme.primary, size: 12),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    auth.activeClinicName,
                                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Theme mode section
          _SectionHeader('Appearance'),
          const SizedBox(height: 14),
          _SettingsCard(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      Icon(Icons.brightness_6_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text('Theme Mode', style: theme.textTheme.titleMedium),
                      const Spacer(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: ThemeMode.values.map((mode) {
                      final labels = ['System', 'Light', 'Dark'];
                      final icons = [Icons.brightness_auto_rounded, Icons.light_mode_rounded, Icons.dark_mode_rounded];
                      final isSelected = themeProvider.themeMode == mode;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: mode.index == 0 ? 0 : 8),
                          child: GestureDetector(
                            onTap: () => themeProvider.setThemeMode(mode),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icons[mode.index],
                                      color: isSelected ? Colors.white : theme.colorScheme.primary, size: 20),
                                  const SizedBox(height: 4),
                                  Text(
                                    labels[mode.index],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                // Color picker
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.palette_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Text('Accent Color', style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        children: AppColors.seedColors.asMap().entries.map((entry) {
                          final index = entry.key;
                          final color = entry.value;
                          final isSelected = themeProvider.seedColor.toARGB32() == color.toARGB32();
                          
                          return GestureDetector(
                            onTap: () => themeProvider.setSeedColor(color),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? theme.colorScheme.onSurface : Colors.transparent,
                                      width: 2.5,
                                    ),
                                    boxShadow: isSelected
                                        ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 2)]
                                        : [],
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                                      : null,
                                ),
                                if (index == 0) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Default',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Account section
          _SectionHeader('Account'),
          const SizedBox(height: 14),
          _SettingsCard(
            child: Column(
              children: [
                _SettingsTile(icon: Icons.person_outline_rounded, label: 'Edit Profile', onTap: () {}),
                const Divider(height: 1, indent: 56),
                _SettingsTile(icon: Icons.lock_outline_rounded, label: 'Change Password', onTap: () {}),
                const Divider(height: 1, indent: 56),
                _SettingsTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsCard(
            child: Column(
              children: [
                _SettingsTile(icon: Icons.info_outline_rounded, label: 'About App', onTap: () {}),
                const Divider(height: 1, indent: 56),
                _SettingsTile(icon: Icons.help_outline_rounded, label: 'Help & Support', onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sign Out button
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _confirmLogout(context, auth),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Doctor CRM v1.0.0',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatRole(String role) {
    switch (role) {
      case 'clinic_admin': return '✦ Clinic Administrator';
      case 'doctor':       return '✦ Doctor';
      case 'patient':      return '✦ Patient';
      default:             return role.isNotEmpty ? '✦ ${role.replaceAll('_', ' ')}' : '✦ Staff';
    }
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
          titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          title: const Text('Log Out?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true && context.mounted) {
      await auth.logout();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 11,
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary, size: 22),
      title: Text(label, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15)),
      trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
      onTap: onTap,
    );
  }
}

