// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <--- Import Provider
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'providers/theme_provider.dart'; // Import Provider
import 'utils/app_theme.dart'; // Import Theme

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Reset token (Opsional, sesuai request sebelumnya)
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');

  // Load Provider dulu sebelum jalankan App
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    ChangeNotifierProvider(
      create: (_) => themeProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ambil data tema dari Provider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'CampusTalk App',
      debugShowCheckedModeBanner: false,
      
      // --- KONFIGURASI TEMA ---
      themeMode: themeProvider.themeMode, // System / Light / Dark
      theme: AppTheme.lightTheme,         // Definisi Light
      darkTheme: AppTheme.darkTheme,      // Definisi Dark
      // ------------------------

      home: const LoginScreen(),
    );
  }
}