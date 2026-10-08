import 'package:flutter_test/flutter_test.dart';
import 'package:app_cemdo/data/services/error_service.dart';
import 'package:app_cemdo/data/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ErrorService.isAlreadyReportedApiError', () {
    test('is true for every 5xx ApiException', () {
      for (final statusCode in [500, 502, 503, 504]) {
        final error = ApiException(message: 'falla', statusCode: statusCode);

        expect(
          ErrorService.isAlreadyReportedApiError(error),
          isTrue,
          reason: 'el status $statusCode debe considerarse ya reportado',
        );
      }
    });

    test('is false for client errors (4xx)', () {
      final error = ApiException(message: 'falla', statusCode: 422);

      expect(ErrorService.isAlreadyReportedApiError(error), isFalse);
    });

    test('is false for exceptions that are not ApiException', () {
      expect(
        ErrorService.isAlreadyReportedApiError(Exception('cualquiera')),
        isFalse,
      );
    });
  });

  group('ErrorService.reportApiError', () {
    late ErrorService errorService;

    setUp(() {
      errorService = ErrorService();
    });

    test('skips a 5xx already reported by ApiService', () {
      final error = ApiException(message: 'Internal Error', statusCode: 500);

      expect(() => errorService.reportApiError(error), returnsNormally);
    });

    test('still reports a 4xx ApiException', () {
      final error = ApiException(message: 'Bad Request', statusCode: 400);

      expect(() => errorService.reportApiError(error), returnsNormally);
    });

    test('still reports an ApiException with a null stack trace', () {
      final error = ApiException(message: 'Bad Request', statusCode: 404);

      expect(
        () => errorService.reportApiError(error, null, 'hint-de-prueba'),
        returnsNormally,
      );
    });
  });

  group('ErrorService.reportSocialAuthError', () {
    late ErrorService errorService;

    setUp(() {
      errorService = ErrorService();
    });

    test('skips ApiException of any status (backend already reports it)', () {
      for (final statusCode in [401, 422, 500]) {
        final error = ApiException(message: 'falla', statusCode: statusCode);

        expect(
          () => errorService.reportSocialAuthError(error),
          returnsNormally,
          reason: 'el status $statusCode no debe reportarse desde la app',
        );
      }
    });

    test('still reports errors that are not ApiException', () {
      expect(
        () => errorService.reportSocialAuthError(
          Exception('respuesta mal formada'),
          StackTrace.current,
          'AuthProvider.signInWithApple',
        ),
        returnsNormally,
      );
    });
  });
}
