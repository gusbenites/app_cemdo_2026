import 'package:flutter/material.dart';
import 'package:app_cemdo/data/services/api_service.dart';
import 'package:app_cemdo/data/models/user_model.dart';
import 'package:app_cemdo/data/services/secure_storage_service.dart';
import 'package:app_cemdo/exceptions/email_not_verified_exception.dart';

class AuthProvider with ChangeNotifier {
  late final ApiService _apiService;
  late final SecureStorageService _secureStorageService;

  AuthProvider({
    ApiService? apiService,
    SecureStorageService? secureStorageService,
  }) {
    _apiService = apiService ?? ApiService();
    _secureStorageService = secureStorageService ?? SecureStorageService();
  }
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
    final deviceName = 'mobile';

    try {
      final responseData = await _apiService.post(
        'login',
        body: {'email': email, 'password': password, 'device_name': deviceName},
      );

      final token = responseData['token'];
      final user = User.fromJson(responseData['user']);
      await _saveLoginData(token, user);
    } catch (e) {
      final errorMessage = e.toString();
      debugPrint('Login error: $errorMessage');
      if (errorMessage.contains('Email no verificado')) {
        throw EmailNotVerifiedException(errorMessage);
      }
      rethrow;
    }
  }

  Future<void> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
    String deviceName,
  ) async {
    await _apiService.post(
      'register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_name': deviceName,
      },
    );
    // Registration successful
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
      if (storedUser.emailVerifiedAt == null) {
        await logout();
        return;
      }

      _token = storedToken;
      _user = storedUser;
      notifyListeners();
    }
  }
}
