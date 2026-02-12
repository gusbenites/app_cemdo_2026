import 'package:flutter_test/flutter_test.dart';
import 'package:app_cemdo/data/services/error_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ErrorService singleton test', () {
    final service1 = ErrorService();
    final service2 = ErrorService();
    expect(identical(service1, service2), isTrue);
  });

  test('ErrorService reporting doesn\'t crash before init', () {
    final service = ErrorService();
    // Should not throw even if not initialized
    expect(() => service.reportError('Test error'), returnsNormally);
  });
}
