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
import 'package:package_info_plus/package_info_plus.dart'; // Added
import 'package:url_launcher/url_launcher.dart'; // Added
import 'widgets/about_dialog_widget.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
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
      ],
      child: MaterialApp(
        title: 'Portal CEMDO',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const AuthCheck(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/main': (context) => const MainScreen(), // Named route for MainScreen
          '/login': (context) => const LoginScreen(), // Named route for LoginScreen
          '/accounts': (context) => const AccountsScreen(), // Named route for AccountsScreen
        },
      ),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoggedIn = false;
  final _secureStorageService = SecureStorageService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await _secureStorageService.getToken();
    final user = await _secureStorageService.getUser();

    if (token != null && user != null) {
      if (!mounted) return; // Added
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );

      // Fetch accounts on app start
      await accountProvider.fetchAccounts(token);

      if (!mounted) return; // Added
      // Set the active account if ultimoIdCliente is defined and accounts are available
      if (user.ultimoIdCliente != null && accountProvider.accounts.isNotEmpty) {
        Account? activeAccount; // Make activeAccount nullable
        try {
          activeAccount = accountProvider.accounts.firstWhere(
            (acc) => acc.idcliente == user.ultimoIdCliente,
          );
        } catch (e) {
          // If no element is found, activeAccount remains null
          debugPrint('Active account not found: $e');
        }

        if (activeAccount != null) {
          accountProvider.setActiveAccount(activeAccount);
        }
      }

      if (!mounted) return; // Added
      setState(() {
        _isLoggedIn = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn ? const MainScreen() : const LoginScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  PackageInfo? _packageInfo; // Added
  final _secureStorageService = SecureStorageService(); // Added
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const InvoicesScreen(showAll: true),
    const AccountsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _checkAccountStatusAndNavigate(); // Call the new method
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  // New method to check account status and navigate
  Future<void> _checkAccountStatusAndNavigate() async {
    final user = await _secureStorageService.getUser();
    if (!mounted) return; // Added
    final accountProvider = Provider.of<AccountProvider>(context, listen: false);

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
                final secureStorageService = SecureStorageService();
                await secureStorageService
                    .deleteLoginData(); // Changed to deleteLoginData()
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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.all_inbox),
            label: 'Facturas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_box),
            label: 'Cuentas',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}