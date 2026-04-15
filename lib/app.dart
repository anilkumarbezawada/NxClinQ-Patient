import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/router/patient_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_font_sizes.dart';
import 'features/auth/patient_auth_provider.dart';

class PatientCrmApp extends StatefulWidget {
  const PatientCrmApp({super.key});

  @override
  State<PatientCrmApp> createState() => _PatientCrmAppState();
}

class _PatientCrmAppState extends State<PatientCrmApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<PatientAuthProvider>();
    _router = createPatientRouter(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NxClinq',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(AppFontSizes.scaleFactor),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        scaffoldBackgroundColor: AppColors.surface,
      ),
      routerConfig: _router,
    );
  }
}
