import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_cemdo/models/user_model.dart';
import 'package:app_cemdo/services/secure_storage_service.dart';
import 'package:app_cemdo/exceptions/email_not_verified_exception.dart'; // New import

class AuthProvider with ChangeNotifier {
  final SecureStorageService _secureStorageService = SecureStorageService();
  User? _user;
  String? _token;

  User? get user => _user;
  String? get token => _token;

  Future<void> _saveLoginData(String token, User user) async {
    _token = token;
    _user = user;
    await _secureStorageService.storeLoginData(token, user);
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) {
      throw Exception('URL del backend no configurada.');
    }

    final url = Uri.parse('$backendUrl/login');
    final deviceName = 'mobile'; // You might want to get a unique device name

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {'email': email, 'password': password, 'device_name': deviceName},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final token = responseData['token'];
      final user = User.fromJson(responseData['user']);
      await _saveLoginData(token, user);
    } else {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['message'] ?? 'Error de inicio de sesión.';
      debugPrint('Backend error message: $errorMessage'); // Added debugPrint
      if (errorMessage.contains('Email no verificado')) {
        throw EmailNotVerifiedException(errorMessage);
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
    String deviceName,
  ) async {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null) {
      throw Exception('URL del backend no configurada.');
    }

    final url = Uri.parse('$backendUrl/register');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_name': deviceName,
      }),
    );

    if (response.statusCode == 201) {
      // Registration successful, backend should send verification email
      // No token or user data to save yet, as email verification is pending
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error en el registro.');
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    await _secureStorageService.deleteLoginData();
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    final storedToken = await _secureStorageService.getToken();
    final storedUser = await _secureStorageService.getUser();

    if (storedToken != null && storedUser != null) {
      debugPrint('storedUser: $storedUser');
      // Check if email is verified
      if (storedUser.emailVerifiedAt == null) {
        // Email not verified, clear session and return
        await logout();
        return;
      }

      _token = storedToken;
      _user = storedUser;
      notifyListeners();
    }
  }
}
