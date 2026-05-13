import 'package:flutter_test/flutter_test.dart';
import 'package:secure_vault/app.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build app and trigger a frame.
    await tester.pumpWidget(const SecureVaultApp());
    await tester.pump();
  });
}
