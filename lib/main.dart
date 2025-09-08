import 'package:app_cemdo/providers/account_provider.dart';
import 'package:app_cemdo/models/account_model.dart'; // Added
import 'package:app_cemdo/providers/invoice_provider.dart'; // Added
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/accounts_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'services/secure_storage_service.dart';
import 'package:app_cemdo/providers/auth_provider.dart'; // Added

import 'widgets/about_dialog_widget.dart';
import 'screens/notices_screen.dart'; // Added for NoticesScreen
import 'package:firebase_core/firebase_core.dart'; // Added for Firebase
import 'package:firebase_messaging/firebase_messaging.dart'; // Added for Firebase Messaging
import 'services/notification_service.dart'; // Added for Notification Service
import 'package:shared_preferences/shared_preferences.dart'; // Added for SharedPreferences
import 'screens/verify_email_screen.dart'; // New import

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Initialize Firebase for background messages
  debugPrint("Handling a background message: \${message.messageId}");
  NotificationService().saveNotification(
    message.notification?.title ?? 'No Title',
    message.notification?.body ?? 'No Body',
    message.data['tipo'] ?? 'general',
    message.data['timestamp'] ?? DateTime.now().toIso8601String(),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  // Define the flavor, defaulting to 'development'
  const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'development',
  );
  await dotenv.load(fileName: ".env.$flavor"); // Load the appropriate .env file

  // Temporarily clear old notifications for debugging
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('notifications'); // Clear the key

  // Initialize Notification Service
  await NotificationService().initialize();

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SecureStorageService>(create: (_) => SecureStorageService()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()), // Added
        ChangeNotifierProvider(create: (_) => NotificationService()), // Added
        ChangeNotifierProvider(create: (_) => AuthProvider()), // Added
      ],
      child: MaterialApp(
        title: 'Portal CEMDO',
        theme: ThemeData(primarySwatch: Colors.blue),
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (context) => const AuthCheck(), // Set AuthCheck as initial route
          '/main': (context) =>
              const MainScreen(), // Named route for MainScreen
          '/login': (context) =>
              const LoginScreen(), // Named route for LoginScreen
          '/accounts': (context) =>
              const AccountsScreen(), // Named route for AccountsScreen
          '/verify_email': (context) =>
              const VerifyEmailScreen(), // New named route
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final _secureStorageService = SecureStorageService(); // Added
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const InvoicesScreen(showAll: true),
    const AccountsScreen(),
    const NoticesScreen(), // Added for Notifications
  ];

  @override
  void initState() {
    super.initState();
    _checkAccountStatusAndNavigate(); // Call the new method
  }

  // New method to check account status and navigate
  Future<void> _checkAccountStatusAndNavigate() async {
    final user = await _secureStorageService.getUser();
    if (!mounted) return; // Added
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );

    if (accountProvider.accounts.isEmpty || user?.ultimoIdCliente == null) {
      if (!mounted) return; // Added
      setState(() {
        _selectedIndex = 2; // Index for AccountsScreen
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal CEMDO'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String item) async {
              if (item == 'Acerca de...') {
                if (!mounted) return; // Added
                showDialog(
                  context: context,
                  builder: (context) => const AboutDialogWidget(),
                );
              } else if (item == 'Cerrar Sesión') {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.logout();
                if (!mounted) return; // Added
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return ['Cerrar Sesión', 'Acerca de...'].map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.all_inbox),
            label: 'Facturas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_box),
            label: 'Cuentas',
          ),
          BottomNavigationBarItem(
            icon: Consumer<NotificationService>(
              builder: (context, notificationService, child) {
                final unreadCount =
                    notificationService.unreadCount; // Direct access
                return Stack(
                  children: [
                    Icon(Icons.notifications),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Avisos',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
      ),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  AuthCheckState createState() => AuthCheckState();
}

class AuthCheckState extends State<AuthCheck> {
  final bool _isLoading = true; // Added loading state

  @override
  void initState() {
    super.initState();
    _checkAndNavigate(); // Call the new method to handle check and navigation
  }

  Future<void> _checkAndNavigate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkLoginStatus();

    if (!mounted) return;

    String nextRoute;
    if (authProvider.token != null && authProvider.user != null) {
      // Check if email is verified
      if (authProvider.user!.emailVerifiedAt == null) {
        nextRoute = '/verify_email';
      } else {
        nextRoute = '/main';
        final accountProvider = Provider.of<AccountProvider>(
          context,
          listen: false,
        );

        // Fetch accounts on app start
        await accountProvider.fetchAccounts(authProvider.token!);

        if (!mounted) return;
        // Set the active account if ultimoIdCliente is defined and accounts are available
        if (authProvider.user!.ultimoIdCliente != null &&
            accountProvider.accounts.isNotEmpty) {
          Account? activeAccount;
          try {
            activeAccount = accountProvider.accounts.firstWhere(
              (acc) => acc.idcliente == authProvider.user!.ultimoIdCliente,
            );
          } catch (e) {
            debugPrint('Active account not found: $e');
          }

          if (activeAccount != null) {
            accountProvider.setActiveAccount(activeAccount);
          }
        }

        // Send FCM token to backend after successful login
        NotificationService().sendFcmTokenToBackend(
          authProvider.user!.id.toString(),
        ); // Assuming user.id is available and can be converted to String
      }
    } else {
      nextRoute = '/login';
    }

    if (!mounted) return;
    // Navigate after the build method has completed
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while checking status
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[700]!, Colors.blue[900]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo_cemdo.png', height: 120),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cargando...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
