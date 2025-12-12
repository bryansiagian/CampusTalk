import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Import ini penting untuk ScrollDirection
import 'dart:async';
import 'package:badges/badges.dart' as badges;

import '../../services/api_services.dart';
import 'home/home_tab_screen.dart';
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
  
  // STATE BARU: Untuk mengontrol visibilitas Bottom Bar
  bool _isBottomBarVisible = true;

  final Color _primaryBlue = const Color(0xFF4A90E2);
  final Color _textSecondary = const Color(0xFF657786);

  final List<Widget> _widgetOptions = <Widget>[
    const HomeTabScreen(),
    const NotificationScreen(),
    const ProfileScreen(),
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
      if (mounted) setState(() => _unreadNotificationCount = count);
    } catch (e) {
      print('Error fetching notification: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) _fetchUnreadNotificationCount();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navBarColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = theme.dividerColor;

    return Scaffold(
      // WRAP BODY DENGAN NOTIFICATION LISTENER
      // Ini bertugas "mendengar" apakah user sedang scroll ke atas atau bawah
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          // Jika scroll ke BAWAH (Reverse) -> Sembunyikan
          if (notification.direction == ScrollDirection.reverse && _isBottomBarVisible) {
            setState(() => _isBottomBarVisible = false);
          } 
          // Jika scroll ke ATAS (Forward) -> Munculkan
          else if (notification.direction == ScrollDirection.forward && !_isBottomBarVisible) {
            setState(() => _isBottomBarVisible = true);
          }
          return true;
        },
        child: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
      ),
      
      // ANIMATED CONTAINER UNTUK EFEK SLIDING
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200), // Kecepatan animasi
        height: _isBottomBarVisible ? kBottomNavigationBarHeight + 16 : 0.0, // +16 untuk padding/border
        child: Wrap( // Wrap digunakan agar child tidak error overflow saat height jadi 0
          children: [
            Container(
              decoration: BoxDecoration(
                color: navBarColor,
                border: Border(top: BorderSide(color: borderColor, width: 0.5)),
              ),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: navBarColor,
                elevation: 0,
                currentIndex: _selectedIndex,
                selectedItemColor: _primaryBlue,
                unselectedItemColor: isDark ? Colors.grey : _textSecondary,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                onTap: _onItemTapped,
                items: <BottomNavigationBarItem>[
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Beranda',
                  ),
                  BottomNavigationBarItem(
                    icon: badges.Badge(
                      showBadge: _unreadNotificationCount > 0,
                      position: badges.BadgePosition.topEnd(top: -5, end: -2),
                      badgeStyle: const badges.BadgeStyle(badgeColor: Colors.red, padding: EdgeInsets.all(4)),
                      badgeContent: Text(
                        _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    activeIcon: badges.Badge(
                      showBadge: _unreadNotificationCount > 0,
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
          ],
        ),
      ),
    );
  }
}