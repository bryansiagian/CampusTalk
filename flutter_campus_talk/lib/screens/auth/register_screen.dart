import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_services.dart';
import '../../models/prodi.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nimController = TextEditingController();
  final _angkatanController = TextEditingController();

  final ApiServices _apiService = ApiServices();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // State Prodi
  List<Prodi> _prodiList = [];
  Prodi? _selectedProdi;
  bool _isLoadingProdi = true;

  @override
  void initState() {
    super.initState();
    _fetchProdis();
  }

  Future<void> _fetchProdis() async {
    try {
      final list = await _apiService.getProdis();
      
      // Hapus duplikat jika ada (Safety)
      final uniqueList = list.toSet().toList();

      if (mounted) {
        setState(() {
          _prodiList = uniqueList;
          _isLoadingProdi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProdi = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error pick image: $e");
    }
  }

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _nimController.text.isEmpty ||     
        _selectedProdi == null || 
        _angkatanController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua kolom harus diisi')));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password tidak sama')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool success = await _apiService.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        _confirmPasswordController.text,
        _nimController.text,       
        _selectedProdi!.id,
        _angkatanController.text,
        _profileImage,
      );

      if (success && mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Registrasi Berhasil'),
            content: const Text('Akun Anda telah dibuat dan sedang menunggu persetujuan Admin.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); 
                  Navigator.pop(context); 
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception:', ''))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nimController.dispose();
    _angkatanController.dispose();
    super.dispose();
  }

  Widget _buildLabel(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 14
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required Color fillColor,
    required Color hintColor,
    required Color iconColor,
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      obscureText: isPassword ? obscureText : false,
      maxLength: maxLength,
      style: TextStyle(color: iconColor), // Warna teks input
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: hintColor, fontSize: 14),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        counterText: "",
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: hintColor),
                onPressed: onToggleVisibility,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- SETUP TEMA ---
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Warna Background Utama: Biru (Light) atau Hitam/DarkGrey (Dark)
    final Color backgroundColor = isDark ? theme.scaffoldBackgroundColor : theme.primaryColor;
    
    // Warna Kartu
    final Color cardColor = theme.cardColor;
    
    // Warna Input Field
    final Color inputFillColor = isDark ? Colors.grey[800]! : const Color(0xFFF3F4F6);
    final Color hintColor = isDark ? Colors.grey[400]! : Colors.grey;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text(
                  'Daftar Akun Baru',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bergabung dengan komunitas IT Del',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10, 
                        offset: const Offset(0, 5)
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FOTO PROFIL
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: inputFillColor,
                              backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                              child: _profileImage == null 
                                ? Icon(Icons.person, size: 40, color: hintColor) 
                                : null,
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: cardColor, width: 2)
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildLabel('Nama Lengkap', theme),
                      _buildTextField(
                        controller: _nameController, 
                        hintText: 'Masukkan nama lengkap',
                        fillColor: inputFillColor, hintColor: hintColor, iconColor: textColor
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('NIM', theme),
                      _buildTextField(
                        controller: _nimController, 
                        hintText: 'Masukkan NIM', 
                        inputType: TextInputType.number,
                        fillColor: inputFillColor, hintColor: hintColor, iconColor: textColor
                      ),
                      const SizedBox(height: 16),

                      // --- DROPDOWN PRODI ---
                      _buildLabel('Program Studi', theme),
                      _isLoadingProdi
                          ? Center(child: Padding(padding: const EdgeInsets.all(8.0), child: CircularProgressIndicator(color: theme.primaryColor)))
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: inputFillColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<Prodi>(
                                  value: _selectedProdi,
                                  isExpanded: true,
                                  dropdownColor: cardColor, // Dropdown menu bg
                                  hint: Text(
                                    'Pilih Program Studi',
                                    style: TextStyle(color: hintColor, fontSize: 14),
                                  ),
                                  icon: Icon(Icons.arrow_drop_down, color: hintColor),
                                  items: _prodiList.map((Prodi prodi) {
                                    return DropdownMenuItem<Prodi>(
                                      value: prodi,
                                      child: Text(
                                        prodi.name,
                                        style: TextStyle(color: textColor, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _prodiList.isEmpty 
                                      ? null 
                                      : (Prodi? newValue) {
                                          setState(() {
                                            _selectedProdi = newValue;
                                          });
                                          FocusScope.of(context).requestFocus(FocusNode());
                                        },
                                ),
                              ),
                            ),
                      const SizedBox(height: 16),

                      _buildLabel('Angkatan', theme),
                      _buildTextField(
                        controller: _angkatanController, 
                        hintText: 'Contoh: 2023', 
                        inputType: TextInputType.number, 
                        maxLength: 4,
                        fillColor: inputFillColor, hintColor: hintColor, iconColor: textColor
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Email Kampus', theme),
                      _buildTextField(
                        controller: _emailController, 
                        hintText: 'nama@students.del.ac.id', 
                        inputType: TextInputType.emailAddress,
                        fillColor: inputFillColor, hintColor: hintColor, iconColor: textColor
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Kata Sandi', theme),
                      _buildTextField(
                        controller: _passwordController,
                        hintText: 'Minimal 6 karakter',
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                        fillColor: inputFillColor, hintColor: hintColor, iconColor: textColor
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Konfirmasi Kata Sandi', theme),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Ulangi kata sandi',
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        fillColor: inputFillColor, hintColor: hintColor, iconColor: textColor
                      ),
                      const SizedBox(height: 32),

                      _isLoading
                          ? Center(child: SpinKitThreeBounce(color: theme.primaryColor, size: 30.0))
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                                child: const Text('Daftar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                      
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Sudah punya akun? ", style: TextStyle(color: textColor.withOpacity(0.7))),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              "Masuk", 
                              style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)
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
}