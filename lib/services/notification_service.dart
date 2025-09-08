import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Added for HTTP requests
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Added for .env access
import 'package:flutter/foundation.dart'; // Added for debugPrint
import 'package:app_cemdo/services/secure_storage_service.dart'; // Added for authentication token
import 'package:flutter/material.dart'; // Added for ChangeNotifier
import 'package:url_launcher/url_launcher.dart'; // Added for opening app settings
import 'package:device_info_plus/device_info_plus.dart'; // Added for device info
import 'dart:io'; // Added for Platform

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
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
    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
      'User granted permission: ${settings.authorizationStatus == AuthorizationStatus.authorized}',
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _notificationsEnabled = true;
      debugPrint('Notifications are authorized.');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      _notificationsEnabled = false;
      debugPrint(
        'Notifications are denied. Please enable them in app settings.',
      );
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.notDetermined) {
      _notificationsEnabled = false;
      debugPrint('Notifications permission not determined.');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      _notificationsEnabled = true;
      debugPrint('Notifications are provisionally authorized.');
    }

    // Get the FCM token
    String? token = await _firebaseMessaging.getToken();
    debugPrint('******** FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification!.title} - ${message.notification!.body}',
        );
        saveNotification(
          message.notification!.title ?? 'No Title',
          message.notification!.body ?? 'No Body',
          message.data['tipo'] ?? 'general',
          message.data['timestamp'] ?? DateTime.now().toIso8601String(),
        );
      }
    });

    // Handle messages when the app is in the background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      debugPrint('Message data: ${message.data}');
      if (message.notification != null) {
        saveNotification(
          message.notification!.title ?? 'No Title',
          message.notification!.body ?? 'No Body',
          message.data['tipo'] ?? 'general',
          message.data['timestamp'] ?? DateTime.now().toIso8601String(),
        );
      }
      // You can navigate to a specific screen here based on the message data
    });
    _updateUnreadCount(); // Initial load of unread count
    notifyListeners(); // Notify listeners about the initial state
  }

  Future<void> toggleNotifications(bool enable) async {
    if (enable) {
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
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
        await _firebaseMessaging.subscribeToTopic('general_notifications');
        debugPrint('Notifications enabled and subscribed to topic.');
      } else {
        _notificationsEnabled = false;
        debugPrint('Notifications permission not granted by user.');
      }
    } else {
      _notificationsEnabled = false;
      // Unsubscribe from all topics or disable auto-init
      await _firebaseMessaging.unsubscribeFromTopic('general_notifications');
      debugPrint('Notifications disabled and unsubscribed from topic.');
    }
    notifyListeners(); // Notify listeners about the change
  }

  Future<void> openAppSettings() async {
    if (await canLaunchUrl(Uri.parse('app-settings:'))) {
      await launchUrl(Uri.parse('app-settings:'));
    } else {
      debugPrint('Could not open app settings.');
      // Fallback for iOS if 'app-settings:' scheme doesn't work
      // For Android, it usually works. For iOS, it might need specific URL schemes.
      // Consider showing a dialog to manually guide the user.
    }
  }

  Future<void> sendFcmTokenToBackend(String userId) async {
    String? fcmToken = await _firebaseMessaging.getToken();

    final String backendUrl = '${dotenv.env['BACKEND_URL']!}/fcm-token';
    final secureStorageService = SecureStorageService();
    final authToken = await secureStorageService.getToken();
    final deviceInfo = await _getDeviceInfo(); // Get device info map
    final deviceName = deviceInfo['name'];
    final deviceId = deviceInfo['id']; // Get device ID

    if (authToken == null) {
      debugPrint('Auth token is null, cannot send FCM token to backend.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $authToken',
        },
        body: {
          'fcm_token': fcmToken,
          'device_name': deviceName ?? 'Unknown Device',
          'device_id': deviceId ?? 'Unknown ID', // Include device ID
        },
      );

      if (response.statusCode == 200) {
        debugPrint('FCM Token sent to backend successfully.');
      } else {
        debugPrint(
          'Failed to send FCM Token to backend. Status code: ${response.statusCode}',
        );
        debugPrint('Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending FCM Token to backend: $e');
    }
  }

  Future<void> saveNotification(
    String title,
    String body,
    String tipo,
    String timestamp,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList('notifications') ?? [];
    final notification = {
      'title': title,
      'body': body,
      'tipo': tipo,
      'timestamp': timestamp,
      'read': false, // Mark as unread when saving
    };
    notifications.add(jsonEncode(notification));
    await prefs.setStringList('notifications', notifications);
    _notificationsList = (await _loadNotificationsFromPrefs()).reversed
        .toList();
    _unreadCount++; // Increment unread count
    notifyListeners(); // Notify listeners that the notification list has changed
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    _notificationsList = (await _loadNotificationsFromPrefs()).reversed
        .toList();
    notifyListeners();
    return _notificationsList;
  }

  Future<List<Map<String, dynamic>>> _loadNotificationsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationStrings = prefs.getStringList('notifications') ?? [];
    List<Map<String, dynamic>> parsedNotifications = [];
    for (String notificationString in notificationStrings) {
      try {
        parsedNotifications.add(
          jsonDecode(notificationString) as Map<String, dynamic>,
        );
      } catch (e) {
        debugPrint(
          'Error decoding notification string: $e - $notificationString',
        );
      }
    }
    return parsedNotifications;
  }

  Future<void> markNotificationsAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList('notifications') ?? [];
    List<String> updatedNotifications = [];
    for (String notificationString in notifications) {
      try {
        Map<String, dynamic> notification =
            jsonDecode(notificationString) as Map<String, dynamic>;
        notification['read'] = true; // Mark as read
        updatedNotifications.add(jsonEncode(notification));
      } catch (e) {
        debugPrint(
          'Error decoding notification string for marking as read: $e - $notificationString',
        );
        updatedNotifications.add(
          notificationString,
        ); // Add original if decoding fails
      }
    }
    await prefs.setStringList('notifications', updatedNotifications);
    _notificationsList = (await _loadNotificationsFromPrefs()).reversed
        .toList();
    _unreadCount = 0; // Reset unread count
    notifyListeners(); // Notify listeners that the notification list has changed
  }

  Future<void> _updateUnreadCount() async {
    _notificationsList = (await _loadNotificationsFromPrefs()).reversed
        .toList();
    _unreadCount = _notificationsList.where((n) => n['read'] == false).length;
    notifyListeners();
  }

  Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('notifications', []);
    _notificationsList = [];
    _unreadCount = 0;
    notifyListeners();
  }
}
