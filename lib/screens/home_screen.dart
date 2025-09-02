import 'package:app_cemdo/models/invoice_model.dart';
import 'package:app_cemdo/providers/account_provider.dart';
import 'package:app_cemdo/widgets/account_card.dart';
import 'package:app_cemdo/widgets/invoice_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample invoices data. This will be replaced with data from the API.
    final List<Invoice> sampleInvoices = [
      Invoice.fromJson({
        "idcbte": 37487572,
        "idsuministro": 303172,
        "nro_factura": "01-0006-FAC-2000-A-00200290",
        "fecha_vto": "15/08/2025",
        "servicio": "Unificado",
        "srv_importe": "10.859,99",
        "srv_saldo": "10859.99",
        "estado": "Vencida",
        "is_vencida": true,
        "anio": 2025,
        "nroper": 6,
        "domicilio_sum_r1": "MZ. 101 LOTE 5 FIDEICOMISO UNION",
        "domicilio_sum_r2": "(5870) VILLA DOLORES-Córdoba"
      }),
      Invoice.fromJson({
        "idcbte": 37769439,
        "idsuministro": 303172,
        "nro_factura": "01-0006-FAC-2000-A-00201893",
        "fecha_vto": "12/09/2025",
        "servicio": "Unificado",
        "srv_importe": "11.334,14",
        "srv_saldo": "11334.14",
        "estado": "Pendiente",
        "is_vencida": false,
        "anio": 2025,
        "nroper": 7,
        "domicilio_sum_r1": "MZ. 101 LOTE 5 FIDEICOMISO UNION",
        "domicilio_sum_r2": "(5870) VILLA DOLORES-Córdoba"
      }),
    ];

    final int overdueCount = sampleInvoices.where((inv) => inv.isVencida).length;

    return Consumer<AccountProvider>(
      builder: (context, accountProvider, child) {
        if (accountProvider.activeAccount == null) {
          return const Center(child: Text('No hay una cuenta activa seleccionada.'));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 16.0),
                child: AccountCard(account: accountProvider.activeAccount!),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Facturas Pendientes',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (overdueCount > 0)
                              Chip(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                label: Text(
                                  '$overdueCount VENCIDA(S)',
                                  style: const TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.separated(
                            itemCount: sampleInvoices.length,
                            itemBuilder: (context, index) {
                              return InvoiceCard(invoice: sampleInvoices[index]);
                            },
                            separatorBuilder: (context, index) => const Divider(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}