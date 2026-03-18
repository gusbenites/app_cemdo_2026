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
    // We no longer mark all as read automatically on view.
    // We trigger a fetch to get the freshest list.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationService>(
        context,
        listen: false,
      ).getNotifications();
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
                            final String dateString = notification['sent_at'] ?? notification['created_at'] ?? '';
                            if (dateString.isNotEmpty) {
                              try {
                                final timestamp = DateTime.parse(dateString).toLocal();
                                formattedDate =
                                    '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
                              } catch (e) {
                                formattedDate = dateString;
                              }
                            }

                            final bool isRead = notification['is_read'] ?? true;
                            final int? notificationId = notification['id'];

                            return GestureDetector(
                              onTap: () {
                                if (!isRead && notificationId != null) {
                                  notificationService.markAsRead(notificationId);
                                }
                              },
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                elevation: isRead ? 1 : 3,
                                color: isRead ? Colors.white : Colors.blue[50],
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notification['title'] ?? 'Sin Título',
                                              style: TextStyle(
                                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          if (!isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.blue,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
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
