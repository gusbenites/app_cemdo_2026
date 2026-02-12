import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:app_cemdo/ui/screens/login_screen.dart';
import 'package:app_cemdo/logic/providers/auth_provider.dart';

import 'mocks/mocks.dart';

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
  });

  Widget createLoginScreen() {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: mockAuthProvider,
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('LoginScreen shows email and password fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createLoginScreen());

    expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
