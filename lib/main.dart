import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'features/auth/patient_auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PatientCrmRoot());
}

class PatientCrmRoot extends StatelessWidget {
  const PatientCrmRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PatientAuthProvider()),
      ],
      child: const PatientCrmApp(),
    );
  }
}

