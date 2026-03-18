import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http; // Added for HTTP requests
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Added for .env access
import 'package:flutter/foundation.dart'; // Added for debugPrint
import 'package:app_cemdo/data/services/secure_storage_service.dart'; // Added for authentication token
import 'package:flutter/material.dart'; // Added for ChangeNotifier
import 'package:url_launcher/url_launcher.dart'; // Added for opening app settings
import 'package:device_info_plus/device_info_plus.dart'; // Added for device info
import 'package:package_info_plus/package_info_plus.dart'; // Added for app version
import 'dart:io'; // Added for Platform
import 'package:provider/provider.dart';
import 'package:app_cemdo/logic/providers/auth_provider.dart';
import 'package:app_cemdo/ui/utils/global_navigator_key.dart';
import 'package:app_cemdo/data/services/api_service.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  FirebaseMessaging? _messaging;
  FirebaseMessaging? get _firebaseMessaging {
    try {
      if (Firebase.apps.isNotEmpty) {
        _messaging ??= FirebaseMessaging.instance;
      }
    } catch (e) {
      debugPrint('Error accessing FirebaseMessaging: $e');
    }
    return _messaging;
  }

  int _unreadCount = 0;
  List<Map<String, dynamic>> _notificationsList = [];
  bool _notificationsEnabled = false; // New: Track notification status

  int get unreadCount => _unreadCount;
  List<Map<String, dynamic>> get notifications => _notificationsList;
  bool get notificationsEnabled =>
      _notificationsEnabled; // New: Getter for status

  Future<Map<String, String?>> _getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    String? deviceName;
    String? deviceId; // Using deviceId for unique identifier

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      deviceName = androidInfo.model; // e.g. "SM-G981B"
      // On Android 10 (API 29) and above, serial number is restricted.
      // androidId is a common alternative for unique device identification.
      deviceId = androidInfo.id; // Android ID
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      deviceName = iosInfo.name; // e.g. "iPhone 11 Pro"
      deviceId = iosInfo.identifierForVendor; // iOS unique identifier
    } else if (Platform.isLinux) {
      LinuxDeviceInfo linuxInfo = await deviceInfoPlugin.linuxInfo;
      deviceName = linuxInfo.prettyName; // e.g. "Ubuntu 20.04 LTS"
      deviceId = linuxInfo.machineId; // Linux machine ID
    } else if (Platform.isMacOS) {
      MacOsDeviceInfo macOsInfo = await deviceInfoPlugin.macOsInfo;
      deviceName = macOsInfo.model; // e.g. "MacBookPro16,1"
      deviceId = macOsInfo.systemGUID; // macOS system GUID
    } else if (Platform.isWindows) {
      WindowsDeviceInfo windowsInfo = await deviceInfoPlugin.windowsInfo;
      deviceName = windowsInfo.computerName; // e.g. "MyComputer"
      deviceId = windowsInfo.deviceId; // Windows device ID
    }
    return {'name': deviceName, 'id': deviceId};
  }

  Future<void> initialize() async {
    final messaging = _firebaseMessaging;
    if (messaging == null) {
      debugPrint('NotificationService: Firebase messaging not available.');
      return;
    }

    // Request permission for notifications - MOVED to toggleNotifications for Guideline 4.5.4
    /*
    try {
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
        'Notification Authorization Status: ${settings.authorizationStatus}',
      );
      _updatePermissionStatus(settings.authorizationStatus);

      // Get the FCM token
      try {
        String? token = await messaging.getToken();
        debugPrint('******** FCM Token (at Init): $token');
      } catch (e) {
        debugPrint('Error getting FCM token at initialization: $e');
      }
    } catch (e) {
      debugPrint('Error during notification permission request: $e');
    }
    */

    // Listen to token refresh
    messaging.onTokenRefresh.listen((newToken) {
      debugPrint('******** FCM Token Refresh: $newToken');
      // If user is already logged in, update backend
      final authProvider = Provider.of<AuthProvider>(
        GlobalNavigatorKey.navigatorKey.currentContext!,
        listen: false,
      );
      if (authProvider.user != null) {
        sendFcmTokenToBackend(authProvider.user!.id.toString());
      }
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '******** Foreground Notification Received: ${message.messageId}',
      );
      _updateUnreadCount();
      getNotifications();
    });

    // Handle messages when the app is in the background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('******** Notification Opened App: ${message.messageId}');
      _updateUnreadCount();
      getNotifications();
    });

    _updateUnreadCount(); // Initial load of unread count
    await checkPermissionStatus(); // Ensure initial status is set
    notifyListeners(); // Notify listeners about the initial state
  }

  void _updatePermissionStatus(AuthorizationStatus status) {
    if (status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional) {
      _notificationsEnabled = true;
      debugPrint('Notifications authorized.');
    } else {
      _notificationsEnabled = false;
      debugPrint('Notifications not authorized: $status');
    }
    notifyListeners();
  }

  Future<void> checkPermissionStatus() async {
    final messaging = _firebaseMessaging;
    if (messaging == null) return;

    try {
      NotificationSettings settings = await messaging.getNotificationSettings();
      _updatePermissionStatus(settings.authorizationStatus);
    } catch (e) {
      debugPrint('Error checking notification settings: $e');
    }
  }

  Future<void> toggleNotifications(bool enable) async {
    final messaging = _firebaseMessaging;
    if (messaging == null) return;

    if (enable) {
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        _notificationsEnabled = true;
        // Subscribe to a general topic if you have one, or ensure auto-init is enabled
        await messaging.subscribeToTopic('general_notifications');
        debugPrint('Notifications enabled and subscribed to topic.');
      } else {
        _notificationsEnabled = false;
        debugPrint('Notifications permission not granted by user.');
      }
    } else {
      _notificationsEnabled = false;
      // Unsubscribe from all topics or disable auto-init
      await messaging.unsubscribeFromTopic('general_notifications');
      debugPrint('Notifications disabled and unsubscribed from topic.');
    }
    notifyListeners(); // Notify listeners about the change
  }

  Future<void> openAppSettings() async {
    if (Platform.isAndroid) {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        final packageName = packageInfo.packageName;
        // The standard way for Android with url_launcher (if handled by system)
        // or just guiding the user.
        debugPrint('Opening settings for package: $packageName');
      } catch (e) {
        debugPrint('Error getting package name: $e');
      }

      // try app-settings: which some plugins/systems might handle
      if (await canLaunchUrl(Uri.parse('app-settings:'))) {
        await launchUrl(Uri.parse('app-settings:'));
      } else {
        debugPrint('Could not open app settings via app-settings:');
      }
    } else {
      if (await canLaunchUrl(Uri.parse('app-settings:'))) {
        await launchUrl(Uri.parse('app-settings:'));
      } else {
        debugPrint('Could not open app settings.');
      }
    }
  }

  Future<void> sendFcmTokenToBackend(String userId) async {
    final messaging = _firebaseMessaging;
    if (messaging == null) {
      debugPrint(
        'NotificationService: Skipping token update, messaging unavailable.',
      );
      return;
    }

    String? fcmToken;
    try {
      fcmToken = await messaging.getToken();
      debugPrint('******** Sending FCM Token to backend: $fcmToken');
    } catch (e) {
      debugPrint('Error getting FCM token for backend submission: $e');
      return;
    }

    if (fcmToken == null) {
      debugPrint('FCM Token is null, cannot update backend.');
      return;
    }

    final backendUrlEnv = dotenv.env['BACKEND_URL'];
    if (backendUrlEnv == null) {
      debugPrint(
        'NotificationService: BACKEND_URL not configured, skipping token update.',
      );
      return;
    }
    final String backendUrl = '$backendUrlEnv/fcm-token';
    final secureStorageService = SecureStorageService();
    final authToken = await secureStorageService.getToken();
    final deviceInfo = await _getDeviceInfo();
    final deviceName = deviceInfo['name'];
    final deviceId = deviceInfo['id'];

    if (authToken == null) {
      debugPrint('Auth token is null, cannot send FCM token to backend.');
      return;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = packageInfo.version;

    try {
      debugPrint('Posting FCM token to: $backendUrl');
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $authToken',
        },
        body: {
          'fcm_token': fcmToken,
          'device_name': deviceName ?? 'Unknown Device',
          'device_id': deviceId ?? 'Unknown ID',
          'app_version': appVersion,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('******** FCM Token sent correctly to backend.');
      } else {
        debugPrint(
          '******** FAILED to send FCM Token to backend. Status: ${response.statusCode}',
        );
        debugPrint('Response Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error during HTTP post of FCM token: $e');
    }
  }

  // We keep this signature but it's no longer saving to prefs.
  // We rely on API for state. If needed, you could fallback to API call or local cache.
  Future<void> saveNotification(
    String title,
    String body,
    String tipo,
    String timestamp,
  ) async {
    // Deprecated for local, we just update from API
    await _updateUnreadCount();
    await getNotifications();
  }

  Future<List<Map<String, dynamic>>> getNotifications({int page = 1}) async {
    try {
      final secureStorageService = SecureStorageService();
      final authToken = await secureStorageService.getToken();
      if (authToken == null) return _notificationsList;

      final apiService = ApiService();
      final response = await apiService.get('api/v2/notifications?page=$page', token: authToken);
      if (response != null && response['success'] == true && response['data'] != null) {
        final List<dynamic> rawData = response['data']['data'] ?? [];
        if (page == 1) {
          _notificationsList = rawData.cast<Map<String, dynamic>>();
        } else {
          _notificationsList.addAll(rawData.cast<Map<String, dynamic>>());
        }
        await _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
    return _notificationsList;
  }

  Future<void> markAsRead(int id) async {
    try {
      final secureStorageService = SecureStorageService();
      final authToken = await secureStorageService.getToken();
      if (authToken == null) return;

      final apiService = ApiService();
      await apiService.post('api/v2/notifications/$id/read', token: authToken);
      
      // Update local state temporarily so UI reflects instantly
      final index = _notificationsList.indexWhere((n) => n['id'] == id);
      if (index != -1 && !(_notificationsList[index]['is_read'] ?? true)) {
        _notificationsList[index]['is_read'] = true;
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _updateUnreadCount() async {
    try {
      final secureStorageService = SecureStorageService();
      final authToken = await secureStorageService.getToken();
      if (authToken == null) return;

      final apiService = ApiService();
      final response = await apiService.get('api/v2/notifications/unread-count', token: authToken);
      if (response != null && response['success'] == true) {
        // the payload might come directly in 'data'
        _unreadCount = response['data'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  Future<void> clearNotifications() async {
    // If the API supports clearing, call it here. Otherwise just clear local view.
    // Assuming backend handles deletion or we just clear caching.
    _notificationsList = [];
    _unreadCount = 0;
    notifyListeners();
  }
}
