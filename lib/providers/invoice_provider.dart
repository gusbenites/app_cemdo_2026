import 'package:flutter/foundation.dart';
import 'package:app_cemdo/models/invoice_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class InvoiceProvider with ChangeNotifier {
  List<Invoice> _unpaidInvoices = [];
  List<Invoice> _allInvoices = []; // Added

  List<Invoice> get unpaidInvoices => _unpaidInvoices;
  List<Invoice> get allInvoices => _allInvoices; // Added

  Future<void> fetchInvoices(String token, int idCliente, {bool showAll = false}) async { // Modified method signature
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) {
      debugPrint('BACKEND_URL not configured.');
      return;
    }

    String endpoint = showAll ? '/invoices' : '/invoices/unpaid'; // Determine endpoint
    final url = Uri.parse('$backendUrl$endpoint?idcliente=$idCliente'); // Construct URL
    debugPrint('Fetching invoices from: $url');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = jsonDecode(response.body);
        final List<dynamic> responseData = decodedResponse['data'];
        List<Invoice> fetchedInvoices = responseData.map((json) => Invoice.fromJson(json)).toList();
        debugPrint('Number of invoices fetched: ${fetchedInvoices.length}');

        if (showAll) {
          _allInvoices = fetchedInvoices;
          _unpaidInvoices = fetchedInvoices.where((invoice) => invoice.isVencida).toList(); // Populate unpaid from all
        } else {
          _unpaidInvoices = fetchedInvoices;
          // If fetching only unpaid, we don't update _allInvoices from here
        }
        notifyListeners();
      } else {
        debugPrint('Failed to load invoices: ${response.statusCode}');
        if (showAll) {
          _allInvoices = [];
        } else {
          _unpaidInvoices = [];
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching invoices: $e');
      if (showAll) {
        _allInvoices = [];
      } else {
        _unpaidInvoices = [];
      }
      notifyListeners();
    }
  }
}
