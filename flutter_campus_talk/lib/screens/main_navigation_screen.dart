import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:badges/badges.dart' as badges;

import '../../services/api_services.dart';
import 'package:flutter_campus_talk/screens/auth/login_screen.dart';
import 'home/home_tab_screen.dart';
import 'post/create_post_screen.dart'; // Menu ke-2 adalah Buat Postingan
import 'profile/profile_screen.dart';
import 'package:flutter_campus_talk/screens/notification/notification_screen.dart';

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

  // Widget untuk setiap Tab
  final List<Widget> _widgetOptions = <Widget>[
    const HomeTabScreen(),      // 0: Forum
    const CreatePostScreen(),   // 1: Post (Form Buat Postingan)
    const NotificationScreen(), // 2: Notifikasi
    const ProfileScreen(),      // 3: Profil
  ];

  @override
  void initState() {
    super.initState();
    _startNotificationPolling();
  }

  @override
  void dispose() {
    _notificationPollingTimer?.cancel();
    super.dispose();
  }

  void _startNotificationPolling() {
    _fetchUnreadNotificationCount();
    _notificationPollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchUnreadNotificationCount();
    });
  }

  Future<void> _fetchUnreadNotificationCount() async {
    try {
      final count = await _apiServices.getUnreadNotificationCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      print('Error fetching notification: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Reset badge jika masuk tab notifikasi
    if (index == 2) {
      _fetchUnreadNotificationCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar dihapus agar tidak double dengan AppBar di Home/Profile
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1.0)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          onTap: _onItemTapped,
          items: <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Forum',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              activeIcon: Icon(Icons.add_box),
              label: 'Post',
            ),
            BottomNavigationBarItem(
              icon: badges.Badge(
                showBadge: _unreadNotificationCount > 0,
                position: badges.BadgePosition.topEnd(top: -5, end: -2),
                badgeContent: Text(
                  _unreadNotificationCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                child: const Icon(Icons.notifications_outlined),
              ),
              activeIcon: badges.Badge(
                showBadge: _unreadNotificationCount > 0,
                position: badges.BadgePosition.topEnd(top: -5, end: -2),
                badgeContent: Text(
                  _unreadNotificationCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                child: const Icon(Icons.notifications),
              ),
              label: 'Notifikasi',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}