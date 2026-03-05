import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_cemdo/logic/providers/auth_provider.dart';
import 'package:app_cemdo/logic/providers/account_provider.dart';
import 'package:app_cemdo/data/services/notification_service.dart';
import 'package:app_cemdo/ui/screens/login_screen.dart';

import '../../mocks/mocks.dart';

void main() {
  late MockAuthProvider mockAuthProvider;
  late MockAccountProvider mockAccountProvider;
  late MockNotificationService mockNotificationService;

  setUp(() {
    // Initialize dotenv for tests
    dotenv.testLoad(
      fileInput: '''
      TERMS_AND_CONDITIONS_URL=https://example.com/terms
    ''',
    );

    mockAuthProvider = MockAuthProvider();
    mockAccountProvider = MockAccountProvider();
    mockNotificationService = MockNotificationService();

    // Default stubs
    when(() => mockAuthProvider.login(any(), any())).thenAnswer((_) async {});
    when(() => mockAuthProvider.token).thenReturn('fake_token');
    when(
      () => mockAccountProvider.fetchAccounts(any()),
    ).thenAnswer((_) async => {});
  });

  Widget createLoginScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ChangeNotifierProvider<AccountProvider>.value(
          value: mockAccountProvider,
        ),
        ChangeNotifierProvider<NotificationService>.value(
          value: mockNotificationService,
        ),
      ],
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
    // We check for the specific validation error message
    expect(find.text('Por favor, ingresa tu email'), findsOneWidget);
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
