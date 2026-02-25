import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:app_cemdo/ui/widgets/support_icon_button.dart';

class PaymentProcedureScreen extends StatelessWidget {
  const PaymentProcedureScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('URL no configurada')));
      return;
    }

    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el enlace')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al abrir el enlace: $e')));
      }
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
        actions: const [SupportIconButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Puede abonar sus facturas vigentes a través de las plataformas bancarizadas. Las facturas vencidas posterior al ultimo vencimiento, deben abonarse en la cooperativa o sus delegaciones.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Seleccione una plataforma:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPaymentLogoButton(
              context: context,
              assetPath: 'assets/images/MACROLogo.png',
              onPressed: () =>
                  _launchUrl(context, dotenv.env['PAYMENT_MACRO_URL']),
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            _buildPaymentLogoButton(
              context: context,
              assetPath: 'assets/images/bancor-pagos.png',
              onPressed: () =>
                  _launchUrl(context, dotenv.env['PAYMENT_BANCOR_URL']),
              backgroundColor: const Color(0xFF1B5E20),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade800),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tenga en cuenta que se abrirá una página web externa correspondiente al banco seleccionado.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Importante: Los pagos realizados por plataformas bancarizadas demoran hasta 48 hs hábiles para acreditarse.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentLogoButton({
    required BuildContext context,
    required String assetPath,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Image.asset(assetPath, fit: BoxFit.contain)),
        ),
      ),
    );
  }
}
