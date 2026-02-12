import 'package:flutter/material.dart';
import 'package:app_cemdo/data/services/notification_service.dart';
import 'package:provider/provider.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  @override
  void initState() {
    super.initState();
    // Mark notifications as read when the screen is viewed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationService>(
        context,
        listen: false,
      ).markNotificationsAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avisos'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          final notifications = notificationService.notifications;
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => notificationService.getNotifications(),
                  child: notifications.isEmpty
                      ? const Center(child: Text('No hay avisos para mostrar.'))
                      : ListView.builder(
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            String formattedDate = '';
                            if (notification['timestamp'] != null) {
                              try {
                                final timestamp = DateTime.parse(
                                  notification['timestamp'],
                                );
                                formattedDate =
                                    '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
                              } catch (e) {
                                formattedDate = notification['timestamp'];
                              }
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification['title'] ?? 'Sin Título',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notification['body'] ?? 'Sin Contenido',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          formattedDate,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Provider.of<NotificationService>(
          context,
          listen: false,
        ).clearNotifications(),
        tooltip: 'Borrar todos los avisos',
        child: const Icon(Icons.delete_forever),
      ),
    );
  }
}
