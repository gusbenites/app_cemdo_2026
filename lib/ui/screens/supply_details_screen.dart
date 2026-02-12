import 'package:flutter/material.dart';
import 'package:app_cemdo/data/models/service_model.dart';
import 'package:app_cemdo/data/models/supply_model.dart';

class SupplyDetailsScreen extends StatefulWidget {
  final Service service;

  const SupplyDetailsScreen({super.key, required this.service});

  @override
  State<SupplyDetailsScreen> createState() => _SupplyDetailsScreenState();
}

class _SupplyDetailsScreenState extends State<SupplyDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final supplies = widget.service.supplies;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service.label),
        backgroundColor: _getServiceColor(widget.service.tag),
      ),
      body: supplies.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No se encontraron suministros para este servicio.',
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: supplies.length,
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, index) {
                final supply = supplies[index];
                return _buildSupplyCard(supply);
              },
            ),
    );
  }

  Widget _buildSupplyCard(Supply supply) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Suministro #${supply.nrosum}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildStatusChip(supply.estado),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    supply.direccion,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_city_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    supply.localidad,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.category_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Categoría: ${supply.categoria}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String estado) {
    Color color;
    switch (estado.toUpperCase()) {
      case 'CONECTADO':
      case 'ACTIVO':
        color = Colors.green;
        break;
      case 'CON DEUDA':
      case 'SUSPENDIDO':
        color = Colors.red;
        break;
      case 'DESCONECTADO':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getServiceColor(String tag) {
    switch (tag.toUpperCase()) {
      case 'E':
        return Colors.amber[700]!;
      case 'A':
        return Colors.blue;
      case 'I':
        return Colors.purple;
      case 'S':
        return Colors.grey;
      case 'G':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
