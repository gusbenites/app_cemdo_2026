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
    // Basic cleanup: remove everything from '-' onwards (suffixes like -dev, -alpha)
    String cleanV1 = v1.split('-').first;
    String cleanV2 = v2.split('-').first;

    List<int> v1Parts = cleanV1
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    List<int> v2Parts = cleanV2
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    int length = v1Parts.length > v2Parts.length
        ? v1Parts.length
        : v2Parts.length;

    for (int i = 0; i < length; i++) {
      int p1 = i < v1Parts.length ? v1Parts[i] : 0;
      int p2 = i < v2Parts.length ? v2Parts[i] : 0;

      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }
}
