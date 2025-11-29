import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // Pastikan package provider sudah diinstall
import 'dart:io';
import 'dart:async';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/api_services.dart';
import '../post/post_detail_screen.dart';
import '../auth/login_screen.dart';
// Pastikan Anda memiliki file ini untuk manajemen tema
import '../../providers/theme_provider.dart'; 

class ProfileScreen extends StatefulWidget {
  final int? userId; // JIKA NULL = PROFIL SAYA, JIKA ADA ANGKA = ORANG LAIN

  const ProfileScreen({Key? key, this.userId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiServices _apiServices = ApiServices();
  late Future<User?> _userProfileFuture = Future.value(null);
  late Future<List<Post>> _userPostsFuture = Future.value([]);
  final ImagePicker _picker = ImagePicker();

  // Cek apakah ini profil saya sendiri
  bool get _isMyProfile => widget.userId == null;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  // Helper URL untuk Emulator
  String _fixImageUrl(String url) {
    if (url.startsWith('/')) return 'http://10.0.2.2:8000$url';
    if (url.contains('localhost')) return url.replaceAll('localhost', '10.0.2.2');
    if (url.contains('127.0.0.1')) return url.replaceAll('127.0.0.1', '10.0.2.2');
    return url;
  }

  void _fetchProfileData() {
    setState(() {
      if (_isMyProfile) {
        // --- KASUS 1: PROFIL SAYA ---
        _userProfileFuture = _apiServices.getCurrentUser();
        _userPostsFuture = _userProfileFuture.then((user) {
          return user != null ? _apiServices.getPostsByUser(user.id) : Future.value(<Post>[]);
        });
      } else {
        // --- KASUS 2: PROFIL ORANG LAIN ---
        // Pastikan ApiServices punya method getUserById
        _userProfileFuture = _apiServices.getUserById(widget.userId!);
        _userPostsFuture = _apiServices.getPostsByUser(widget.userId!);
      }
    });
  }

  Future<void> _refreshProfileAndPosts() async {
    _fetchProfileData();
  }

  Future<void> _changeProfilePicture() async {
    // HANYA BISA GANTI FOTO KALAU PROFIL SENDIRI
    if (!_isMyProfile) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, maxHeight: 1024, imageQuality: 80,
      );
      
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mengupload foto...")));
        await _apiServices.updateProfilePicture(imageFile);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Foto profil diperbarui!")));
        _refreshProfileAndPosts(); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal mengganti foto.")));
    }
  }

  Future<void> _handleLogout() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _apiServices.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil Tema
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isMyProfile ? 'Profil Saya' : 'Profil Pengguna',
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfileAndPosts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: FutureBuilder<User?>(
            future: _userProfileFuture,
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(height: 400, child: Center(child: SpinKitFadingCircle(color: theme.primaryColor)));
              }
              if (!userSnapshot.hasData || userSnapshot.data == null) {
                return const SizedBox(height: 400, child: Center(child: Text('Gagal memuat profil.')));
              }

              final user = userSnapshot.data!;

