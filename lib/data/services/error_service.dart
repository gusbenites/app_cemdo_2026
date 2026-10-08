import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:app_cemdo/data/services/api_service.dart';
import 'package:app_cemdo/ui/utils/error_notification.dart';

class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();

  bool _isInitialized = false;

  Future<void> init({required String dsn, required String environment}) async {
    if (_isInitialized) return;

    await SentryFlutter.init((options) {
      options.dsn = dsn;
      options.environment = environment;
      options.tracesSampleRate = 1.0;
    });
    _isInitialized = true;
    log('ErrorService initialized in $environment mode');
  }

  bool _isNetworkOfflineError(Object error) {
    if (error is SocketException || error is TimeoutException) {
      return true;
    }
    if (error is http.ClientException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('connection closed') ||
          msg.contains('connection reset') ||
          msg.contains('connection refused') ||
          msg.contains('failed host lookup') ||
          msg.contains('network is unreachable')) {
        return true;
      }
    }
    if (error is OSError) {
      // errno 7 = No address associated with hostname, errno 101/51 = Network unreachable
      if (error.errorCode == 7 ||
          error.errorCode == 101 ||
          error.errorCode == 51) {
        return true;
      }
    }
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('no address associated with hostname') ||
        errorStr.contains('network is unreachable') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('connection closed before full header was received')) {
      return true;
    }
    return false;
  }

  void reportError(Object error, [StackTrace? stackTrace, String? hint]) {
    log('Error reported: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }

    if (_isInitialized && !_isNetworkOfflineError(error)) {
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          if (hint != null) {
            scope.setTag('hint', hint);
          }
        },
      );
    }

    _notifyUser(error);
  }

  /// true si [error] es un 5xx que `ApiService._handleResponse` ya envió a
  /// Sentry (con el método y la URL en el hint).
  static bool isAlreadyReportedApiError(Object error) =>
      error is ApiException && error.statusCode >= 500;

  /// Igual que [reportError], pero omite el envío cuando el error es un 5xx
  /// de [ApiService], porque `ApiService._handleResponse` ya lo reporta con el
  /// método y la URL en el hint.
  ///
  /// Reportarlo también desde el provider crea un **segundo** evento en Sentry
  /// con otro stacktrace (mismo fallo partido en dos issues) y un SnackBar
  /// extra para el usuario.
  void reportApiError(Object error, [StackTrace? stackTrace, String? hint]) {
    if (isAlreadyReportedApiError(error)) {
      log('5xx ya reportado por ApiService (${hint ?? 'sin hint'}) — omitido.');
      return;
    }
    reportError(error, stackTrace, hint);
  }

  /// Para los flujos de login social (Apple / Google / Microsoft).
  ///
  /// Ahí el backend hace `report($e)` con la causa real (el ApiException que
  /// llega a la app sólo lleva un mensaje genérico), así que reportarlo también
  /// desde la app duplica el evento sin sumar información.
  ///
  /// Sólo se envían los errores que **no** son [ApiException]: fallos locales
  /// como una respuesta mal formada o un `User.fromJson` inválido, que el
  /// backend nunca va a ver.
  void reportSocialAuthError(
    Object error, [
    StackTrace? stackTrace,
    String? hint,
  ]) {
    if (error is ApiException) {
      log(
        'ApiException de login social no reportada '
        '(${error.statusCode}): ${hint ?? 'sin hint'}',
      );
      return;
    }
    reportError(error, stackTrace, hint);
  }

  void log(String message) {
    debugPrint('[ErrorService] $message');
  }

  void _notifyUser(Object error) {
    String message = 'Ha ocurrido un error inesperado.';
    String code = '[F]';

    if (error is SocketException || error is http.ClientException) {
      message = 'Problema de conexión con el servidor. Verifica tu internet.';
      code = '[C]';
    } else if (error is TimeoutException) {
      message = 'El servidor tardó demasiado en responder. Inténtalo de nuevo.';
      code = '[C]';
    } else if (error is ApiException) {
      if (error.statusCode >= 500) {
        message =
            'El servicio está temporalmente fuera de servicio o en mantenimiento. Por favor, intente de nuevo más tarde.';
        code = '[S]';
      } else {
        message = error.message;
        code = '[B]';
      }
    } else if (error is Exception) {
      message = error.toString().replaceAll('Exception: ', '');
    } else if (error is String) {
      message = error;
    }

    ErrorNotification.showSnackBar('$message $code');
  }
}
