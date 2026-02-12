import 'package:mocktail/mocktail.dart';
import 'package:app_cemdo/data/services/api_service.dart';
import 'package:app_cemdo/data/services/secure_storage_service.dart';
import 'package:app_cemdo/data/services/notification_service.dart';
import 'package:app_cemdo/logic/providers/auth_provider.dart';
import 'package:app_cemdo/logic/providers/account_provider.dart';
import 'package:app_cemdo/data/models/user_model.dart';

class MockApiService extends Mock implements ApiService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockAuthProvider extends Mock implements AuthProvider {}

class MockAccountProvider extends Mock implements AccountProvider {}

class FakeUser extends Fake implements User {}
