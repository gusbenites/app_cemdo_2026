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
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.headset_mic, color: Colors.blue),
              SizedBox(width: 8),
              Text('Contactar Soporte'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text('Llamar por teléfono'),
                subtitle: Text(dotenv.env['SUPPORT_PHONE'] ?? 'No configurado'),
                onTap: () {
                  Navigator.of(context).pop();
                  _makePhoneCall();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.green),
                title: const Text('Chatear por WhatsApp'),
                subtitle: Text(
                  dotenv.env['SUPPORT_WHATSAPP'] ?? 'No configurado',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _openWhatsApp();
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Horario de atención por WhatsApp:\nLunes a viernes 6 a 22hs\nSábados 6 a 13hs',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _makePhoneCall() async {
    final phoneNumber = dotenv.env['SUPPORT_PHONE'];
    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número de teléfono no configurado')),
      );
      return;
    }

    final url = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo hacer la llamada')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al hacer la llamada: $e')));
    }
  }

  Future<void> _openWhatsApp() async {
    final phoneNumber = dotenv.env['SUPPORT_WHATSAPP'];
    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número de WhatsApp no configurado')),
      );
      return;
    }

    const message = 'Hola, necesito asistencia con el Portal CEMDO';
    final url = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al abrir WhatsApp: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_cemdo.png',
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            const Text('Portal CEMDO'),
          ],
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.headset_mic),
            tooltip: 'Contactar Soporte',
            onPressed: _showContactDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (String item) async {
              if (item == 'Acerca de...') {
                if (!mounted) return;
                showDialog(
                  context: context,
                  builder: (context) => const AboutDialogWidget(),
                );
              } else if (item == 'Cerrar Sesión') {
                if (!mounted) return;
                final navigator = Navigator.of(context);
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.logout();
                if (!mounted) return;
                navigator.pushAndRemoveUntil(
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
