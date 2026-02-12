import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:app_cemdo/data/services/api_service.dart';

class VersionCheckResult {
  final String version;
  final bool forceUpdate;
  final String message;
  final String? storeUrl;

  VersionCheckResult({
    required this.version,
    required this.forceUpdate,
    required this.message,
    this.storeUrl,
  });

  factory VersionCheckResult.fromJson(Map<String, dynamic> json) {
    String? url;
    if (Platform.isAndroid) {
      url = json['store_url_android'];
    } else if (Platform.isIOS) {
      url = json['store_url_ios'];
    }

    return VersionCheckResult(
      version: json['version'] ?? '',
      forceUpdate: json['force_update'] ?? false,
      message: json['message'] ?? 'Nueva versión disponible.',
      storeUrl: url,
    );
  }
}

class VersionService {
  final ApiService _apiService = ApiService();

  Future<VersionCheckResult?> checkAppVersion() async {
    try {
      final response = await _apiService.get('app-version');
      if (response != null && response is Map<String, dynamic>) {
        return VersionCheckResult.fromJson(response);
      }
    } catch (e) {
      debugPrint('Error checking app version: $e');
    }
    return null;
  }

  Future<bool> isUpdateAvailable(String serverVersion) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      return _compareVersions(serverVersion, currentVersion) > 0;
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return false;
    }
  }

  int _compareVersions(String v1, String v2) {
    List<int> v1Parts = v1.split('.').map(int.parse).toList();
    List<int> v2Parts = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < v1Parts.length && i < v2Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) return 1;
      if (v1Parts[i] < v2Parts[i]) return -1;
    }
    return 0;
  }
}
