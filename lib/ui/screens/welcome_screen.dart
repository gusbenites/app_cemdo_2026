import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:app_cemdo/logic/providers/auth_provider.dart';
import 'package:app_cemdo/ui/utils/error_notification.dart';
import 'package:app_cemdo/logic/providers/account_provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  PackageInfo? _packageInfo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.white.withOpacity(0.95),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset('assets/images/logo_cemdo.png', height: 100),
                      const SizedBox(height: 24),
                      Text(
                        'Bienvenido a Portal CEMDO',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Elige cómo quieres identificarte para continuar',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                      ),
                      const SizedBox(height: 40),

                      // Email Button
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/login');
                        },
                        icon: const Icon(Icons.email_outlined),
                        label: const Text(
                          'Continuar con Email',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: Colors.blue[900],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'O también con',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Google Button
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : OutlinedButton.icon(
                              onPressed: () async {
                                setState(() => _isLoading = true);
                                try {
                                  final authProvider =
                                      Provider.of<AuthProvider>(
                                        context,
                                        listen: false,
                                      );
                                  await authProvider.signInWithGoogle();

                                  if (!mounted) return;

                                  final accountProvider =
                                      Provider.of<AccountProvider>(
                                        context,
                                        listen: false,
                                      );
                                  await accountProvider.fetchAccounts(
                                    authProvider.token!,
                                  );

                                  if (!mounted) return;
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/main',
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              },
                              icon: Image.asset(
                                'assets/images/google.png',
                                height: 24,
                              ),
                              label: const Text(
                                'Google y Gmail',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),

                      const SizedBox(height: 16),

                      // Microsoft Button
                      _isLoading
                          ? const SizedBox.shrink()
                          : OutlinedButton.icon(
                              onPressed: () async {
                                setState(() => _isLoading = true);
                                try {
                                  final authProvider =
                                      Provider.of<AuthProvider>(
                                        context,
                                        listen: false,
                                      );
                                  await authProvider.signInWithMicrosoft();

                                  if (!mounted) return;

                                  final accountProvider =
                                      Provider.of<AccountProvider>(
                                        context,
                                        listen: false,
                                      );
                                  await accountProvider.fetchAccounts(
                                    authProvider.token!,
                                  );

                                  if (!mounted) return;
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/main',
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              },
                              icon: Image.asset(
                                'assets/images/microsoft.png',
                                height: 20,
                              ),
                              label: const Text(
                                'Hotmail y Outlook',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),

                      if (Platform.isIOS) ...[
                        const SizedBox(height: 16),
                        _isLoading
                            ? const SizedBox.shrink()
                            : OutlinedButton.icon(
                                onPressed: () async {
                                  setState(() => _isLoading = true);
                                  try {
                                    final authProvider =
                                        Provider.of<AuthProvider>(
                                          context,
                                          listen: false,
                                        );
                                    await authProvider.signInWithApple();

                                    if (!mounted) return;

                                    final accountProvider =
                                        Provider.of<AccountProvider>(
                                          context,
                                          listen: false,
                                        );
                                    await accountProvider.fetchAccounts(
                                      authProvider.token!,
                                    );

                                    if (!mounted) return;
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/main',
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ErrorNotification.showSnackBar(
                                      'Error al iniciar sesión con Apple. Inténtelo de nuevo.',
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                                icon: const Icon(
                                  Icons.apple,
                                  size: 28,
                                  color: Colors.black,
                                ),
                                label: const Text(
                                  'Continuar con Apple',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 56),
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                      ],

                      const SizedBox(height: 40),

                      // Footer info
                      if (_packageInfo != null)
                        Column(
                          children: [
                            Text(
                              'Cooperativa de Provisión de Servicios Públicos CEMDO Ltda',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Versión ${_packageInfo!.version}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
