import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:app_cemdo/data/models/user_model.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

class SecureStorageService {
  final _storage = FlutterSecureStorage();

  static const _tokenKey = 'token';
  static const _userKey = 'user';

  Future<void> storeLoginData(String token, User user) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Error storing login data: $e');
      await deleteLoginData();
      rethrow;
    }
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('Error reading token: $e');
      await deleteLoginData();
      return null;
    }
  }

  Future<User?> getUser() async {
    try {
      final userJson = await _storage.read(key: _userKey);
      debugPrint('SecureStorageService - userJson: $userJson');
      if (userJson != null) {
        final decodedUser = jsonDecode(userJson);
        debugPrint('SecureStorageService - decodedUser: $decodedUser');
        return User.fromJson(decodedUser as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error reading user data: $e');
      await deleteLoginData();
      return null;
    }
  }

  Future<void> deleteLoginData() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
    } catch (e) {
      debugPrint('Error deleting login data: $e');
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Error updating user data: $e');
      // If we can't update, we probably shouldn't delete everything immediately,
      // but it might indicate a bigger issue. For now, just logging.
    }
  }
}
