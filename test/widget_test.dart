import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:doctor_crm/app.dart';
import 'package:doctor_crm/core/theme/theme_provider.dart';
import 'package:doctor_crm/features/auth/auth_provider.dart';

void main() {
  testWidgets('App smoke test — renders without exceptions', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const DoctorCrmApp(),
      ),
    );
    // App renders at least something
    expect(find.byType(DoctorCrmApp), findsOneWidget);
  });
}
