import 'package:flutter_test/flutter_test.dart';
import 'package:qarz_khaata/main.dart';

void main() {
  testWidgets('Qarz Khaata app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QarzKhaataApp());

    // Verify that Qarz Khaata dashboard title or elements load.
    expect(find.text('Digital Ledger • Qarz Khaata'), findsOneWidget);
  });
}
