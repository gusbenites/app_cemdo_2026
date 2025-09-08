import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_cemdo/providers/auth_provider.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Correo Electrónico'),
        automaticallyImplyLeading: false, // Prevent back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.email_outlined,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                '¡Verifica tu correo electrónico!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hemos enviado un enlace de verificación a tu correo. Por favor, haz clic en el enlace para activar tu cuenta.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement resend verification email logic
                  // authProvider.resendVerificationEmail();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enlace de verificación reenviado.')),
                  );
                },
                child: const Text('Reenviar correo de verificación'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await authProvider.logout();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login', (route) => false);
                },
                child: const Text('Volver a Iniciar Sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
