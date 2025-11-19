import 'package:flutter/material.dart';
// import 'package:flutter_campus_talk/services/api_services.dart'; // Hapus ini, karena sudah ada yang relatif
import '../../services/api_services.dart'; // Pertahankan yang ini
import '../main_navigation_screen.dart'; // <--- PASTIKAN INI DIIMPOR
import 'package:flutter_spinkit/flutter_spinkit.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  final ApiServices _apiServices = ApiServices();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _passwordConfirmationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua kolom harus diisi.')),
      );
      return;
    }
    if (_passwordController.text != _passwordConfirmationController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konfirmasi password tidak cocok.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _apiServices.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        _passwordConfirmationController.text,
      );

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registrasi Berhasil! Selamat datang, ${user.name}')),
        );
        Navigator.of(context).pushReplacement(
          // PERBAIKAN: Ganti HomeScreen() dengan MainNavigationScreen()
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrasi CampusTalk', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Daftar Akun Baru',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Kampus',
                  hintText: 'contoh@del.ac.id',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordConfirmationController,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_reset),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? SpinKitWave(color: Theme.of(context).primaryColor, size: 30.0)
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Daftar', style: TextStyle(fontSize: 18)),
                      ),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Ini akan kembali ke LoginScreen
                },
                child: const Text('Sudah punya akun? Login di sini'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}