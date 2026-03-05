import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_cemdo/logic/providers/auth_provider.dart';
import 'package:app_cemdo/ui/screens/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_cemdo/logic/providers/account_provider.dart';
import 'package:app_cemdo/data/services/notification_service.dart';

import 'mocks/mocks.dart';

void main() {
  late MockAuthProvider mockAuthProvider;
  late MockAccountProvider mockAccountProvider;
  late MockNotificationService mockNotificationService;

  setUp(() {
    dotenv.testLoad(
      fileInput: '''
      TERMS_AND_CONDITIONS_URL=https://example.com/terms
    ''',
    );
    mockAuthProvider = MockAuthProvider();
    mockAccountProvider = MockAccountProvider();
    mockNotificationService = MockNotificationService();

    when(() => mockAuthProvider.token).thenReturn('fake_token');
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

  testWidgets('LoginScreen shows email and password fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createLoginScreen());

    expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
