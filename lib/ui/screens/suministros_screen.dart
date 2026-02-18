import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_cemdo/logic/providers/service_provider.dart';
import 'package:app_cemdo/logic/providers/account_provider.dart';
import 'package:app_cemdo/data/services/secure_storage_service.dart';

import 'supply_details_screen.dart';
import 'individual_supply_details_screen.dart';
import 'generic_supply_details_screen.dart';

class SuministrosScreen extends StatefulWidget {
  const SuministrosScreen({super.key});

  @override
  State<SuministrosScreen> createState() => _SuministrosScreenState();
}

class _SuministrosScreenState extends State<SuministrosScreen> {
  final SecureStorageService _secureStorageService = SecureStorageService();
  bool _isInit = true;
  int? _lastFetchedAccountId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final accountProvider = Provider.of<AccountProvider>(context);
    final activeAccountId = accountProvider.activeAccount?.idcliente;

    if (_isInit || activeAccountId != _lastFetchedAccountId) {
      _fetchServices();
      _isInit = false;
      _lastFetchedAccountId = activeAccountId;
    }
  }

  Future<void> _fetchServices() async {
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );

    final token = await _secureStorageService.getToken();
    final activeAccount = accountProvider.activeAccount;

    if (token != null && activeAccount != null) {
      await serviceProvider.fetchServices(token, activeAccount.idcliente);
    } else {
      // Clear services if no account or token
      serviceProvider.clearServices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Servicios')),
      body: Consumer<ServiceProvider>(
        builder: (context, serviceProvider, child) {
          final accountProvider = Provider.of<AccountProvider>(context);

          if (accountProvider.activeAccount == null) {
            return const Center(
              child: Text('No hay una cuenta activa seleccionada.'),
            );
          }

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
                    if (service.supplies.length == 1) {
                      final supply = service.supplies.first;
                      if (service.id == 1 || service.id == 2) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IndividualSupplyDetailsScreen(
                              supply: supply,
                              tag: service.tag,
                              serviceId: service.id,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GenericSupplyDetailsScreen(
                              supply: supply,
                              tag: service.tag,
                            ),
                          ),
                        );
                      }
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SupplyDetailsScreen(service: service),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _getServiceColor(service.tag),
                          radius: 25,
                          child: Icon(
                            _getServiceIcon(service.tag),
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
                                service.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${service.supplies.length} suministro(s)',
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
        return Colors.green;
    }
  }

  IconData _getServiceIcon(String tag) {
    switch (tag.toUpperCase()) {
      case 'E':
        return Icons.lightbulb_outline;
      case 'A':
        return Icons.water_drop_outlined;
      case 'I':
        return Icons.wifi;
      case 'S':
        return Icons.church;
      case 'G':
        return Icons.local_gas_station;
      default:
        return Icons.design_services;
    }
  }
}
