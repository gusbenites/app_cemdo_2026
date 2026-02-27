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

  // 1. Get Flavor
  const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'development',
  );

  // 2. Parallelize critical initializations
  debugPrint("🚀 Iniciando App en modo: $flavor");

  final initializationFuture = Future.wait([
    dotenv
        .load(fileName: ".env.$flavor")
        .then((_) {
          debugPrint("✅ Entorno cargado (.env.$flavor)");
          // Initialize Sentry ASAP once dotenv is ready
          final String sentryDsn = dotenv.env['SENTRY_DSN'] ?? '';
          if (sentryDsn.isNotEmpty) {
            return ErrorService()
                .init(dsn: sentryDsn, environment: flavor)
                .then((_) {
                  debugPrint("✅ Sentry inicializado");
                });
          }
          return Future.value();
        })
        .catchError((e) {
          debugPrint("❌ ERROR cargando entorno: $e");
        }),

    Firebase.initializeApp()
        .then((_) {
          debugPrint("✅ Firebase inicializado");
        })
        .catchError((e) {
          debugPrint("⚠️ Advertencia Firebase: $e");
        }),
  ]);

  // Wait for critical services but don't let one failure block the whole app if possible
  await initializationFuture;

  // 3. Global Error Handlers
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

  // 4. Start the App ASAP
  runApp(const MyApp());

  // 5. Initialize Non-Critical Services in background
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
