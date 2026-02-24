import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_cemdo/logic/providers/service_provider.dart';
import 'package:app_cemdo/logic/providers/account_provider.dart';
import 'package:app_cemdo/data/services/secure_storage_service.dart';
import 'package:app_cemdo/ui/widgets/support_icon_button.dart';

import 'supply_details_screen.dart';
import 'individual_supply_details_screen.dart';
import 'generic_supply_details_screen.dart';
import 'package:app_cemdo/ui/utils/service_utils.dart';

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
      appBar: AppBar(
        title: Consumer<AccountProvider>(
          builder: (context, accountProvider, child) {
            final activeAccount = accountProvider.activeAccount;
            if (activeAccount == null) return const Text('Suministros');
            return Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    'Suministros de ${activeAccount.razonSocial}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${activeAccount.idcliente})',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            );
          },
        ),
        actions: const [SupportIconButton()],
      ),
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
                      if (service.id == 1 ||
                          service.id == 2 ||
                          service.id == 3 ||
                          service.id == 99) {
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
                          backgroundColor: ServiceUtils.getServiceColor(
                            service.tag,
                            service.label,
                          ),
                          radius: 25,
                          child: Icon(
                            ServiceUtils.getServiceIcon(
                              service.tag,
                              service.label,
                            ),
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
                                'Suministro de ${service.label}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
}
