import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/api_services.dart';

// Import Screen Tujuan
import '../main_navigation_screen.dart'; // Untuk User Biasa
import '../admin/admin_dashboard_screen.dart'; // Untuk Admin
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiServices _apiService = ApiServices();
  
  bool _isLoading = false;
  bool _obscureText = true; // Untuk toggle password visibility
  bool _rememberMe = false; // Untuk checkbox ingat saya

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password tidak boleh kosong')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selamat datang, ${user.name}!')),
        );

        if (user.isAdmin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception:', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Warna Biru Utama sesuai desain (Royal Blue)
    final Color mainBlueColor = const Color(0xFF1855F4); 
    
    return Scaffold(
      backgroundColor: mainBlueColor, // Background Biru Penuh
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- HEADER DI LUAR KARTU ---
                const Text(
                  'CampusTalk',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Image.asset(
                  'assets/images/logos/kampus.jpeg', // Pastikan path file sesuai dengan folder aset Anda
                  height: 60,               // Atur tinggi logo
                  width: 80,                // Atur lebar logo (opsional)
                ),
                const SizedBox(height: 8),
                const Text(
                  'Forum Diskusi Mahasiswa IT Del',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),

                // --- CARD PUTIH ---
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20), // Sudut melengkung
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul Card
                      const Center(
                        child: Text(
                          'Selamat Datang',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Masuk ke akun Anda',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Input Email
                      _buildLabel('Email Kampus'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration(
                          hintText: 'nama@students.del.ac.id',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Input Password
                      _buildLabel('Kata Sandi'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        decoration: _buildInputDecoration(
                          hintText: 'Masukkan kata sandi',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                      ),

                      // Row: Ingat Saya & Lupa Password
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: mainBlueColor,
                                  onChanged: (val) {
                                    setState(() {
                                      _rememberMe = val ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Ingat saya', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              // Aksi Lupa Password
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fitur reset password belum tersedia')),
                              );
                            },
                            child: Text(
                              'Lupa password?',
                              style: TextStyle(color: mainBlueColor, fontSize: 13),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Tombol Login
                      _isLoading
                          ? Center(child: SpinKitWave(color: mainBlueColor, size: 30.0))
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: mainBlueColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                      
                      const SizedBox(height: 24),

                      // Footer Daftar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Belum punya akun? ", style: TextStyle(color: Colors.black54)),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const RegisterScreen()),
                              );
                            },
                            child: Text(
                              "Daftar sekarang",
                              style: TextStyle(
                                color: mainBlueColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Demo Text (Opsional seperti di gambar)
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8)
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget Helper untuk Label di atas Input
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Colors.black87,
      ),
    );
  }

  // Helper untuk Style Input Field (Background abu-abu, tanpa border outline)
  InputDecoration _buildInputDecoration({required String hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF3F4F6), // Abu-abu muda
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none, // Hilangkan garis border
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1855F4), width: 1), // Sedikit biru saat aktif
      ),
    );
  }
}