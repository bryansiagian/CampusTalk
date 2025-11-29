import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/api_services.dart';

// Import Screen Tujuan
import '../main_navigation_screen.dart'; 
import '../admin/admin_dashboard_screen.dart'; 
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
  bool _obscureText = true; 
  bool _rememberMe = false; 

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
    // --- AMBIL TEMA DARI PROVIDER/CONTEXT ---
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Warna Dinamis
    // Jika Dark Mode: Background Hitam/Abu Gelap. Jika Light: Biru Royal.
    final Color backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFF1855F4);
    
    // Warna Card
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    
    // Warna Teks di dalam Card
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey;

    // Warna Input Field
    final Color inputFillColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF3F4F6);

    // Warna Tombol & Link (Tetap Biru agar kontras, atau sesuaikan primaryColor)
    final Color accentColor = const Color(0xFF1855F4);

    return Scaffold(
      backgroundColor: backgroundColor, 
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- HEADER ---
                const Icon(Icons.school, size: 60, color: Colors.white), 
                const SizedBox(height: 16),
                const Text(
                  'CampusTalk',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Forum Diskusi Mahasiswa IT Del',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 32),

                // --- CARD LOGIN ---
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
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
                      Center(
                        child: Text(
                          'Selamat Datang',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Masuk ke akun Anda',
                          style: TextStyle(fontSize: 14, color: subTextColor),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Input Email
                      _buildLabel('Email Kampus', textColor),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: textColor), // Teks input user
                        decoration: _buildInputDecoration(
                          hintText: 'nama@students.del.ac.id',
                          icon: Icons.email_outlined,
                          fillColor: inputFillColor,
                          hintColor: subTextColor,
                          iconColor: subTextColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Input Password
                      _buildLabel('Kata Sandi', textColor),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        style: TextStyle(color: textColor),
                        decoration: _buildInputDecoration(
                          hintText: 'Masukkan kata sandi',
                          icon: Icons.lock_outline,
                          fillColor: inputFillColor,
                          hintColor: subTextColor,
                          iconColor: subTextColor,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: subTextColor,
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
                      const SizedBox(height: 12),
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
                                  activeColor: accentColor,
                                  checkColor: Colors.white,
                                  side: BorderSide(color: subTextColor),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (val) {
                                    setState(() {
                                      _rememberMe = val ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('Ingat saya', style: TextStyle(fontSize: 13, color: textColor)),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fitur reset password belum tersedia')),
                              );
                            },
                            child: Text(
                              'Lupa password?',
                              style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Tombol Login
                      _isLoading
                          ? Center(child: SpinKitThreeBounce(color: accentColor, size: 30.0))
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Masuk',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                      
                      const SizedBox(height: 24),

                      // Footer Daftar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Belum punya akun? ", style: TextStyle(color: subTextColor)),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const RegisterScreen()),
                              );
                            },
                            child: Text(
                              "Daftar sekarang",
                              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: color),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText, 
    required Color fillColor,
    required Color hintColor,
    required Color iconColor,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: hintColor, fontSize: 14),
      filled: true,
      fillColor: fillColor,
      prefixIcon: icon != null ? Icon(icon, color: iconColor, size: 20) : null,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1855F4), width: 1.5),
      ),
    );
  }
}