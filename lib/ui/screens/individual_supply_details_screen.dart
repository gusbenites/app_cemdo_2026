import 'package:flutter/material.dart';
import 'package:app_cemdo/data/models/supply_model.dart';
import 'package:app_cemdo/logic/providers/auth_provider.dart';
import 'package:app_cemdo/logic/providers/service_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart'; // Uncomment once used

class IndividualSupplyDetailsScreen extends StatefulWidget {
  final Supply supply;
  final String tag;
  final int serviceId;

  const IndividualSupplyDetailsScreen({
    super.key,
    required this.supply,
    required this.tag,
    required this.serviceId,
  });

  @override
  State<IndividualSupplyDetailsScreen> createState() =>
      _IndividualSupplyDetailsScreenState();
}

class _IndividualSupplyDetailsScreenState
    extends State<IndividualSupplyDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  SupplyDetails? _details;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final serviceProvider = Provider.of<ServiceProvider>(
        context,
        listen: false,
      );
      final details = await serviceProvider.fetchSupplyDetails(
        authProvider.token!,
        widget.supply.idsuministro,
      );

      if (details != null) {
        setState(() {
          _details = details;
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
                  _buildInfoCard(),
                  if (_details!.consumos != null &&
                      _details!.consumos!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Histórico de Consumos'),
                    const SizedBox(height: 16),
                    _buildConsumptionChart(_details!.consumos!),
                  ],
                  if (_details!.coordenadas?.latitud != null) ...[
                    const SizedBox(height: 24),
                    _buildMapPlaceholder(),
                  ],
                  if (widget.serviceId == 3 &&
                      _details!.grupoFamiliar != null &&
                      _details!.grupoFamiliar!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Grupo Familiar'),
                    const SizedBox(height: 16),
                    _buildFamilyGroup(),
                  ],
                  if (widget.serviceId == 3 &&
                      _details!.habilitados != null) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Estado de Servicios'),
                    const SizedBox(height: 16),
                    _buildEnabledServices(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0D47A1),
      ),
    );
  }

  Widget _buildInfoCard() {
    final medidor = _details?.medidor;
    String medidorText = 'Sin Medidor';
    if (medidor != null &&
        medidor.numero.isNotEmpty &&
        medidor.numero.toLowerCase() != 'null') {
      final marca = medidor.marca;
      final modelo = medidor.modelo;
      final serie = medidor.numero;
      medidorText = '$marca $modelo'.trim();
      if (medidorText.isEmpty) medidorText = 'Medidor';
      medidorText += ' (Nº Serie: $serie)';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow(
              Icons.location_on,
              'Domicilio',
              _details?.direccion ?? widget.supply.direccion,
            ),
            const Divider(),
            _buildDetailRow(
              Icons.location_city,
              'Localidad',
              _details?.localidad ?? widget.supply.localidad,
            ),
            const Divider(),
            _buildDetailRow(
              Icons.category,
              'Categoría',
              _details?.categoria ?? widget.supply.categoria,
            ),
            if ((widget.serviceId == 1 ||
                    widget.serviceId == 2 ||
                    widget.serviceId == 99) ||
                (medidorText != 'Sin Medidor' && widget.serviceId != 3)) ...[
              const Divider(),
              _buildDetailRow(Icons.speed, 'Medidor', medidorText),
            ],
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

  Widget _buildConsumptionChart(
    Map<String, List<ConsumptionData>> consumptionMap,
  ) {
    if (consumptionMap.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = [
      Colors.blue[700]!,
      Colors.green[600]!,
      Colors.orange[600]!,
      Colors.red[600]!,
      Colors.purple[600]!,
      Colors.teal[600]!,
    ];

    final unit = widget.serviceId == 2 ? 'm³' : 'kWh';

    final List<LineChartBarData> lines = [];
    final List<int> years = [];

    // Sort years descending to show latest first in legend, but ascending for processing if needed
    final sortedYears = consumptionMap.keys.toList()..sort();

    for (var yearStr in sortedYears) {
      final yearData = consumptionMap[yearStr]!;
      if (yearData.isEmpty) continue;

      final currentYear = int.tryParse(yearStr) ?? 0;
      years.add(currentYear);

      final List<FlSpot> spots = [];
      for (var item in yearData) {
        spots.add(FlSpot(item.periodo.toDouble(), item.consumo));
      }
      spots.sort((a, b) => a.x.compareTo(b.x));

      final color = colors[lines.length % colors.length];

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: color.withValues(alpha: 0.05),
          ),
        ),
      );
    }

    if (lines.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Container(
          height: 300,
          padding: const EdgeInsets.only(
            top: 24,
            bottom: 12,
            left: 12,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 2,
                blurRadius: 5,
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final year = years[spot.barIndex];
                      return LineTooltipItem(
                        '$year - Mes ${spot.x.toInt()}: ${spot.y.toInt()} $unit',
                        const TextStyle(color: Colors.white, fontSize: 10),
                      );
                    }).toList();
                  },
                ),
              ),
              minX: 1,
              maxX: 12,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 100,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: Colors.grey[200], strokeWidth: 1),
                getDrawingVerticalLine: (value) =>
                    FlLine(color: Colors.grey[100], strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                  axisNameWidget: Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value >= 1 && value <= 12) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: Colors.grey[300]!),
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              lineBarsData: lines,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: List.generate(years.length, (index) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, color: lines[index].color),
                const SizedBox(width: 4),
                Text(
                  years[index].toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder() {
    final lat = _details?.coordenadas?.latitud;
    final lng = _details?.coordenadas?.longitud;

    if (lat == null || lng == null) return const SizedBox.shrink();

    final position = LatLng(lat.toDouble(), lng.toDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ubicación'),
        const SizedBox(height: 16),
        Container(
          height: 250,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(initialCenter: position, initialZoom: 15.0),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.app_cemdo.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: position,
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.location_on,
                          color: Colors.red[700],
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '© OpenStreetMap',
                    style: TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Coordenadas: $lat, $lng',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () async {
            final url = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
            );
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
          icon: const Icon(Icons.map),
          label: const Text('Navegar con Google Maps'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[900],
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyGroup() {
    return Column(
      children: _details!.grupoFamiliar!.map((member) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue[50],
                      radius: 20,
                      child: Text(
                        member.parentesco.isNotEmpty
                            ? member.parentesco.substring(0, 1).toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${member.apellido}, ${member.nombre}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            member.parentesco,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMemberConceptBadge(
                      Icons.church_outlined,
                      'Sepelio',
                      member.sepelio,
                    ),
                    _buildMemberConceptBadge(
                      Icons.medical_services_outlined,
                      'Ambulancia',
                      member.ambulancia,
                    ),
                    _buildMemberConceptBadge(
                      Icons.local_hospital_outlined,
                      'Enfermería',
                      member.enfermeria,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMemberConceptBadge(IconData icon, String label, String status) {
    final bool isHabilitado = status.toUpperCase() == 'HABILITADO';
    final bool isInhabilitado = status.toUpperCase() == 'INHABILITADO';

    Color color;
    if (isHabilitado) {
      color = Colors.green;
    } else if (isInhabilitado) {
      color = Colors.red;
    } else {
      color = Colors.grey;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: isHabilitado ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          status.isEmpty ? 'N/A' : status,
          style: TextStyle(fontSize: 9, color: color.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildEnabledServices() {
    final enabled = _details!.habilitados!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatusIndicator('Sepelio', enabled.sepelio),
            _buildStatusIndicator('Ambulancia', enabled.ambulancia),
            _buildStatusIndicator('Enfermería', enabled.enfermeria),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isEnabled) {
    return Column(
      children: [
        Icon(
          isEnabled ? Icons.check_circle : Icons.cancel,
          color: isEnabled ? Colors.green : Colors.red,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
