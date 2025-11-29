import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:badges/badges.dart' as badges;

import '../../services/api_services.dart';
import 'home/home_tab_screen.dart';
import 'post/create_post_screen.dart';
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

  // --- DESIGN COLORS ---
  final Color _primaryBlue = const Color(0xFF4A90E2);
  final Color _textSecondary = const Color(0xFF657786);

  // Widget untuk setiap Tab
  final List<Widget> _widgetOptions = <Widget>[
    const HomeTabScreen(),      // 0: Forum
    const CreatePostScreen(),   // 1: Post (Sebaiknya CreatePost ini tampil sebagai Modal, tapi kita ikuti struktur tab dulu)
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
    // Poll setiap 30 detik
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
    // Ambil Tema untuk Dark Mode Support
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Warna Background Nav Bar (Putih di Light, Hitam Abu di Dark)
    final navBarColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    // Warna Border Atas
    final borderColor = theme.dividerColor;

    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Container(
        // GARIS PEMISAH TIPIS DI ATAS (Khas Twitter/IG)
        decoration: BoxDecoration(
          color: navBarColor,
          border: Border(top: BorderSide(color: borderColor, width: 0.5)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: navBarColor,
          elevation: 0, // Flat Design
          currentIndex: _selectedIndex,
          
          // Warna Item
          selectedItemColor: _primaryBlue,
          unselectedItemColor: isDark ? Colors.grey : _textSecondary,
          
          // Style Text
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          
          onTap: _onItemTapped,
          
          items: <BottomNavigationBarItem>[
            // 1. HOME / FORUM
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), // Icon Home lebih umum daripada Chat Bubble untuk feed utama
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            
            // 2. CREATE POST
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              activeIcon: Icon(Icons.add_box),
              label: 'Posting',
            ),
            
            // 3. NOTIFIKASI (Dengan Badge)
            BottomNavigationBarItem(
              icon: badges.Badge(
                showBadge: _unreadNotificationCount > 0,
                position: badges.BadgePosition.topEnd(top: -5, end: -2),
                badgeStyle: const badges.BadgeStyle(
                  badgeColor: Colors.red, // Warna badge merah mencolok
                  padding: EdgeInsets.all(4),
                ),
                badgeContent: Text(
                  _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                child: const Icon(Icons.notifications_outlined),
              ),
              activeIcon: badges.Badge(
                showBadge: _unreadNotificationCount > 0,
                position: badges.BadgePosition.topEnd(top: -5, end: -2),
                badgeStyle: const badges.BadgeStyle(
                  badgeColor: Colors.red,
                  padding: EdgeInsets.all(4),
                ),
                badgeContent: Text(
                  _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                child: const Icon(Icons.notifications),
              ),
              label: 'Notifikasi',
            ),
            
            // 4. PROFIL
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