import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_cemdo/data/services/notification_service.dart';
import 'package:app_cemdo/app.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Initialize Firebase for background messages
  debugPrint("Handling a background message: \${message.messageId}");
  NotificationService().saveNotification(
    message.notification?.title ?? 'No Title',
    message.notification?.body ?? 'No Body',
    message.data['tipo'] ?? 'general',
    message.data['timestamp'] ?? DateTime.now().toIso8601String(),
  );
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(); // Initialize Firebase
    // Define the flavor, defaulting to 'development'
    const String flavor = String.fromEnvironment(
      'FLAVOR',
      defaultValue: 'development',
    );
    await dotenv.load(
      fileName: ".env.$flavor",
    ); // Load the appropriate .env file

    // Temporarily clear old notifications for debugging
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notifications'); // Clear the key

    // Initialize Notification Service
    await NotificationService().initialize();

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    runApp(const MyApp());
  } catch (e, stack) {
    debugPrint("🔥 ERROR CRITICO EN MAIN: $e");
    debugPrint(stack.toString());
  }
}
