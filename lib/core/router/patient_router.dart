import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:patient_crm/features/auth/patient_auth_provider.dart';
import 'package:patient_crm/features/auth/patient_login_screen.dart';
import 'package:patient_crm/features/splash/splash_screen.dart';
import 'package:patient_crm/features/patient/shell/patient_shell.dart';
import 'package:patient_crm/features/patient/profile/patient_profile_screen.dart';
import 'package:patient_crm/features/patient/appointments/patient_appointments_screen.dart';
import 'package:patient_crm/features/patient/booking/doctor_picker_screen.dart';
import 'package:patient_crm/features/patient/booking/doctor_booking_screen.dart';
import 'package:patient_crm/features/patient/ai_assistant/ai_assistant_screen.dart';
import 'package:patient_crm/features/patient/models/doctor_list_response.dart';
import 'package:patient_crm/features/patient/models/patient_profile_response.dart';
import 'package:patient_crm/features/patient/vitals/vitals_tracking_screen.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _patientShellKey = GlobalKey<NavigatorState>(debugLabel: 'patientShell');

GoRouter createPatientRouter(PatientAuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: authProvider,
    redirect: (context, state) {
      if (!authProvider.isInitialized) return '/splash';

      final isLoggedIn = authProvider.isLoggedIn;
      final loc = state.matchedLocation;
      final atLogin = loc == '/login';
      final atSplash = loc == '/splash';

      // Logged in → redirect away from auth screens
      if (isLoggedIn && (atLogin || atSplash)) return '/patient/home';

      // Not logged in → force login
      if (!isLoggedIn) {
        if (atSplash) return null;
        if (!atLogin) return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const PatientLoginScreen(),
      ),

      // ── Patient Shell ─────────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _patientShellKey,
        builder: (context, state, child) => PatientShell(child: child),
        routes: [
          GoRoute(
            path: '/patient/home',
            pageBuilder: (context, state) {
              final auth = context.read<PatientAuthProvider>();
              final patient = PatientProfile(
                id: auth.userId,
                name: auth.patientName,
                mobileNumber: auth.mobileNumber,
                emailId: auth.patientEmail,
              );
              return NoTransitionPage(child: DoctorPickerScreen(patient: patient));
            },
          ),
          GoRoute(
            path: '/patient/appointments',
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: PatientAppointmentsScreen()),
          ),
          GoRoute(
            path: '/patient/profile',
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: PatientProfileScreen()),
          ),
          GoRoute(
            path: '/patient/ai-assistant',
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: AiAssistantScreen()),
          ),
          GoRoute(
            path: '/patient/vitals',
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: VitalsTrackingScreen()),
          ),
        ],
      ),

      // ── Patient full-page routes (outside shell) ──────────────────────────
      GoRoute(
        path: '/patient/doctor-picker',
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final patient = state.extra as PatientProfile;
          return DoctorPickerScreen(patient: patient);
        },
      ),
      GoRoute(
        path: '/patient/booking',
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return DoctorBookingScreen(
            doctor: extra['doctor'] as DoctorModel,
            clinic: extra['clinic'] as PractisingClinic,
            patient: extra['patient'] as PatientProfile,
          );
        },
      ),
    ],
  );
}
