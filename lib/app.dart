import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/auth_provider.dart';

class DoctorCrmApp extends StatefulWidget {
  const DoctorCrmApp({super.key});

  @override
  State<DoctorCrmApp> createState() => _DoctorCrmAppState();
}

class _DoctorCrmAppState extends State<DoctorCrmApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Initialize the router once, so hot-reloads and theme changes
    // don't recreate GoRouter and cause GlobalKey duplicate errors.
    final authProvider = context.read<AuthProvider>();
    _router = createRouter(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'Doctor CRM',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      routerConfig: _router,
    );
  }
}

