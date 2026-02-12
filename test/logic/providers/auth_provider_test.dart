import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_cemdo/logic/providers/auth_provider.dart';
import 'package:app_cemdo/data/services/api_service.dart';
import 'package:app_cemdo/data/models/user_model.dart';

import '../../mocks/mocks.dart';

void main() {
  late AuthProvider authProvider;
  late MockApiService mockApiService;
  late MockSecureStorageService mockSecureStorageService;

  setUp(() {
    mockApiService = MockApiService();
    mockSecureStorageService = MockSecureStorageService();
    authProvider = AuthProvider(
      apiService: mockApiService,
      secureStorageService: mockSecureStorageService,
    );
    // Register fallbacks if needed
    registerFallbackValue(FakeUser());
  });

  group('AuthProvider', () {
    const email = 'test@example.com';
    const password = 'password';
    const token = 'fake_token';
    final user = User(
      id: 1,
      name: 'Test User',
      email: email,
      emailVerifiedAt: '2023-01-01T00:00:00.000000Z',
      isAdmin: false,
      ultimoIdCliente: 123,
    );

    test('login success sets user and token', () async {
      // Arrange
      final responseData = {'token': token, 'user': user.toJson()};
      when(
        () => mockApiService.post(any(), body: any(named: 'body')),
      ).thenAnswer((_) async => responseData);
      when(
        () => mockSecureStorageService.storeLoginData(any(), any()),
      ).thenAnswer((_) async => {});

      // Act
      await authProvider.login(email, password);

      // Assert
      expect(authProvider.token, token);
      expect(authProvider.user?.email, email);
      verify(
        () => mockSecureStorageService.storeLoginData(token, any()),
      ).called(1);
    });

    test('login failure throws exception', () async {
      // Arrange
      final exception = ApiException(
        message: 'Invalid credentials',
        statusCode: 401,
      );
      when(
        () => mockApiService.post(any(), body: any(named: 'body')),
      ).thenThrow(exception);

      // Act & Assert
      expect(
        () => authProvider.login(email, password),
        throwsA(isA<ApiException>()),
      );
      expect(authProvider.token, null);
    });

    test('checkLoginStatus restores session if valid', () async {
      // Arrange
      when(
        () => mockSecureStorageService.getToken(),
      ).thenAnswer((_) async => token);
      when(
        () => mockSecureStorageService.getUser(),
      ).thenAnswer((_) async => user);

      // Act
      await authProvider.checkLoginStatus();

      // Assert
      expect(authProvider.token, token);
      expect(authProvider.user?.email, email);
    });

    test('logout clears session', () async {
      // Arrange
      when(
        () => mockSecureStorageService.deleteLoginData(),
      ).thenAnswer((_) async => {});

      // Act
      await authProvider.logout();

      // Assert
      expect(authProvider.token, null);
      expect(authProvider.user, null);
      verify(() => mockSecureStorageService.deleteLoginData()).called(1);
    });
  });
}
