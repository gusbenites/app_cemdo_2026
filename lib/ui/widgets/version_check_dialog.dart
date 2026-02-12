import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionCheckDialog extends StatelessWidget {
  final String message;
  final String? storeUrl;
  final bool forceUpdate;

  const VersionCheckDialog({
    super.key,
    required this.message,
    this.storeUrl,
    required this.forceUpdate,
  });

  Future<void> _launchStoreUrl(BuildContext context) async {
    if (storeUrl != null && await canLaunchUrl(Uri.parse(storeUrl!))) {
      await launchUrl(
        Uri.parse(storeUrl!),
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la tienda.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !forceUpdate,
      child: AlertDialog(
        title: const Text('Actualización Disponible'),
        content: Text(message),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Más tarde'),
            ),
          ElevatedButton(
            onPressed: () => _launchStoreUrl(context),
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
}
