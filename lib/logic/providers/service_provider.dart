import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:app_cemdo/data/models/service_model.dart';
import 'package:app_cemdo/data/models/supply_model.dart';

class ServiceProvider with ChangeNotifier {
  List<Service> _services = [];
  List<Supply> _supplies = [];
  bool _isLoading = false;

  List<Service> get services => _services;
  List<Supply> get supplies => _supplies;
  bool get isLoading => _isLoading;

  Future<void> fetchServices(String token, int idCliente) async {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) {
      debugPrint('BACKEND_URL not configured.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    final url = Uri.parse('$backendUrl/services?id_cliente=$idCliente');
    debugPrint('Fetching services from: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = jsonDecode(response.body);
        final List<dynamic> responseData = decodedResponse['data'];
        _services = responseData.map((json) => Service.fromJson(json)).toList();
      } else {
        debugPrint('Failed to load services: ${response.statusCode}');
        _services = [];
      }
    } catch (e) {
      debugPrint('Error fetching services: $e');
      _services = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSupplies(
    String token,
    int idCliente,
    int idServicio,
  ) async {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) {
      debugPrint('BACKEND_URL not configured.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(
      '$backendUrl/suministros?id_cliente=$idCliente&id_servicio=$idServicio',
    );
    debugPrint('Fetching supplies from: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = jsonDecode(response.body);
        final List<dynamic> responseData = decodedResponse['data'];
        _supplies = responseData.map((json) => Supply.fromJson(json)).toList();
      } else {
        debugPrint('Failed to load supplies: ${response.statusCode}');
        _supplies = [];
      }
    } catch (e) {
      debugPrint('Error fetching supplies: $e');
      _supplies = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
