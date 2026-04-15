import 'package:flutter_test/flutter_test.dart';
import 'package:patient_crm/main.dart';

void main() {
  testWidgets('App smoke test — renders without exceptions', (WidgetTester tester) async {
    await tester.pumpWidget(const PatientCrmRoot());
  });
}
