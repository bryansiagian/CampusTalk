import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../models/notification.dart'; 
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

  String _fixImageUrl(String url) {
    if (url.startsWith('/')) return 'http://10.0.2.2:8000$url';
    if (url.contains('localhost')) return url.replaceAll('localhost', '10.0.2.2');
    if (url.contains('127.0.0.1')) return url.replaceAll('127.0.0.1', '10.0.2.2');
    return url;
  }

  String _timeAgo(DateTime d) {
    Duration diff = DateTime.now().difference(d);
    if (diff.inDays > 7) return "${d.day}/${d.month}";
    if (diff.inDays >= 1) return "${diff.inDays}hr";
    if (diff.inHours >= 1) return "${diff.inHours}j";
    if (diff.inMinutes >= 1) return "${diff.inMinutes}m";
    return "Now";
  }

  // Helper Ikon (Warna tetap statis karena ini branding interaksi)
  Widget _getNotificationIcon(String type, Color primaryColor) {
    switch (type) {
      case 'like_post':
      case 'like_comment':
        return const Icon(Icons.favorite, color: Colors.pink, size: 24);
      case 'comment_post':
        return Icon(Icons.chat_bubble, color: primaryColor, size: 24);
      case 'reply_comment':
        return const Icon(Icons.reply, color: Colors.green, size: 24);
      default:
        return const Icon(Icons.info, color: Colors.grey, size: 24);
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await _apiServices.markNotificationAsRead(notificationId);
      _fetchNotifications(); 
    } catch (e) {
      print("Gagal mark read: $e");
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _apiServices.markAllNotificationsAsRead();
      _fetchNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: ${e.toString()}'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- AMBIL TEMA ---
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final primaryColor = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Otomatis Hitam/Putih
      appBar: AppBar(
        title: Text('Notifikasi', style: TextStyle(color: theme.appBarTheme.foregroundColor, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0.5,
        iconTheme: theme.appBarTheme.iconTheme,
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text('Tandai baca', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchNotifications(),
        color: primaryColor,
        child: FutureBuilder<List<AppNotification>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: SpinKitFadingCircle(color: primaryColor, size: 40.0));
            } else if (snapshot.hasError) {
              return Center(child: Text('Gagal memuat notifikasi.', style: TextStyle(color: textSecondary)));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 64, color: textSecondary),
                    const SizedBox(height: 16),
                    Text('Belum ada notifikasi.', style: TextStyle(color: textSecondary, fontSize: 16)),
                  ],
                ),
              );
            } else {
              return ListView.separated(
                itemCount: snapshot.data!.length,
                separatorBuilder: (context, index) => Divider(height: 1, thickness: 0.5, color: theme.dividerColor),
                itemBuilder: (context, index) {
                  final notification = snapshot.data![index];
                  return _buildNotificationTile(notification, theme, isDark, textPrimary, textSecondary, primaryColor);
                },
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    AppNotification notification, 
    ThemeData theme, 
    bool isDark, 
    Color textPrimary, 
    Color textSecondary, 
    Color primaryColor
  ) {
    // Logic Warna Background:
    // Light Mode: Read = Putih, Unread = Biru Muda
    // Dark Mode: Read = Hitam/Surface, Unread = Abu Gelap (sedikit lebih terang dari bg)
    Color bgColor;
    if (notification.isRead) {
      bgColor = theme.scaffoldBackgroundColor;
    } else {
      bgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F8FA);
    }

    return InkWell(
      onTap: () async {
        if (!notification.isRead) {
          await _markAsRead(notification.id);
        }
        if (notification.relatedPost != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(postId: notification.relatedPost!.id),
            ),
          ).then((_) => _fetchNotifications());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konten ini mungkin sudah dihapus.")));
        }
      },
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IKON TIPE
            Padding(
              padding: const EdgeInsets.only(top: 4.0, right: 12.0),
              child: _getNotificationIcon(notification.type, primaryColor),
            ),

            // 2. KONTEN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (notification.sender != null)
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.canvasColor, // Neutral bg
                          backgroundImage: notification.sender!.profilePictureUrl != null
                              ? NetworkImage(_fixImageUrl(notification.sender!.profilePictureUrl!))
                              : null,
                          child: notification.sender!.profilePictureUrl == null
                              ? Text(notification.sender!.name[0].toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textPrimary))
                              : null,
                        ),
                      
                      const SizedBox(width: 8),
                      
                      const Spacer(),
                      // Parsing Tanggal dengan DateTime.parse
                      Text(
                        _timeAgo(DateTime.parse(notification.createdAt.toString())),
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 6),

                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 15,
                      color: textPrimary,
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600, 
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  if (notification.type.contains('comment') || notification.type.contains('reply'))
                    Text(
                      "Ketuk untuk membalas",
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}