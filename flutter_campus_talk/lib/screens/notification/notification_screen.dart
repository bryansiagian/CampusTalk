// lib/screens/notification/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../models/notification.dart'; // Import AppNotification
import '../../services/api_services.dart';
import '../post/post_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiServices _apiServices = ApiServices();
  late Future<List<AppNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  void _fetchNotifications() {
    setState(() {
      _notificationsFuture = _apiServices.getNotifications();
    });
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await _apiServices.markNotificationAsRead(notificationId);
      _fetchNotifications(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menandai notifikasi sebagai dibaca: ${e.toString()}'))
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _apiServices.markAllNotificationsAsRead();
      _fetchNotifications(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menandai semua notifikasi sebagai dibaca: ${e.toString()}'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('Baca Semua', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchNotifications(),
        child: FutureBuilder<List<AppNotification>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: SpinKitFadingCircle(color: Theme.of(context).primaryColor, size: 50.0));
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}. Tarik untuk refresh.'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Tidak ada notifikasi baru.'));
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final notification = snapshot.data![index];
                  return Card(
                    color: notification.isRead ? Colors.white : Colors.blue.shade50,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: InkWell(
                      onTap: () async {
                        if (!notification.isRead) {
                          await _markAsRead(notification.id);
                        }
                        if (notification.relatedPost != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PostDetailScreen(postId: notification.relatedPost!.id),
                            ),
                          ).then((_) => _fetchNotifications()); // Refresh saat kembali
                        } else {
                          // Jika notifikasi tidak terkait dengan postingan, mungkin tampilkan pesan
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(notification.message))
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.message,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.createdAt, // Anda bisa memformat ini lebih baik
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}