import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_cemdo/data/models/supply_model.dart';
import 'package:app_cemdo/data/models/service_model.dart';
import 'package:app_cemdo/data/services/error_service.dart';

class ServiceProvider with ChangeNotifier {
  List<Service> _services = [];

  bool _isLoading = false;

  List<Service> get services => _services;

  bool get isLoading => _isLoading;

  Future<void> fetchServices(String token, int idCliente) async {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) {
      debugPrint('BACKEND_URL not configured.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    final url = Uri.parse('$backendUrl/services?idcliente=$idCliente');
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
        final errorMsg = 'Failed to load services: ${response.statusCode}';
        debugPrint(errorMsg);
        ErrorService().reportError(
          errorMsg,
          null,
          'ServiceProvider.fetchServices',
        );
        _services = [];
      }
    } catch (e, stack) {
      debugPrint('Error fetching services: $e');
      ErrorService().reportError(e, stack, 'ServiceProvider.fetchServices');
      _services = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SupplyDetails?> fetchSupplyDetails(
    String token,
    int idSuministro,
  ) async {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) {
      debugPrint('BACKEND_URL not configured.');
      return null;
    }

    final url = Uri.parse('$backendUrl/services/$idSuministro');
    debugPrint('Fetching supply details from: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = jsonDecode(response.body);
        if (decodedResponse['data'] != null) {
          return SupplyDetails.fromJson(decodedResponse['data']);
        }
      } else {
        final errorMsg =
            'Failed to load supply details: ${response.statusCode}';
        debugPrint(errorMsg);
        ErrorService().reportError(
          errorMsg,
          null,
          'ServiceProvider.fetchSupplyDetails',
        );
      }
    } catch (e, stack) {
      debugPrint('Error fetching supply details: $e');
      ErrorService().reportError(
        e,
        stack,
        'ServiceProvider.fetchSupplyDetails',
      );
    }
    return null;
  }

  void clearServices() {
    _services = [];
    notifyListeners();
  }
}
