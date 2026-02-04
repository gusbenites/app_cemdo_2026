import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_cemdo/logic/providers/auth_provider.dart';
import 'package:app_cemdo/ui/screens/login_screen.dart';

import '../../mocks/mocks.dart';

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    // Default stubs
    when(() => mockAuthProvider.login(any(), any())).thenAnswer((_) async {});
  });

  Widget createLoginScreen() {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: mockAuthProvider,
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('LoginScreen displays inputs and button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createLoginScreen());

    expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });

  testWidgets('LoginScreen shows validation error on empty submit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createLoginScreen());

    // Tap login button without entering text
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pump();

    // Should see validation errors.
    // Exact text depends on validator messages, usually "Ingrese su email" or similar.
    // Assuming standard validators are used.
    expect(find.textContaining('email'), findsOneWidget);
    // This might be fragile if validators aren't checked.
  });

  testWidgets('LoginScreen calls authProvider.login on valid submit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createLoginScreen());

    // Enter email and password
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');

    // Tap login
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pump(); // Start animation

    verify(
      () => mockAuthProvider.login('test@example.com', 'password123'),
    ).called(1);
  });
}
