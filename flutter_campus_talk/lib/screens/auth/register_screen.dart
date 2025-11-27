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
  final _confirmPasswordController = TextEditingController();
  final _nimController = TextEditingController();
  final _prodiController = TextEditingController();
  final _angkatanController = TextEditingController();

  final ApiServices _apiService = ApiServices();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
        _confirmPasswordController.text,
        _nimController.text,       
        _prodiController.text,     
        _angkatanController.text,
      );

      if (success) {
        if (mounted) {
          // 4. Tampilkan Dialog Sukses
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text('Registrasi Berhasil', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  child: const Text('OK, Saya Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
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
    _nimController.dispose();
    _prodiController.dispose();
    _angkatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Warna UI sesuai desain
    final Color mainBlueColor = const Color(0xFF1855F4);
    final Color inputFillColor = const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: mainBlueColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Teks di Luar Kartu
                const Text(
                  'Daftar Akun Baru',
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bergabung dengan komunitas IT Del',
                  style: TextStyle(
                    fontSize: 14, 
                    color: Colors.white70
                  ),
                ),
                const SizedBox(height: 24),

                // Kartu Putih Utama
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                      // --- NAMA ---
                      _buildLabel('Nama Lengkap'),
                      _buildTextField(
                        controller: _nameController,
                        hintText: 'Masukkan nama lengkap',
                        fillColor: inputFillColor,
                      ),
                      const SizedBox(height: 16),

                      // --- NIM ---
                      _buildLabel('NIM'),
                      _buildTextField(
                        controller: _nimController,
                        hintText: 'Masukkan NIM',
                        inputType: TextInputType.number,
                        fillColor: inputFillColor,
                      ),
                      const SizedBox(height: 16),

                      // --- PRODI ---
                      _buildLabel('Program Studi'),
                      _buildTextField(
                        controller: _prodiController,
                        hintText: 'Contoh: D3 Teknologi Komputer',
                        fillColor: inputFillColor,
                      ),
                      const SizedBox(height: 16),

                      // --- ANGKATAN ---
                      _buildLabel('Angkatan'),
                      _buildTextField(
                        controller: _angkatanController,
                        hintText: 'Contoh: 2023',
                        inputType: TextInputType.number,
                        fillColor: inputFillColor,
                      ),
                      const SizedBox(height: 16),

                      // --- EMAIL ---
                      _buildLabel('Email Kampus'),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'nama@students.del.ac.id',
                        inputType: TextInputType.emailAddress,
                        fillColor: inputFillColor,
                      ),
                      const SizedBox(height: 16),

                      // --- PASSWORD ---
                      _buildLabel('Kata Sandi'),
                      _buildTextField(
                        controller: _passwordController,
                        hintText: 'Minimal 6 karakter',
                        fillColor: inputFillColor,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // --- CONFIRM PASSWORD ---
                      _buildLabel('Konfirmasi Kata Sandi'),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Masukkan kata sandi sekali lagi',
                        fillColor: inputFillColor,
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Info Box (Syarat & Ketentuan visual)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Dengan mendaftar, Anda menyetujui untuk menggunakan forum dengan etika yang baik.',
                                style: TextStyle(fontSize: 12, color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tombol Daftar
                      _isLoading
                          ? Center(child: SpinKitThreeBounce(color: mainBlueColor, size: 30.0))
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: mainBlueColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Daftar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                      const SizedBox(height: 20),

                      // Footer Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Sudah punya akun? ", style: TextStyle(color: Colors.black54)),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              "Masuk sekarang",
                              style: TextStyle(
                                color: mainBlueColor,
                                fontWeight: FontWeight.bold,
                              ),
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

  // --- Widget Helper untuk Label ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  // --- Widget Helper untuk TextField ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required Color fillColor,
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      obscureText: isPassword ? obscureText : false,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1855F4), width: 1),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
      ),
    );
  }
}