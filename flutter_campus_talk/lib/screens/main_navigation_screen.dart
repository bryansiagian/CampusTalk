// lib/screens/main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_services.dart';
import 'auth/login_screen.dart';
import 'home/home_tab_screen.dart'; // Import HomeTabScreen yang baru
import 'post/post_list_screen.dart'; // Import PostListScreen yang baru
import 'profile/profile_screen.dart'; // Import ProfileScreen yang baru

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0; // Index tab yang aktif
  final ApiServices _apiServices = ApiServices();

  // Daftar widget untuk setiap tab
  final List<Widget> _widgetOptions = <Widget>[
    const HomeTabScreen(),      // Tab Beranda
    const PostListScreen(),     // Tab Daftar Postingan
    const ProfileScreen(),      // Tab Profil
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    try {
      await _apiServices.logout();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('token'); // Pastikan token dihapus
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
          // Anda bisa memindahkan tombol notifikasi di sini atau di masing-masing tab
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Navigator.of(context).push(
              //   MaterialPageRoute(builder: (context) => NotificationScreen()),
              // );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Fitur notifikasi akan datang'))
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
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
        onTap: _onItemTapped,
      ),
    );
  }
}