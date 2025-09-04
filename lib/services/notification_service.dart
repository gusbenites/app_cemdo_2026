import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Added for HTTP requests
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Added for .env access
import 'package:flutter/foundation.dart'; // Added for debugPrint
import 'package:app_cemdo/services/secure_storage_service.dart'; // Added for authentication token
import 'package:flutter/material.dart'; // Added for ChangeNotifier

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  int _unreadCount = 0; // Added

  int get unreadCount => _unreadCount; // Added

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
  }

  Future<void> sendFcmTokenToBackend(String userId) async {
    String? token = await _firebaseMessaging.getToken();
    if (token == null) {
      debugPrint('FCM Token is null, cannot send to backend.');
      return;
    }

    final String backendUrl = '${dotenv.env['BACKEND_URL']!}/fcm-token';
    final secureStorageService = SecureStorageService();
    final authToken = await secureStorageService.getToken();

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
        body: {'token': token},
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
    _unreadCount++; // Increment unread count
    notifyListeners(); // Notify listeners that the notification list has changed
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
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
    _unreadCount = 0; // Reset unread count
    notifyListeners(); // Notify listeners that the notification list has changed
  }

  Future<void> _updateUnreadCount() async {
    final notifications = await getNotifications();
    _unreadCount = notifications.where((n) => n['read'] == false).length;
    notifyListeners();
  }
}