              return Column(
                children: [
                  // Header Profil (Avatar, Nama, Prodi)
                  _buildProfileHeader(user, theme, isDark),
                  
                  const SizedBox(height: 16),
                  
                  // Statistik & Postingan
                  FutureBuilder<List<Post>>(
                    future: _userPostsFuture,
                    builder: (context, postsSnapshot) {
                      int totalPosts = 0;
                      int totalLikes = 0;
                      int totalComments = 0;
                      List<Post> posts = [];

                      if (postsSnapshot.hasData) {
                        posts = postsSnapshot.data!;
                        totalPosts = posts.length;
                        for (var post in posts) {
                          totalLikes += post.totalLikes;
                          totalComments += post.totalComments;
                        }
                      }

                      return Column(
                        children: [
                          // Kartu Statistik
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                _buildStatCard(Icons.chat_bubble_outline, "$totalPosts", "Postingan", Colors.blue, theme),
                                const SizedBox(width: 12),
                                _buildStatCard(Icons.favorite_border, "$totalLikes", "Likes", Colors.red, theme),
                                const SizedBox(width: 12),
                                _buildStatCard(Icons.comment_outlined, "$totalComments", "Komentar", Colors.green, theme),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Judul Section Postingan
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _isMyProfile ? "Postingan Saya" : "Postingan ${user.name}",
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // List Postingan
                          if (postsSnapshot.connectionState == ConnectionState.waiting)
                             Padding(padding: const EdgeInsets.all(20.0), child: SpinKitThreeBounce(color: theme.primaryColor, size: 20))
                          else if (posts.isEmpty)
                            _buildEmptyPostState(theme)
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: posts.length,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemBuilder: (context, index) => _buildPostItem(context, posts[index], theme),
                            ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Pengaturan (Hanya untuk profil sendiri)
                  if (_isMyProfile)
                    _buildSettingsSection(context, theme),

                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user, ThemeData theme, bool isDark) {
    Color containerColor = theme.cardColor;

    // Cek apakah user punya foto
    bool hasPhoto = user.profilePictureUrl != null;

    return Container(
      color: containerColor,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      width: double.infinity,
      child: Column(
        children: [
          // --- AVATAR ---
          GestureDetector(
            onTap: _isMyProfile ? _changeProfilePicture : null,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  // PERBAIKAN UTAMA: Kondisional Error Handler
                  backgroundImage: hasPhoto 
                      ? NetworkImage(_fixImageUrl(user.profilePictureUrl!)) 
                      : null,
                  onBackgroundImageError: hasPhoto
                      ? (_,__) { print("Error loading profile image"); }
                      : null,
                  
                  child: !hasPhoto
                      ? Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : "?", 
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: theme.primaryColor)
                        )
                      : null,
                ),
                if (_isMyProfile)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    ),
                  )
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // --- NAMA & EMAIL ---
          Text(user.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(user.email, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          
          const SizedBox(height: 12),
          
          // --- ROLE BADGE ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.dividerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor)
            ),
            child: Text(
              user.role?.name.toUpperCase() ?? 'USER', 
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)
            ),
          ),

          const SizedBox(height: 16),

          // --- INFORMASI AKADEMIK (PRODI & ANGKATAN) ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Prodi
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school, size: 16, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        user.prodi ?? "Prodi belum diatur", // MENAMPILKAN PRODI
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Angkatan
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      "Angkatan ${user.angkatan ?? '-'}", 
                      style: theme.textTheme.bodyMedium
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String count, String label, Color iconColor, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardColor, 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(count, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildPostItem(BuildContext context, Post post, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => PostDetailScreen(postId: post.id)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.favorite_border, size: 14, color: theme.iconTheme.color),
                  const SizedBox(width: 4),
                  Text("${post.totalLikes}", style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                  Icon(Icons.chat_bubble_outline, size: 14, color: theme.iconTheme.color),
                  const SizedBox(width: 4),
                  Text("${post.totalComments}", style: theme.textTheme.bodySmall),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPostState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(Icons.post_add, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text("Belum ada postingan", style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, ThemeData theme) {
    // Cek apakah ThemeProvider tersedia (jika belum di-setup di main.dart, fitur switch theme akan error)
    // Kita gunakan try-catch atau pengecekan sederhana
    ThemeProvider? themeProvider;
    try {
      themeProvider = Provider.of<ThemeProvider>(context);
    } catch (e) {
      // Provider not found
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Pengaturan Akun", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                // Fitur Switch Theme (Hanya jika Provider ada)
                if (themeProvider != null)
                  SwitchListTile(
                    title: Text("Mode Gelap", style: theme.textTheme.bodyMedium),
                    secondary: Icon(Icons.dark_mode, color: theme.iconTheme.color, size: 20),
                    value: themeProvider.isDarkMode,
                    onChanged: (val) => themeProvider!.toggleTheme(val),
                    activeColor: theme.primaryColor,
                  ),
                if (themeProvider != null)
                  const Divider(height: 1, indent: 16, endIndent: 16),
                
                _buildSettingItem("Ubah Kata Sandi", theme, onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur segera hadir")));
                }),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildSettingItem("Keluar dari Akun", theme, isDestructive: true, onTap: _handleLogout),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text("Keluar dari CampusTalk", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, ThemeData theme, {bool isDestructive = false, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : theme.textTheme.bodyLarge?.color,
        ),
      ),
      trailing: Icon(Icons.chevron_right, size: 20, color: theme.iconTheme.color),
      visualDensity: const VisualDensity(vertical: -1),
    );
  }
}