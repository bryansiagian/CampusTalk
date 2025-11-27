import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/api_services.dart';
import '../post/post_detail_screen.dart';
import 'dart:async';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiServices _apiServices = ApiServices();
  late Future<User?> _userProfileFuture = Future.value(null);
  late Future<List<Post>> _userPostsFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  void _fetchProfileData() {
    setState(() {
      _userProfileFuture = _apiServices.getCurrentUser().catchError((error) {
        print('Error fetching current user: $error');
        return null;
      });

      _userPostsFuture = _userProfileFuture.then((user) {
        if (user != null) {
          return _apiServices.getPostsByUser(user.id);
        } else {
          return Future.value(<Post>[]);
        }
      }).catchError((error) {
        print('Error fetching user posts: $error');
        return Future.value(<Post>[]);
      });
    });
  }

  Future<void> _refreshProfileAndPosts() async {
    _fetchProfileData();
  }

  // Helper untuk format tanggal sederhana (Tanpa package intl)
  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      // Format: 15 Agustus 2024 (Manual mapping bulan)
      List<String> months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return "${date.day} ${months[date.month - 1]} ${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  // Helper warna avatar
  Color _getAvatarColor(String name) {
    if (name.isEmpty) return Colors.blue;
    return Colors.primaries[name.codeUnitAt(0) % Colors.primaries.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Background agak abu seperti Figma
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(), // Atau sesuaikan jika ini root tab
        ),
        title: const Text(
          'Profil Saya',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: () {
                // TODO: Implementasi Edit Profil
              },
              icon: const Icon(Icons.edit, size: 16, color: Colors.black),
              label: const Text("Edit", style: TextStyle(color: Colors.black)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfileAndPosts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: FutureBuilder<User?>(
            future: _userProfileFuture,
            builder: (context, userSnapshot) {
              // LOADING STATE
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Center(child: SpinKitFadingCircle(color: Colors.blue, size: 40.0)),
                );
              }
              
              // ERROR / NULL STATE
              if (!userSnapshot.hasData || userSnapshot.data == null) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: const Center(child: Text('Gagal memuat profil.')),
                );
              }

              final user = userSnapshot.data!;

              return Column(
                children: [
                  // BAGIAN 1: HEADER PROFIL
                  _buildProfileHeader(user),

                  const SizedBox(height: 16),

                  // BAGIAN 2: STATISTIK & POSTINGAN (Butuh data posts)
                  FutureBuilder<List<Post>>(
                    future: _userPostsFuture,
                    builder: (context, postsSnapshot) {
                      // Default values jika loading/error
                      int totalPosts = 0;
                      int totalLikes = 0;
                      int totalComments = 0;
                      List<Post> posts = [];

                      if (postsSnapshot.hasData) {
                        posts = postsSnapshot.data!;
                        totalPosts = posts.length;
                        // Menghitung total like dan komen dari semua post user
                        for (var post in posts) {
                          totalLikes += post.totalLikes;
                          totalComments += post.totalComments;
                        }
                      }

                      return Column(
                        children: [
                          // Statistik Row (Post, Likes, Comments)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                _buildStatCard(Icons.chat_bubble_outline, totalPosts.toString(), "Postingan", Colors.blue),
                                const SizedBox(width: 12),
                                _buildStatCard(Icons.favorite_border, totalLikes.toString(), "Likes", Colors.red),
                                const SizedBox(width: 12),
                                _buildStatCard(Icons.comment_outlined, totalComments.toString(), "Komentar", Colors.green),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // List Postingan
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Text(
                              "Postingan Saya",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ),
                          
                          const SizedBox(height: 8),

                          if (postsSnapshot.connectionState == ConnectionState.waiting)
                             const Padding(
                               padding: EdgeInsets.all(20.0),
                               child: SpinKitThreeBounce(color: Colors.blue, size: 20),
                             )
                          else if (posts.isEmpty)
                            _buildEmptyPostState()
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: posts.length,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemBuilder: (context, index) {
                                return _buildPostItem(context, posts[index]);
                              },
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // BAGIAN 3: PENGATURAN AKUN (Settings)
                  _buildSettingsSection(context),

                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildProfileHeader(User user) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      width: double.infinity,
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blueAccent, // Sesuai figma biru
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : "?",
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          // Nama
          Text(
            user.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Email
          Text(
            user.email,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.role?.name ?? 'User', // Ambil role
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 16),
          // Tanggal Gabung
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              // Karena User model mungkin tidak punya created_at, gunakan dummy atau pastikan backend kirim
              // Asumsi: Kita pakai tanggal hari ini atau string kosong jika null
              Text(
                "Bergabung sejak ${_formatDate(DateTime.now().toIso8601String())}", // Ganti user.createdAt jika ada
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              count,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostItem(BuildContext context, Post post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(postId: post.id),
            ),
          ).then((_) => _refreshProfileAndPosts());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Stats Row (Like, Comment, Date)
              Row(
                children: [
                  Icon(Icons.favorite_border, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text("${post.totalLikes}", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  const SizedBox(width: 12),
                  Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text("${post.totalComments}", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  
                  const Spacer(),
                  
                  Text(
                    _formatDate(post.createdAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPostState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.post_add, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(
            "Belum ada postingan",
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pengaturan Akun",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildSettingItem("Ubah Kata Sandi", onTap: () {}),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildSettingItem("Pengaturan Notifikasi", onTap: () {}),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildSettingItem("Privasi & Keamanan", onTap: () {}),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildSettingItem("Keluar dari Akun", isDestructive: true, onTap: () {
                  // Tambahkan logika logout di sini (clear token, navigate to login)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Fitur Logout belum diimplementasikan")),
                  );
                }),
              ],
            ),
          ),
          // Tombol Logout Merah Besar (Opsional, sesuai Figma screenshot ke-2 di bawah)
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                 // Logika Logout
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F), // Merah
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
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      visualDensity: const VisualDensity(vertical: -2), // Membuat list lebih rapat
    );
  }
}