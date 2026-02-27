import 'package:flutter/material.dart';
import 'package:app_cemdo/data/services/api_service.dart';
import 'package:app_cemdo/data/models/user_model.dart';
import 'package:app_cemdo/data/services/secure_storage_service.dart';
import 'package:app_cemdo/exceptions/email_not_verified_exception.dart';
import 'package:app_cemdo/data/services/error_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:app_cemdo/ui/utils/global_navigator_key.dart';

class AuthProvider with ChangeNotifier {
  late final ApiService _apiService;
  late final SecureStorageService _secureStorageService;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
    scopes: ['email', 'profile'],
  );

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

      debugPrint('AuthProvider.login raw response: $responseData');

      // Check if response is wrapped in 'data'
      final data = (responseData is Map && responseData.containsKey('data'))
          ? responseData['data']
          : responseData;

      if (data == null || data is! Map) {
        throw Exception('Respuesta de login inválida: se esperaba un objeto.');
      }

      final token = data['token'];
      final userMap = data['user'];

      if (token == null || userMap == null) {
        throw Exception('Token o usuario ausentes en la respuesta.');
      }

      final user = User.fromJson(userMap);
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

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null && accessToken == null) {
        throw Exception('No se pudo obtener el token de Google.');
      }

      // Enviar el token al backend (usamos accessToken o idToken según prefiera Socialite)
      final responseData = await _apiService.post(
        dotenv.env['GOOGLE_AUTH_CALLBACK_ENDPOINT'] ?? 'auth/google/callback',
        body: {'token': accessToken ?? idToken, 'device_name': 'mobile'},
      );

      debugPrint('AuthProvider.signInWithGoogle raw response: $responseData');

      final data = (responseData is Map && responseData.containsKey('data'))
          ? responseData['data']
          : responseData;

      if (data == null || data is! Map) {
        throw Exception('Respuesta de login Google inválida.');
      }

      final token = data['token'];
      final userMap = data['user'];

      if (token == null || userMap == null) {
        throw Exception('Token o usuario ausentes en la respuesta de Google.');
      }

      final user = User.fromJson(userMap);
      await _saveLoginData(token, user);
    } catch (e, stack) {
      debugPrint('Google Sign-In error: $e');
      ErrorService().reportError(e, stack, 'AuthProvider.signInWithGoogle');
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      debugPrint('Apple Sign-In Credential: $credential');

      // Enviar el token y datos al backend
      final responseData = await _apiService.post(
        dotenv.env['APPLE_AUTH_CALLBACK_ENDPOINT'] ?? 'auth/apple/callback',
        body: {
          'token': credential.identityToken,
          'code': credential.authorizationCode,
          'first_name': credential.givenName,
          'last_name': credential.familyName,
          'device_name': 'mobile',
        },
      );

      debugPrint('AuthProvider.signInWithApple raw response: $responseData');

      final data = (responseData is Map && responseData.containsKey('data'))
          ? responseData['data']
          : responseData;

      if (data == null || data is! Map) {
        throw Exception('Respuesta de login Apple inválida.');
      }

      final token = data['token'];
      final userMap = data['user'];

      if (token == null || userMap == null) {
        throw Exception('Token o usuario ausentes en la respuesta de Apple.');
      }

      final user = User.fromJson(userMap);
      await _saveLoginData(token, user);
    } catch (e, stack) {
      debugPrint('Apple Sign-In error: $e');
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        return; // User cancelled
      }
      ErrorService().reportError(e, stack, 'AuthProvider.signInWithApple');
      rethrow;
    }
  }

  Future<void> signInWithMicrosoft() async {
    try {
      final config = Config(
        tenant: 'common',
        clientId: dotenv.env['MICROSOFT_CLIENT_ID']!,
        scope: 'openid email profile offline_access User.Read',
        redirectUri: dotenv.env['MICROSOFT_REDIRECT']!,
        navigatorKey: GlobalNavigatorKey.navigatorKey,
        clientSecret:
            null, // For public client (native apps), secret should not be used
        responseType: 'code',
      );

      final AadOAuth oauth = AadOAuth(config);

      // Force login to ensure it asks for credentials
      await oauth.login();
      final String? token = await oauth.getAccessToken();

      if (token == null) {
        throw Exception('No se pudo obtener el token de Microsoft.');
      }

      // Enviar el token al backend
      final responseData = await _apiService.post(
        dotenv.env['MICROSOFT_AUTH_CALLBACK_ENDPOINT'] ??
            'auth/microsoft/callback',
        body: {'token': token, 'device_name': 'mobile'},
      );

      debugPrint(
        'AuthProvider.signInWithMicrosoft raw response: $responseData',
      );

      final data = (responseData is Map && responseData.containsKey('data'))
          ? responseData['data']
          : responseData;

      if (data == null || data is! Map) {
        throw Exception('Respuesta de login Microsoft inválida.');
      }

      final String? apiToken = data['token'];
      final userMap = data['user'];

      if (apiToken == null || userMap == null) {
        throw Exception(
          'Token o usuario ausentes en la respuesta de Microsoft.',
        );
      }

      final user = User.fromJson(userMap);
      await _saveLoginData(apiToken, user);
    } catch (e, stack) {
      debugPrint('Microsoft Sign-In error: $e');
      ErrorService().reportError(e, stack, 'AuthProvider.signInWithMicrosoft');
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

  Future<void> resendVerificationEmail() async {
    try {
      await _apiService.post('email/resend');
    } catch (e, stack) {
      debugPrint('Error resending verification email: $e');
      ErrorService().reportError(
        e,
        stack,
        'AuthProvider.resendVerificationEmail',
      );
      rethrow;
    }
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
