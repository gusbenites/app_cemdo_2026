import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_cemdo/data/services/notification_service.dart';
import 'package:app_cemdo/app.dart';
import 'package:app_cemdo/data/services/error_service.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Initialize Firebase for background messages
  debugPrint("Handling a background message: ${message.messageId}");

  if (message.notification != null) {
    NotificationService().saveNotification(
      message.notification!.title ?? 'No Title',
      message.notification!.body ?? 'No Body',
      message.data['tipo'] ?? 'general',
      message.data['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Get Flavor and Load Environment IMMEDIATELY
  // This is critical. If this fails, we want to know why.
  const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'development',
  );

  try {
    debugPrint("🚀 Iniciando App en modo: $flavor");
    await dotenv.load(fileName: ".env.$flavor");
    debugPrint("✅ Entorno cargado (.env.$flavor)");
  } catch (e) {
    debugPrint("❌ ERROR FATAL cargando entorno: $e");
    // If environment fails, we still try to run the app to show an error UI if possible,
    // but many things will likely fail.
  }

  // 2. Initialize Firebase (Essential for Messaging and Core)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
      debugPrint("✅ Firebase inicializado");
    }
  } catch (e) {
    debugPrint("⚠️ Advertencia Firebase: $e");
    // Firebase failure is not always fatal, but should be noted.
  }

  // 3. Initialize Error Service (Sentry)
  try {
    final String sentryDsn = dotenv.env['SENTRY_DSN'] ?? '';
    if (sentryDsn.isNotEmpty) {
      await ErrorService().init(dsn: sentryDsn, environment: flavor);
      debugPrint("✅ Sentry inicializado");
    } else {
      debugPrint("ℹ️ Sentry DSN no encontrado, omitiendo...");
    }
  } catch (e) {
    debugPrint("⚠️ Advertencia ErrorService: $e");
  }

  // 4. Global Error Handlers
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    ErrorService().reportError(
      details.exception,
      details.stack,
      'FlutterError.onError',
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorService().reportError(error, stack, 'PlatformDispatcher.onError');
    return true;
  };

  // 5. Start the App
  runApp(const MyApp());

  // 6. Initialize Non-Critical Services in background
  _initializeBackgroundServices();
}

Future<void> _initializeBackgroundServices() async {
  try {
    // SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notifications');

    // Only proceed with Firebase-related services if Firebase is initialized
    if (Firebase.apps.isNotEmpty) {
      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
    } else {
      debugPrint(
        'Firebase not initialized, skipping background message handler registration.',
      );
    }

    // Notification Service (Delayed to ensure UI is up)
    // The service itself now handles Firebase unavailability internaly
    await NotificationService().initialize();
  } catch (e, stack) {
    debugPrint("Background services error: $e");
    ErrorService().reportError(e, stack, 'Background initialization error');
  }
}
