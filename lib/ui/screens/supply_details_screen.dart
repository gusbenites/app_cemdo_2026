import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_cemdo/data/models/service_model.dart';
import 'package:app_cemdo/data/models/supply_model.dart';
import 'package:app_cemdo/logic/providers/service_provider.dart';
import 'package:app_cemdo/logic/providers/account_provider.dart';
import 'package:app_cemdo/data/services/secure_storage_service.dart';

class SupplyDetailsScreen extends StatefulWidget {
  final Service service;

  const SupplyDetailsScreen({super.key, required this.service});

  @override
  State<SupplyDetailsScreen> createState() => _SupplyDetailsScreenState();
}

class _SupplyDetailsScreenState extends State<SupplyDetailsScreen> {
  final SecureStorageService _secureStorageService = SecureStorageService();
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      _fetchSupplies();
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  Future<void> _fetchSupplies() async {
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );

    if (accountProvider.activeAccount != null) {
      final token = await _secureStorageService.getToken();
      if (token != null) {
        await serviceProvider.fetchSupplies(
          token,
          accountProvider.activeAccount!.idcliente,
          widget.service.id,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service.nombre),
        backgroundColor: _getServiceColor(widget.service.tipo),
      ),
      body: Consumer<ServiceProvider>(
        builder: (context, serviceProvider, child) {
          if (serviceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (serviceProvider.supplies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No se encontraron suministros para este servicio.',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchSupplies,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: serviceProvider.supplies.length,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, index) {
              final supply = serviceProvider.supplies[index];
              return _buildSupplyCard(supply);
            },
          );
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
                  'Suministro #${supply.nroSuministro}',
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
                const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Servicio: ${supply.nombreServicio}',
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
      case 'ACTIVO':
        color = Colors.green;
        break;
      case 'CON DEUDA':
        color = Colors.red;
        break;
      case 'SUSPENDIDO':
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

  Color _getServiceColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'energia':
        return Colors.amber[700]!;
      case 'agua':
        return Colors.blue;
      case 'internet':
        return Colors.purple;
      case 'sepelio':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
