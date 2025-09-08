import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:app_cemdo/models/user_model.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

class SecureStorageService {
  final _storage = FlutterSecureStorage();

  static const _tokenKey = 'token';
  static const _userKey = 'user';

  Future<void> storeLoginData(String token, User user) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<User?> getUser() async {
    final userJson = await _storage.read(key: _userKey);
    debugPrint('SecureStorageService - userJson: $userJson');
    if (userJson != null) {
      final decodedUser = jsonDecode(userJson);
      debugPrint('SecureStorageService - decodedUser: $decodedUser');
      return User.fromJson(decodedUser as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> deleteLoginData() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  Future<void> updateUser(User user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }
}
