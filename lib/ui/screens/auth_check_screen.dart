import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_cemdo/logic/providers/auth_provider.dart';
import 'package:app_cemdo/logic/providers/account_provider.dart';
import 'package:app_cemdo/data/services/notification_service.dart';
import 'package:app_cemdo/data/models/account_model.dart';

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  AuthCheckState createState() => AuthCheckState();
}

class AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    if (!mounted) return;
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );
    await notificationService.checkPermissionStatus();

    if (!notificationService.notificationsEnabled) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/notification_permission');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkLoginStatus();

    if (!mounted) return;

    String nextRoute;
    if (authProvider.token != null && authProvider.user != null) {
      if (authProvider.user!.emailVerifiedAt == null) {
        nextRoute = '/verify_email';
      } else {
        nextRoute = '/main';
        final accountProvider = Provider.of<AccountProvider>(
          context,
          listen: false,
        );

        await accountProvider.fetchAccounts(authProvider.token!);

        if (!mounted) return;
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

        NotificationService().sendFcmTokenToBackend(
          authProvider.user!.id.toString(),
        );
      }
    } else {
      nextRoute = '/welcome';
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[700]!, Colors.blue[900]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo_app_1152.png', // Corrected path
                    height: 120,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Error loading logo in AuthCheck: $error');
                      return const Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 80,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cargando...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Portal CEMDO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Versión 2.0.0+1',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
