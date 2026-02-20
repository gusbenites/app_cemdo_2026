import 'package:flutter/material.dart';
import 'package:app_cemdo/data/models/service_model.dart';
import 'package:app_cemdo/data/models/supply_model.dart';
import 'individual_supply_details_screen.dart';
import 'generic_supply_details_screen.dart';

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
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (widget.service.id == 1 ||
              widget.service.id == 2 ||
              widget.service.id == 3 ||
              widget.service.id == 99) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IndividualSupplyDetailsScreen(
                  supply: supply,
                  tag: widget.service.tag,
                  serviceId: widget.service.id,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GenericSupplyDetailsScreen(
                  supply: supply,
                  tag: widget.service.tag,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Suministro #${supply.idsuministro}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusChip(supply.estado, widget.service.tag),
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
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String estado, String tag) {
    Color color;
    final estadoUpper = estado.toUpperCase();

    // Check for specific statuses provided by the user
    if (estadoUpper == 'NORMAL' ||
        estadoUpper == 'ACTIVO' ||
        estadoUpper == 'CONECTADO') {
      color = Colors.green;
    } else if (estadoUpper == 'SUSPENDIDO' ||
        estadoUpper == 'BAJA' ||
        estadoUpper == 'CON DEUDA') {
      color = Colors.red;
    } else if (estadoUpper == 'DESCONECTADO') {
      color = Colors.orange;
    } else {
      // Background logic for other cases
      if (tag.toUpperCase() == 'E') {
        color = Colors.green;
      } else {
        color = Colors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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
}
