import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportUtils {
  static void showContactDialog(BuildContext context) {
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
                  makePhoneCall(context);
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
                  openWhatsApp(context);
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

  static Future<void> makePhoneCall(BuildContext context) async {
    final phoneNumber = dotenv.env['SUPPORT_PHONE'];
    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (!context.mounted) return;
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
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo hacer la llamada')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al hacer la llamada: $e')));
    }
  }

  static Future<void> openWhatsApp(BuildContext context) async {
    final phoneNumber = dotenv.env['SUPPORT_WHATSAPP'];
    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (!context.mounted) return;
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
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al abrir WhatsApp: $e')));
    }
  }
}
