import 'package:app_cemdo/models/account_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; // Added
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Added
import 'dart:convert'; // Added for jsonDecode

class AccountProvider with ChangeNotifier {
  Account? _activeAccount;
  List<Account> _accounts = [];

  Account? get activeAccount => _activeAccount;
  List<Account> get accounts => _accounts;

  // Constructor no longer initializes with sample data
  AccountProvider();

  void setActiveAccount(Account account) {
    _activeAccount = account;
    notifyListeners();
    // Here you would also call the API to update the user's `ultimo_idcliente`
  }

  void unlinkAccount(Account account) {
    _accounts.removeWhere((acc) => acc.idcliente == account.idcliente);
    if (_activeAccount?.idcliente == account.idcliente) {
      _activeAccount = _accounts.isNotEmpty ? _accounts.first : null;
    }
    notifyListeners();
    // Here you would also call the API to unlink the account
  }

  // New method to fetch accounts from the backend
  Future<void> fetchAccounts(String token) async {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) {
      debugPrint('BACKEND_URL not configured.');
      return;
    }

    final url = Uri.parse('$backendUrl/accounts'); // Assuming /accounts endpoint
    debugPrint('Fetching accounts from: $url'); // Added debug print
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Response status code: ${response.statusCode}'); // Added debug print
      debugPrint('Response body: ${response.body}'); // Added debug print

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = jsonDecode(response.body);
        final List<dynamic> responseData = decodedResponse['data']; // Access the 'data' key
        debugPrint('Parsed response data: $responseData'); // Added debug print
        _accounts = responseData.map((json) => Account.fromJson(json)).toList();
        debugPrint('Number of accounts fetched: ${_accounts.length}'); // Added debug print
        // Optionally set active account if there's only one or based on some logic
        if (_accounts.isNotEmpty && _activeAccount == null) {
          _activeAccount = _accounts.first;
        }
        notifyListeners();
      } else {
        debugPrint('Failed to load accounts: ${response.statusCode}');
        _accounts = []; // Clear accounts on error
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching accounts: $e');
      _accounts = []; // Clear accounts on error
      notifyListeners();
    }
  }
}
