import 'package:app_cemdo/data/models/invoice_model.dart';
import 'package:flutter/material.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback? onTap;

  const InvoiceCard({super.key, required this.invoice, this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color colorEstado;
    final String statusText;
    if (invoice.isVencida) {
      colorEstado = Colors.red;
      statusText = 'VENCIDA';
    } else if (invoice.estado == 'Pagado') {
      colorEstado = Colors.green;
      statusText = 'PAGADA';
    } else {
      colorEstado = Colors.orange;
      statusText = 'PENDIENTE';
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 16.0,
        ), // Added horizontal padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address (Primary Info)
            if (invoice.domicilioSumR1 != null)
              Text(
                '${invoice.domicilioSumR1} ${invoice.domicilioSumR2 ?? ''}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              )
            else
              Text(
                'Suministro ${invoice.idsuministro}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 8),

            // Period and Due Date
            Wrap(
              spacing: 12.0,
              runSpacing: 4.0,
              children: [
                if (invoice.nroper != null && invoice.anio != null)
                  Text(
                    'Per: ${invoice.nroper}/${invoice.anio}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                Text(
                  'Vto: ${invoice.fechaVto}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Service and Amount (Right Aligned)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  invoice.servicio,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colorEstado,
                      ),
                    ),
                    Text(
                      '\$${invoice.srvImporte}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorEstado,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
