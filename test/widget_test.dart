import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qarz_khaata/main.dart';
import 'package:qarz_khaata/models/user_model.dart';

void main() {
  test('UserModel serialization and deserialization', () {
    final now = DateTime.now();
    final user = UserModel(
      id: 1,
      name: 'Talib Afridi',
      email: 'talib@example.com',
      imagePath: '/path/to/avatar.jpg',
      createdAt: now,
    );

    final map = user.toMap();
    expect(map['name'], 'Talib Afridi');
    expect(map['email'], 'talib@example.com');
    expect(map['image_path'], '/path/to/avatar.jpg');

    final reconstructed = UserModel.fromMap(map);
    expect(reconstructed.id, 1);
    expect(reconstructed.name, 'Talib Afridi');
    expect(reconstructed.email, 'talib@example.com');
    expect(reconstructed.imagePath, '/path/to/avatar.jpg');
  });

  testWidgets('AuthScreen displays Sign Up with Fingerprint on initial launch', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(const QarzKhaataApp());
    await tester.pumpAndSettle();

    // Verify Auth elements
    expect(find.text('QARZ KHAATA'), findsOneWidget);
    expect(find.text('Sign Up with Fingerprint'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Name and Email fields
    expect(find.byIcon(Icons.fingerprint_rounded), findsWidgets);
  });
}
