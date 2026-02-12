import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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
      // Don't report errors in debug mode to Sentry if you prefer
      // options.beforeSend = (event, {hint}) => kDebugMode ? null : event;
    });
    _isInitialized = true;
    log('ErrorService initialized in $environment mode');
  }

  void reportError(Object error, [StackTrace? stackTrace, String? hint]) {
    // 1. Log to console
    log('Error reported: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }

    // 2. Report to Sentry
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

    // 3. Notify user (optional, depends on error type or context)
    // For now, we show a generic snackbar for all reported errors
    // unless we decide otherwise based on the error type.
    _notifyUser(error);
  }

  void log(String message) {
    debugPrint('[ErrorService] $message');
  }

  void _notifyUser(Object error) {
    String message = 'Ha ocurrido un error inesperado.';

    if (error is Exception) {
      // Custom handling for specific exceptions can be added here
      message = error.toString().replaceAll('Exception: ', '');
    } else if (error is String) {
      message = error;
    }

    ErrorNotification.showSnackBar(message);
  }
}
