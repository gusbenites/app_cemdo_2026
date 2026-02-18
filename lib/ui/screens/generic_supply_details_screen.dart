import 'package:flutter/material.dart';
import 'package:app_cemdo/data/models/supply_model.dart';

class GenericSupplyDetailsScreen extends StatelessWidget {
  final Supply supply;
  final String tag;

  const GenericSupplyDetailsScreen({
    super.key,
    required this.supply,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle Suministro #${supply.idsuministro}'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.location_on,
                      'Domicilio',
                      supply.direccion,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      Icons.location_city,
                      'Localidad',
                      supply.localidad,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      Icons.category,
                      'Categoría',
                      supply.categoria,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      Icons.info_outline,
                      'Estado',
                      supply.estado,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[900], size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
