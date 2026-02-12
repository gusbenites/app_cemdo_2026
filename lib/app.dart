import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_cemdo/logic/providers/account_provider.dart';
import 'package:app_cemdo/logic/providers/invoice_provider.dart';
import 'package:app_cemdo/logic/providers/auth_provider.dart';
import 'package:app_cemdo/logic/providers/service_provider.dart'; // Added
import 'package:app_cemdo/data/services/secure_storage_service.dart';
import 'package:app_cemdo/data/services/notification_service.dart';
import 'package:app_cemdo/ui/screens/accounts_screen.dart';
import 'package:app_cemdo/ui/screens/login_screen.dart';
import 'package:app_cemdo/ui/screens/verify_email_screen.dart';
import 'package:app_cemdo/ui/screens/main_screen.dart';
import 'package:app_cemdo/ui/screens/auth_check_screen.dart';
import 'package:app_cemdo/ui/screens/notification_permission_screen.dart';

import 'package:app_cemdo/ui/utils/error_notification.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SecureStorageService>(create: (_) => SecureStorageService()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()), // Added
      ],
      child: MaterialApp(
        title: 'Portal CEMDO',
        scaffoldMessengerKey: ErrorNotification.messengerKey,
        theme: ThemeData(primarySwatch: Colors.blue),
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (context) => const AuthCheck(),
          '/main': (context) => const MainScreen(),
          '/login': (context) => const LoginScreen(),
          '/accounts': (context) => const AccountsScreen(),
          '/verify_email': (context) => const VerifyEmailScreen(),
          '/notification_permission': (context) =>
              const NotificationPermissionScreen(),
        },
      ),
    );
  }
}
