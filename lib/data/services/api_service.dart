import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_cemdo/data/services/error_service.dart';

class ApiService {
  final http.Client _client = http.Client();

  String get _baseUrl => dotenv.env['BACKEND_URL'] ?? '';

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint, {String? token}) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: _headers(token),
      );
      return _handleResponse(response);
    } catch (e, stack) {
      if (e is! ApiException) {
        ErrorService().reportError(e, stack, 'ApiService.get connection error');
      }
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body, String? token}) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e, stack) {
      if (e is! ApiException) {
        ErrorService().reportError(
          e,
          stack,
          'ApiService.post connection error',
        );
      }
      rethrow;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      final exception = ApiException(
        message: _getErrorMessage(response),
        statusCode: response.statusCode,
      );
      // We don't necessarily want to report every 4xx to Sentry,
      // but maybe we want to log them or report 5xx.
      if (response.statusCode >= 500) {
        ErrorService().reportError(exception, null, 'ApiService server error');
      }
      throw exception;
    }
  }

  String _getErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body['message'] ?? 'Error desconocido';
    } catch (_) {
      return 'Error ${response.statusCode}: ${response.reasonPhrase}';
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => message;
}
