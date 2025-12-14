import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/api_services.dart';
import '../post/post_detail_screen.dart';
import '../auth/login_screen.dart';

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

  // STATE BARU: Kontrol Tampilkan Semua Postingan
  bool _showAllPosts = false; 

  // Cek apakah ini profil saya sendiri
  bool get _isMyProfile => widget.userId == null;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  // Ganti IP ini sesuai IP Laptop Anda
  final String _serverIp = '10.180.3.115'; 
  final String _port = '8000';

  String _fixImageUrl(String url) {
    if (url.isEmpty) return "";
    url = url.trim();
    if (url.startsWith('http')) {
      return url
          .replaceAll('localhost', _serverIp)
          .replaceAll('127.0.0.1', _serverIp)
          .replaceAll('10.0.2.2', _serverIp);
    }
    if (url.startsWith('/')) {
      url = url.substring(1); 
    }
    if (!url.startsWith('storage')) {
      url = 'storage/$url';
    }
    return 'http://$_serverIp:$_port/$url';
  }

  void _fetchProfileData() {
    // Reset state _showAllPosts saat refresh data
    _showAllPosts = false; 

    setState(() {
      if (_isMyProfile) {
        _userProfileFuture = _apiServices.getCurrentUser();
        _userPostsFuture = _userProfileFuture.then((user) {
          return user != null ? _apiServices.getPostsByUser(user.id) : Future.value(<Post>[]);
        });
      } else {
        _userProfileFuture = _apiServices.getUserById(widget.userId!);
        _userPostsFuture = _apiServices.getPostsByUser(widget.userId!);
      }
    });
  }

  Future<void> _refreshProfileAndPosts() async {
    _fetchProfileData();
  }

  Future<void> _changeProfilePicture() async {
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

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      List<String> months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
      return "${date.day} ${months[date.month - 1]} ${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
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
                  _buildProfileHeader(user, theme, isDark),
                  const SizedBox(height: 16),
                  
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

                      // --- LOGIKA PEMBATASAN 3 POSTINGAN ---
                      // Tentukan berapa item yang akan ditampilkan
                      int itemCount = 0;
                      if (posts.isNotEmpty) {
                        if (_showAllPosts) {
                          itemCount = posts.length; // Tampilkan semua
                        } else {
                          // Jika > 3 ambil 3, jika tidak ambil semua
                          itemCount = posts.length > 3 ? 3 : posts.length;
                        }
                      }
                      // -------------------------------------

                      return Column(
                        children: [
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _isMyProfile ? "Postingan Saya" : "Postingan ${user.name}",
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          if (postsSnapshot.connectionState == ConnectionState.waiting)
                             Padding(padding: const EdgeInsets.all(20.0), child: SpinKitThreeBounce(color: theme.primaryColor, size: 20))
                          else if (posts.isEmpty)
                            _buildEmptyPostState(theme)
                          else
                            Column(
                              children: [
                                // LIST POSTINGAN
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: itemCount, // Gunakan itemCount hasil hitungan di atas
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemBuilder: (context, index) => _buildPostItem(context, posts[index], theme),
                                ),

                                // TOMBOL "LIHAT LEBIH BANYAK"
                                // Muncul hanya jika postingan lebih dari 3 DAN belum di-expand
                                if (posts.length > 3 && !_showAllPosts)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _showAllPosts = true; // Expand semua
                                        });
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text("Lihat lebih banyak (${posts.length - 3} lagi)", style: TextStyle(color: theme.primaryColor)),
                                          const Icon(Icons.keyboard_arrow_down, size: 16),
                                        ],
                                      ),
                                    ),
                                  ),
                                
                                // TOMBOL "LIHAT LEBIH SEDIKIT" (Opsional, agar bisa collapse lagi)
                                if (posts.length > 3 && _showAllPosts)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _showAllPosts = false; // Collapse kembali
                                        });
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text("Lihat lebih sedikit", style: TextStyle(color: theme.disabledColor)),
                                          Icon(Icons.keyboard_arrow_up, size: 16, color: theme.disabledColor),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
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
    bool hasPhoto = user.profilePictureUrl != null;

    return Container(
      color: containerColor,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      width: double.infinity,
      child: Column(
        children: [
          GestureDetector(
            onTap: _changeProfilePicture,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blueAccent,
                  backgroundImage: hasPhoto 
                      ? NetworkImage(_fixImageUrl(user.profilePictureUrl!)) 
                      : null,
                  onBackgroundImageError: hasPhoto
                      ? (_,__) { print("Error load profile image"); }
                      : null,
                  child: !hasPhoto
                      ? Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : "?", 
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)
                        )
                      : null,
                ),
                if (_isMyProfile)
                  Positioned(
                    bottom: 0, right: 0,
                    child: CircleAvatar(
                      radius: 12, backgroundColor: Colors.white,
                      child: Icon(Icons.camera_alt, size: 14, color: Colors.black),
                    ),
                  )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(user.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(user.email, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: theme.dividerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.dividerColor)),
            child: Text(user.role?.name.toUpperCase() ?? 'USER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text("Angkatan ${user.angkatan ?? '-'}", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String count, String label, Color color, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
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
          ).then((_) => _refreshProfileAndPosts());
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
                  const Spacer(),
                  Text(_formatDate(post.createdAt), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
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
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor.withOpacity(0.5))),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Pengaturan Akun", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor.withOpacity(0.5))),
            child: Column(
              children: [
                _buildSettingItem("Ubah Kata Sandi", onTap: () {}),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildSettingItem("Keluar dari Akun", isDestructive: true, onTap: _handleLogout),
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

  Widget _buildSettingItem(String title, {bool isDestructive = false, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      title: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDestructive ? Colors.red : Colors.black87)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      visualDensity: const VisualDensity(vertical: -2),
    );
  }
}