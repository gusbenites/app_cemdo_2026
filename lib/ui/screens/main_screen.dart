import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_cemdo/logic/providers/account_provider.dart';
import 'package:app_cemdo/logic/providers/auth_provider.dart';
import 'package:app_cemdo/data/services/secure_storage_service.dart';
import 'package:app_cemdo/data/services/notification_service.dart';
import 'package:app_cemdo/ui/screens/home_screen.dart';
import 'package:app_cemdo/ui/screens/invoices_screen.dart';
import 'package:app_cemdo/ui/screens/accounts_screen.dart';
import 'package:app_cemdo/ui/screens/notices_screen.dart';
import 'package:app_cemdo/ui/screens/login_screen.dart';
import 'package:app_cemdo/ui/widgets/about_dialog_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final _secureStorageService = SecureStorageService();
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const InvoicesScreen(showAll: true),
    const AccountsScreen(),
    const NoticesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAccountStatusAndNavigate();
  }

  Future<void> _checkAccountStatusAndNavigate() async {
    final user = await _secureStorageService.getUser();
    if (!mounted) return;
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );

    if (accountProvider.accounts.isEmpty || user?.ultimoIdCliente == null) {
      if (!mounted) return;
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
                if (!mounted) return;
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
                if (!mounted) return;
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
                final unreadCount = notificationService.unreadCount;
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
