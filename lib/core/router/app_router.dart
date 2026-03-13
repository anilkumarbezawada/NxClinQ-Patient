import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/splash/splash_screen.dart';

// ── Clinic Admin ──────────────────────────────────────────────────────────────
import '../../features/clinic_admin/shell/admin_shell.dart';
import '../../features/clinic_admin/dashboard/dashboard_screen.dart';
import '../../features/clinic_admin/doctors/doctors_screen.dart';
import '../../features/clinic_admin/doctors/add_doctor_screen.dart';
import '../../features/clinic_admin/patients/patients_screen.dart';
import '../../features/clinic_admin/patients/add_patient_screen.dart';
import '../../features/clinic_admin/reports/reports_screen.dart';
import '../../features/clinic_admin/profile/clinic_profile_screen.dart';

// ── Organiser Admin ───────────────────────────────────────────────────────────
import '../../features/organiser_admin/shell/org_shell.dart';
import '../../features/organiser_admin/dashboard/org_dashboard_screen.dart';
import '../../features/organiser_admin/clinics/clinics_screen.dart';
import '../../features/organiser_admin/clinics/create_clinic_screen.dart';
import '../../features/organiser_admin/doctors/org_doctors_screen.dart';
import '../../features/organiser_admin/doctors/add_org_doctor_screen.dart';
import '../../features/organiser_admin/doctors/set_calendar_screen.dart';
import '../../features/organiser_admin/profile/org_profile_screen.dart';
import '../../features/organiser_admin/models/org_dashboard_response.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _adminShellKey =
    GlobalKey<NavigatorState>(debugLabel: 'adminShell');
final GlobalKey<NavigatorState> _orgShellKey =
    GlobalKey<NavigatorState>(debugLabel: 'orgShell');

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      // 1. Wait until AuthProvider has finished checking SharedPreferences
      if (!authProvider.isInitialized) return '/splash';

      final isLoggedIn = authProvider.isLoggedIn;
      final loc = state.matchedLocation;
      final isLoggingIn = loc == '/login';
      final isSplash = loc == '/splash';

      // 2. If logged in, redirect away from splash/login based on role
      if (isLoggedIn && (isSplash || isLoggingIn)) {
        final role = authProvider.userRole;
        final isOrgAdmin = role == 'org_admin';
        return isOrgAdmin ? '/org/dashboard' : '/admin/dashboard';
      }

      // 3. Protect /org/* routes — only org_admin may access them
      if (isLoggedIn && loc.startsWith('/org')) {
        final role = authProvider.userRole;
        final isOrgAdmin = role == 'org_admin';
        if (!isOrgAdmin) return '/admin/dashboard';
      }

      // 4. If NOT logged in, let splash play; otherwise force login
      if (!isLoggedIn) {
        if (isSplash) return null;
        if (!isLoggingIn) return '/login';
      }

      return null;
    },
    refreshListenable: authProvider,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Clinic Admin Shell ────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _adminShellKey,
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/admin/doctors',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DoctorsScreen()),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const AddDoctorScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/admin/patients',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PatientsScreen()),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const AddPatientScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/admin/reports',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReportsScreen()),
          ),
          GoRoute(
            path: '/admin/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),

      // ── Organiser Admin Shell ─────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _orgShellKey,
        builder: (context, state, child) => OrgShell(child: child),
        routes: [
          GoRoute(
            path: '/org/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: OrgDashboardScreen()),
          ),
          GoRoute(
            path: '/org/clinics',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ClinicsScreen()),
          ),
          GoRoute(
            path: '/org/doctors',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: OrgDoctorsScreen()),
          ),
          GoRoute(
            path: '/org/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: OrgProfileScreen()),
          ),
        ],
      ),

      // ── Organiser Admin full-page routes (outside shell) ──────────────────
      GoRoute(
        path: '/org/clinics/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final existingClinic = state.extra as OrgClinic?;
          return CreateClinicScreen(existingClinic: existingClinic);
        },
      ),
      GoRoute(
        path: '/org/doctors/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddOrgDoctorScreen(),
      ),
      GoRoute(
        path: '/org/doctors/calendar',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SetCalendarScreen(),
      ),
    ],
  );
}

