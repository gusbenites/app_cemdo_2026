import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_cemdo/logic/providers/auth_provider.dart';

import 'package:app_cemdo/ui/widgets/support_icon_button.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Correo Electrónico'),
        automaticallyImplyLeading: false, // Prevent back button
        actions: const [SupportIconButton()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.email_outlined, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                '¡Verifica tu correo electrónico!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hemos enviado un enlace de verificación a tu correo. Por favor, haz clic en el enlace para activar tu cuenta.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await authProvider.resendVerificationEmail();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enlace de verificación reenviado.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al reenviar: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Reenviar correo de verificación'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await authProvider.logout();
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/welcome', (route) => false);
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
