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

  void reportError(Object error, [StackTrace? stackTrace, String? hint]) {
    log('Error reported: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }

    if (_isInitialized) {
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
        message = 'El servidor está experimentando problemas técnicos.';
        code = '[B]';
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
