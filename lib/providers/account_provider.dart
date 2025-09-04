import 'package:app_cemdo/models/account_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; // Added
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Added
import 'dart:convert'; // Added for jsonDecode
import 'package:app_cemdo/services/secure_storage_service.dart'; // Added
import 'package:app_cemdo/models/user_model.dart'; // Added

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
      _activeAccount =
          null; // Set active account to null if the unlinked account was the active one
    }
    notifyListeners();
    // The API call will now be handled by unlinkAccountApi
  }

  // New method to unlink account via API
  Future<bool> unlinkAccountApi(String token, int accountIdToUnlink) async {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) {
      debugPrint('BACKEND_URL not configured.');
      return false;
    }

    final url = Uri.parse('$backendUrl/accounts/unlink');
    debugPrint('Unlinking account: $accountIdToUnlink via $url');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $token',
        },
        body: {'cuenta_activa': accountIdToUnlink.toString()},
      );

      debugPrint('Unlink account response status code: ${response.statusCode}');
      debugPrint('Unlink account response body: ${response.body}');

      if (response.statusCode == 200) {
        // If API call is successful, then update local state
        // Find the account to unlink. If not found, it's an unexpected state.
        final accountToUnlink = _accounts.firstWhere(
          (acc) => acc.idcliente == accountIdToUnlink,
          orElse: () => throw Exception(
            'Account not found locally after successful unlink API call',
          ),
        );
        unlinkAccount(accountToUnlink); // Call the local state update method

        // Update ultimo_idcliente in stored User object
        final secureStorageService = SecureStorageService();
        User? currentUser = await secureStorageService.getUser();
        if (currentUser != null) {
          if (currentUser.ultimoIdCliente == accountIdToUnlink) {
            // If the unlinked account was the active one
            int? newUltimoIdCliente;
            if (_accounts.isNotEmpty) {
              // Set to the first remaining account
              newUltimoIdCliente = _accounts.first.idcliente;
            } else {
              // No accounts left
              newUltimoIdCliente = null;
            }
            currentUser = currentUser.copyWith(
              ultimoIdCliente: newUltimoIdCliente,
            );
            await secureStorageService.updateUser(currentUser);
          }
        }
        return true;
      } else {
        debugPrint('Failed to unlink account: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error unlinking account: $e');
      return false;
    }
  }

  // New method to fetch accounts from the backend
  Future<void> fetchAccounts(String token) async {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) {
      debugPrint('BACKEND_URL not configured.');
      return;
    }

    final url = Uri.parse(
      '$backendUrl/accounts',
    ); // Assuming /accounts endpoint
    debugPrint('Fetching accounts from: $url'); // Added debug print
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        'Response status code: ${response.statusCode}',
      ); // Added debug print
      debugPrint('Response body: ${response.body}'); // Added debug print

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = jsonDecode(response.body);
        final List<dynamic> responseData =
            decodedResponse['data']; // Access the 'data' key
        debugPrint('Parsed response data: $responseData'); // Added debug print
        _accounts = responseData.map((json) => Account.fromJson(json)).toList();
        debugPrint(
          'Number of accounts fetched: ${_accounts.length}',
        ); // Added debug print
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

  Future<bool> changeActiveAccount(String token, int newActiveAccountId) async {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) {
      debugPrint('BACKEND_URL not configured.');
      return false;
    }

    final url = Uri.parse('$backendUrl/accounts/change-active');
    debugPrint('Changing active account to: $newActiveAccountId via $url');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $token',
        },
        body: {'cuenta_activa': newActiveAccountId.toString()},
      );

      debugPrint(
        'Change active account response status code: ${response.statusCode}',
      );
      debugPrint('Change active account response body: ${response.body}');

      if (response.statusCode == 200) {
        // Update the active account in the provider
        Account? updatedAccount;
        try {
          updatedAccount = _accounts.firstWhere(
            (acc) => acc.idcliente == newActiveAccountId,
          );
        } catch (e) {
          debugPrint('New active account not found locally: $e');
          // If the new active account is not found locally, it's an unexpected state.
          // We might want to re-fetch accounts or handle this error more gracefully.
          return false;
        }

        _activeAccount = updatedAccount;
        notifyListeners();

        // Update ultimo_idcliente in stored User object
        final secureStorageService = SecureStorageService();
        User? currentUser = await secureStorageService.getUser();
        if (currentUser != null) {
          currentUser = currentUser.copyWith(
            ultimoIdCliente: newActiveAccountId,
          );
          await secureStorageService.updateUser(currentUser);
        }
        return true;
      } else {
        debugPrint('Failed to change active account: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error changing active account: $e');
      return false;
    }
  }

  Future<bool> linkAccount(
    String token,
    String nroUsuario,
    String cuentaAgrupada,
  ) async {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) {
      debugPrint('BACKEND_URL not configured.');
      return false;
    }

    final url = Uri.parse('$backendUrl/accounts/link');
    debugPrint('Linking account: $nroUsuario via $url');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $token',
        },
        body: {'nro_usuario': nroUsuario, 'cuenta_agrupada': cuentaAgrupada},
      );

      debugPrint('Link account response status code: ${response.statusCode}');
      debugPrint('Link account response body: ${response.body}');

      if (response.statusCode == 200) {
        // If API call is successful, then refresh the accounts list
        await fetchAccounts(token);

        // Find the newly linked account and set it as active
        final newAccountId = int.tryParse(nroUsuario);
        if (newAccountId != null) {
          final accountExists = _accounts.any(
            (acc) => acc.idcliente == newAccountId,
          );
          if (accountExists) {
            return await changeActiveAccount(token, newAccountId);
          }
        }
        // If we are here, something went wrong with finding the new account.
        debugPrint(
          'Failed to find the newly linked account to set it as active.',
        );
        return false;
      } else {
        debugPrint('Failed to link account: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error linking account: $e');
      return false;
    }
  }
}
