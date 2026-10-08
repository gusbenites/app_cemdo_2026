import 'package:flutter_test/flutter_test.dart';
import 'package:app_cemdo/data/models/user_model.dart';

void main() {
  group('User.fromJson', () {
    test('should parse correctly when all fields are correct types', () {
      final json = <String, dynamic>{
        'id': 1,
        'name': 'Test User',
        'email': 'test@example.com',
        'avatar': null,
        'ultimo_idcliente': 123,
        'is_admin': 1,
        'email_verified_at': '2023-01-01T00:00:00.000000Z',
      };

      final user = User.fromJson(json);

      expect(user.id, 1);
      expect(user.name, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.avatar, isNull);
      expect(user.ultimoIdCliente, 123);
      expect(user.isAdmin, isTrue);
      expect(user.emailVerifiedAt, '2023-01-01T00:00:00.000000Z');
    });

    test('should not throw when optional fields arrive as objects', () {
      // Regresión de FLUTTER-APP-V2-11:
      // "type '_Map<String, dynamic>' is not a subtype of type 'String?'"
      final json = <String, dynamic>{
        'id': 1,
        'name': 'Test User',
        'email': 'test@example.com',
        'avatar': {'url': 'https://example.com/a.png'},
        'ultimo_idcliente': '456',
        'is_admin': 0,
        'email_verified_at': {'date': '2023-01-01'},
      };

      final user = User.fromJson(json);

      expect(user.id, 1);
      expect(user.avatar, isNull);
      expect(user.ultimoIdCliente, 456);
      expect(user.emailVerifiedAt, isNull);
      expect(user.isAdmin, isFalse);
    });

    test('should keep optional fields null when they are missing', () {
      final json = <String, dynamic>{
        'id': 7,
        'name': 'Test User',
        'email': 'test@example.com',
      };

      final user = User.fromJson(json);

      expect(user.id, 7);
      expect(user.avatar, isNull);
      expect(user.ultimoIdCliente, isNull);
      expect(user.emailVerifiedAt, isNull);
      expect(user.isAdmin, isFalse);
    });

    test('should throw FormatException when a required field is missing', () {
      final json = <String, dynamic>{
        'name': 'Test User',
        'email': 'test@example.com',
      };

      expect(() => User.fromJson(json), throwsFormatException);
    });
  });

  group('User.toJson', () {
    test('should roundtrip through fromJson', () {
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        ultimoIdCliente: 123,
        isAdmin: false,
        emailVerifiedAt: '2023-01-01T00:00:00.000000Z',
      );

      final parsed = User.fromJson(user.toJson());

      expect(parsed.id, user.id);
      expect(parsed.name, user.name);
      expect(parsed.email, user.email);
      expect(parsed.ultimoIdCliente, user.ultimoIdCliente);
      expect(parsed.isAdmin, user.isAdmin);
      expect(parsed.emailVerifiedAt, user.emailVerifiedAt);
    });
  });
}
