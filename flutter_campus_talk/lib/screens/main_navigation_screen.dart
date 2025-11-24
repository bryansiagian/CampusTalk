// lib/screens/main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_services.dart';
import 'package:flutter_campus_talk/screens/auth/login_screen.dart';
import 'home/home_tab_screen.dart';
import 'post/post_list_screen.dart';
import 'profile/profile_screen.dart';
import 'package:flutter_campus_talk/screens/notification/notification_screen.dart'; // Import NotificationScreen
import 'dart:async'; // Untuk Timer
import 'package:badges/badges.dart' as badges; // Import badges

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final ApiServices _apiServices = ApiServices();
  int _unreadNotificationCount = 0;
  Timer? _notificationPollingTimer;

  final List<Widget> _widgetOptions = <Widget>[
    const HomeTabScreen(),
    const PostListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _startNotificationPolling();
  }

  @override
  void dispose() {
    _notificationPollingTimer?.cancel(); // Batalkan timer saat widget dibuang
    super.dispose();
  }

  void _startNotificationPolling() {
    // Ambil jumlah notifikasi saat init
    _fetchUnreadNotificationCount();
    // Atur timer untuk polling setiap 30 detik
    _notificationPollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchUnreadNotificationCount();
    });
  }

  Future<void> _fetchUnreadNotificationCount() async {
    try {
      final count = await _apiServices.getUnreadNotificationCount();
      if (mounted) { // Pastikan widget masih aktif sebelum memanggil setState
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      print('Error fetching unread notification count: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    // ... (kode logout seperti sebelumnya)
    try {
      await _apiServices.logout();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anda telah logout.'))
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout gagal: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusTalk', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          badges.Badge( // Menggunakan widget Badge
            showBadge: _unreadNotificationCount > 0,
            position: badges.BadgePosition.topEnd(top: 0, end: 3),
            badgeContent: Text(
              _unreadNotificationCount.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                ).then((_) {
                  // Saat kembali dari NotificationScreen, refresh count
                  _fetchUnreadNotificationCount();
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Postingan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey, // Tambahkan warna untuk item tidak terpilih
        onTap: _onItemTapped,
      ),
    );
  }
}