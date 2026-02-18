import 'package:flutter/material.dart';
import 'package:app_cemdo/data/models/supply_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:app_cemdo/logic/providers/auth_provider.dart';
import 'package:app_cemdo/data/services/api_service.dart';
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
                  _buildInfoCard(),
                  if (_details?['consumos_historicos'] != null &&
                      (_details!['consumos_historicos'] is List) &&
                      (_details!['consumos_historicos'] as List)
                          .isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Histórico de Consumos'),
                    const SizedBox(height: 16),
                    _buildConsumptionChart(_details!['consumos_historicos']),
                  ],
                  if (widget.serviceId == 1 &&
                      _details?['latitud'] != null) ...[
                    const SizedBox(height: 24),
                    _buildMapPlaceholder(),
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
    final medidor = _details?['medidor'];
    String medidorText = 'Sin Medidor';
    if (medidor != null) {
      final marca = medidor['marca']?.toString() ?? '';
      final modelo = medidor['modelo']?.toString() ?? '';
      final serie = medidor['nro_serie']?.toString() ?? 'S/N';
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
              widget.supply.categoria,
            ),
            const Divider(),
            _buildDetailRow(Icons.speed, 'Medidor', medidorText),
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

  Widget _buildConsumptionChart(dynamic historicalData) {
    if (historicalData is! List || historicalData.isEmpty) {
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

    for (var yearIndex = 0; yearIndex < historicalData.length; yearIndex++) {
      final yearData = historicalData[yearIndex] as List<dynamic>;
      if (yearData.isEmpty) continue;

      final currentYear = yearData.first['anio'] as int;
      years.add(currentYear);

      final List<FlSpot> spots = [];
      for (var i = 0; i < yearData.length; i++) {
        final item = yearData[i];
        final periodo = (item['periodo'] as num).toDouble();
        final consumo = (item['consumo'] as num).toDouble();
        spots.add(FlSpot(periodo, consumo));
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
          dotData: const FlDotData(show: false), // Hide dots to avoid clutter
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
    final lat = _details?['latitud'];
    final lng = _details?['longitud'];

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
}
