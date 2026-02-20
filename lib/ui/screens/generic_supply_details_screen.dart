import 'package:flutter/material.dart';
import 'package:app_cemdo/data/models/supply_model.dart';
import 'package:provider/provider.dart';
import 'package:app_cemdo/logic/providers/auth_provider.dart';
import 'package:app_cemdo/data/services/api_service.dart';

class GenericSupplyDetailsScreen extends StatefulWidget {
  final Supply supply;
  final String tag;

  const GenericSupplyDetailsScreen({
    super.key,
    required this.supply,
    required this.tag,
  });

  @override
  State<GenericSupplyDetailsScreen> createState() =>
      _GenericSupplyDetailsScreenState();
}

class _GenericSupplyDetailsScreenState
    extends State<GenericSupplyDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _details;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService();
      final response = await apiService.get(
        'services/${widget.supply.idsuministro}',
        token: authProvider.token,
      );

      if (response != null && response['data'] != null) {
        setState(() {
          _details = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No se pudieron cargar los detalles.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle Suministro #${widget.supply.idsuministro}'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _fetchDetails();
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
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
                            widget.supply.direccion,
                          ),
                          const Divider(),
                          _buildDetailRow(
                            Icons.location_city,
                            'Localidad',
                            widget.supply.localidad,
                          ),
                          const Divider(),
                          _buildDetailRow(
                            Icons.category,
                            'Categoría',
                            _details?['categoria'] ?? widget.supply.categoria,
                          ),
                          const Divider(),
                          _buildDetailRow(
                            Icons.info_outline,
                            'Estado',
                            widget.supply.estado,
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
