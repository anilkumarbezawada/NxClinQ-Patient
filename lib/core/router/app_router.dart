import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/clinic_admin/shell/admin_shell.dart';
import '../../features/clinic_admin/dashboard/dashboard_screen.dart';
import '../../features/clinic_admin/doctors/doctors_screen.dart';
import '../../features/clinic_admin/doctors/add_doctor_screen.dart';
import '../../features/clinic_admin/patients/patients_screen.dart';
import '../../features/clinic_admin/patients/add_patient_screen.dart';
import '../../features/clinic_admin/reports/reports_screen.dart';
import '../../features/clinic_admin/profile/profile_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

GoRouter createRouter(AuthProvider authProvider) {

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      // 1. Wait until AuthProvider has finished checking SharedPreferences
      if (!authProvider.isInitialized) return '/splash';

      final isLoggedIn = authProvider.isLoggedIn;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/splash';

      // 2. If logged in, skip splash and login -> go straight to dashboard
      if (isLoggedIn && (isSplash || isLoggingIn)) {
        return '/admin/dashboard';
      }

      // 3. If NOT logged in, let splash finish its animations, 
      //    otherwise force them to login screen
      if (!isLoggedIn) {
        if (isSplash) return null; // allow splash screen to play
        if (!isLoggingIn) return '/login'; // protect all other routes
      }

      return null; // No redirect needed
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
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/doctors',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DoctorsScreen(),
            ),
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
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PatientsScreen(),
            ),
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
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReportsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

