import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_cemdo/logic/providers/service_provider.dart';
import 'package:app_cemdo/logic/providers/account_provider.dart';
import 'package:app_cemdo/data/services/secure_storage_service.dart';
import 'package:app_cemdo/data/models/service_model.dart';

import 'supply_details_screen.dart'; // Ensure correct relative import

class SuministrosScreen extends StatefulWidget {
  const SuministrosScreen({super.key});

  @override
  State<SuministrosScreen> createState() => _SuministrosScreenState();
}

class _SuministrosScreenState extends State<SuministrosScreen> {
  final SecureStorageService _secureStorageService = SecureStorageService();
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      _fetchServices();
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  Future<void> _fetchServices() async {
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
        await serviceProvider.fetchServices(
          token,
          accountProvider.activeAccount!.idcliente,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Servicios')),
      body: Consumer<ServiceProvider>(
        builder: (context, serviceProvider, child) {
          if (serviceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (serviceProvider.services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No se encontraron servicios contratados.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchServices,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: serviceProvider.services.length,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, index) {
              final service = serviceProvider.services[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SupplyDetailsScreen(service: service),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _getServiceColor(service.tipo),
                          radius: 25,
                          child: Icon(
                            _getServiceIcon(service.tipo),
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Toque para ver suministros',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
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
        return Colors.green;
    }
  }

  IconData _getServiceIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'energia':
        return Icons.lightbulb_outline;
      case 'agua':
        return Icons.water_drop_outlined;
      case 'internet':
        return Icons.wifi;
      case 'sepelio':
        return Icons.church;
      default:
        return Icons.design_services;
    }
  }
}
