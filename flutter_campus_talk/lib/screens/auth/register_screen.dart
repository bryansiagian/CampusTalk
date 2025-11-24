// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/api_services.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Definisi Controller
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // <--- INI YANG TADINYA HILANG
  final _nimController = TextEditingController();
  final _prodiController = TextEditingController();
  final _angkatanController = TextEditingController();

  final ApiServices _apiService = ApiServices();
  bool _isLoading = false;

  Future<void> _register() async {
    // 1. Validasi Input Kosong
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _nimController.text.isEmpty ||     
        _prodiController.text.isEmpty ||   
        _angkatanController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom harus diisi')),
      );
      return;
    }

    // 2. Validasi Password Match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password dan Konfirmasi Password tidak sama')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Panggil API Register
      bool success = await _apiService.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        _confirmPasswordController.text, // <--- Sekarang variabel ini sudah ada
        _nimController.text,       
        _prodiController.text,     
        _angkatanController.text,
      );

      if (success) {
        if (mounted) {
          // 4. Tampilkan Dialog Sukses & Info Approval
          await showDialog(
            context: context,
            barrierDismissible: false, // User harus klik OK
            builder: (context) => AlertDialog(
              title: const Text('Registrasi Berhasil'),
              content: const Text(
                'Akun Anda telah dibuat.\n\n'
                'Demi keamanan, akun Anda berstatus "Pending".\n'
                'Mohon tunggu persetujuan dari Admin sebelum Anda dapat Login.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Tutup Dialog
                    Navigator.pop(context); // Kembali ke Login Screen
                  },
                  child: const Text('OK, Saya Mengerti'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception:', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun Baru'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Buat Akun',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              // Input Nama
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              // Input NIM
              TextField(
                controller: _nimController,
                decoration: InputDecoration(
                  labelText: 'NIM',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.badge),
                ),
                keyboardType: TextInputType.number, // Keyboard angka
              ),
              const SizedBox(height: 16),

              // Input Prodi
              TextField(
                controller: _prodiController,
                decoration: InputDecoration(
                  labelText: 'Program Studi',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.school),
                ),
              ),
              const SizedBox(height: 16),

              // Input Angkatan
              TextField(
                controller: _angkatanController,
                decoration: InputDecoration(
                  labelText: 'Angkatan (Tahun)',
                  hintText: 'Contoh: 2023',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number, // Keyboard angka
                maxLength: 4, // Batasi 4 digit
              ),
              // const SizedBox(height: 16) - tidak perlu karena TextField maxLength ada padding bawahnya
              
              // Input Email
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
              
              // Input Password
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
              
              // Input Konfirmasi Password
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              
              // Tombol Daftar
              _isLoading
                  ? SpinKitThreeBounce(color: Theme.of(context).primaryColor, size: 30.0)
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
            ],
          ),
        ),
      ),
    );
  }
}