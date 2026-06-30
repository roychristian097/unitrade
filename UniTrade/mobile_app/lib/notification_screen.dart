import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'theme.dart';
import 'auth_service.dart';

class NotificationItem {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'No Title',
      message: json['message'] ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<NotificationItem>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = fetchNotifications();
  }

  Future<List<NotificationItem>> fetchNotifications() async {
    try {
      final token = AuthService.token;
      if (token == null) return [];

      final baseUrlUri = Uri.parse(AuthService.baseUrl);
      final uri = Uri(
        scheme: baseUrlUri.scheme,
        host: baseUrlUri.host,
        port: baseUrlUri.port,
        path: '/notifications',
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((n) => NotificationItem.fromJson(n)).toList();
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      return [];
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      final token = AuthService.token;
      if (token == null) return;

      final baseUrlUri = Uri.parse(AuthService.baseUrl);
      final uri = Uri(
        scheme: baseUrlUri.scheme,
        host: baseUrlUri.host,
        port: baseUrlUri.port,
        path: '/notifications/$id/read',
      );

      await http.post(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      
      setState(() {
        _notificationsFuture = fetchNotifications();
      });
    } catch (e) {
      // Ignore errors silently for now
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays > 0) {
        return '${diff.inDays} hari yang lalu';
      } else if (diff.inHours > 0) {
        return '${diff.inHours} jam yang lalu';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes} menit yang lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<NotificationItem>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: context.colors.primary));
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[700]),
                    const SizedBox(height: 16),
                    Text(
                      "Belum ada notifikasi.",
                      style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Notifikasi pesan, pesanan, dan pembaruan akan muncul di sini.",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => Divider(color: context.colors.textPrimary.withValues(alpha: 0.05)),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return InkWell(
                onTap: () {
                  if (!notif.isRead) {
                    _markAsRead(notif.id);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: notif.isRead ? Colors.transparent : context.colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications, color: context.colors.primary, size: 20),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notif.title,
                                    style: TextStyle(
                                      color: context.colors.textPrimary,
                                      fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (!notif.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: context.colors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              notif.message,
                              style: TextStyle(
                                color: notif.isRead ? Colors.grey[500] : context.colors.textPrimary.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _formatDate(notif.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
