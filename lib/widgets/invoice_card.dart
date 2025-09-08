import 'package:app_cemdo/models/invoice_model.dart';
import 'package:flutter/material.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback? onTap;

  const InvoiceCard({super.key, required this.invoice, this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color colorEstado;
    if (invoice.isVencida) {
      colorEstado = Colors.red;
    } else if (invoice.estado == 'Pagado') {
      colorEstado = Colors.green;
    } else {
      colorEstado = Colors.orange;
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 16.0,
        ), // Added horizontal padding
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    '${invoice.nroFactura} (${invoice.servicio})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Address and Supply Number
                  if (invoice.domicilioSumR1 != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        '${invoice.domicilioSumR1} ${invoice.domicilioSumR2 ?? ''} (${invoice.idsuministro})',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),

                  // Period and Due Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (invoice.nroper != null && invoice.anio != null)
                        Text(
                          'Período: ${invoice.nroper}/${invoice.anio}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      Text(
                        'Vencimiento: ${invoice.fechaVto}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colorEstado,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        invoice.estado,
                        style: TextStyle(
                          color: colorEstado,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Amount
            Text(
              '\$${invoice.srvImporte}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: invoice.isVencida
                    ? Colors.red
                    : (invoice.estado == 'Pagado' ? Colors.green : null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
