// lib/screens/notification/notification_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../models/notification.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
    _notificationsFuture = _apiServices.getNotifications();
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _notificationsFuture = _apiServices.getNotifications();
    });
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      bool success = await _apiServices.markNotificationAsRead(notificationId);
      if (success) {
        _refreshNotifications(); // Refresh daftar setelah menandai dibaca
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menandai notifikasi sudah dibaca.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext
      context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi Saya', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
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
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    color: notification.isRead ? Colors.grey.shade100 : Colors.blue.shade50,
                    child: ListTile(
                      leading: Icon(
                        notification.type == 'comment_on_post' ? Icons.comment : Icons.thumb_up,
                        color: notification.isRead ? Colors.grey : Theme.of(context).primaryColor,
                      ),
                      title: Text(
                        notification.message,
                        style: TextStyle(
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${DateTime.parse(notification.createdAt).day}/${DateTime.parse(notification.createdAt).month}/${DateTime.parse(notification.createdAt).year} - '
                        '${DateTime.parse(notification.createdAt).hour}:${DateTime.parse(notification.createdAt).minute}',
                        style: TextStyle(color: Colors.grey),
                      ),
                      trailing: notification.isRead
                          ? null // Tidak ada ikon jika sudah dibaca
                          : Icon(Icons.mark_email_unread, color: Colors.blueGrey),
                      onTap: () {
                        if (!notification.isRead) {
                          _markAsRead(notification.id);
                        }
                        // TODO: Arahkan ke detail postingan/komentar yang relevan
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Notifikasi #${notification.id} diklik! (Redirect belum diimplementasi)')));
                      },
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