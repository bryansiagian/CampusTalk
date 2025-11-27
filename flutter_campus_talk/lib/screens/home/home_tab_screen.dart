import 'package:flutter/material.dart';
import 'package:flutter_campus_talk/screens/post/post_detail_screen.dart';
import '../../models/post.dart';
import '../../services/api_services.dart';
import '../post/create_post_screen.dart';
// IMPORT SCREEN LAIN UNTUK NAVIGASI ICON ATAS
import '../notification/notification_screen.dart';
import '../profile/profile_screen.dart'; 

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  int _selectedCategoryIndex = 0;
  final ApiServices _apiServices = ApiServices();
  
  final List<String> _categories = [
    "Semua", "Tugas Kuliah", "Pengumuman", "Magang", "Skripsi", "Tips & Trik"
  ];

  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final posts = await _apiServices.getPosts();
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error fetching posts: $e");
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchPosts();
  }

  String _calculateTimeAgo(String createdAt) {
    try {
      final DateTime postDate = DateTime.parse(createdAt);
      final Duration difference = DateTime.now().difference(postDate);
      if (difference.inDays > 7) return "${postDate.day}/${postDate.month}/${postDate.year}";
      if (difference.inDays >= 1) return "${difference.inDays} hari lalu";
      if (difference.inHours >= 1) return "${difference.inHours} jam lalu";
      if (difference.inMinutes >= 1) return "${difference.inMinutes} menit lalu";
      return "Baru saja";
    } catch (e) {
      return "Baru saja";
    }
  }

  Color _getAvatarColor(String name) {
    if (name.isEmpty) return Colors.blue;
    return Colors.primaries[name.codeUnitAt(0) % Colors.primaries.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("CampusTalk", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Forum Mahasiswa IT Del", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
        // --- BAGIAN INI DITAMBAHKAN (ICON LONCENG & PROFIL DI ATAS) ---
        actions: [
          // Icon Notifikasi
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
            },
            icon: const Icon(Icons.notifications_outlined, color: Colors.black54),
          ),
          // Icon Profil
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
              },
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
        // -------------------------------------------------------------
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          ).then((value) {
            if (value == true) _handleRefresh();
          });
        },
        backgroundColor: Colors.blue,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                color: Colors.white,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Cari postingan...",
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      Icon(Icons.filter_list, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),

              // Filter Kategori
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 12, left: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_categories.length, (index) {
                      final isSelected = index == _selectedCategoryIndex;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategoryIndex = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? Colors.black : Colors.grey[300]!),
                            ),
                            child: Text(
                              _categories[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontSize: 12, fontWeight: FontWeight.w500
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // List Postingan
              if (_isLoading)
                const Padding(padding: EdgeInsets.only(top: 50), child: CircularProgressIndicator())
              else if (_posts.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Text("Belum ada postingan", style: TextStyle(color: Colors.grey)),
                )
              else
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    return _buildPostCard(_posts[index]);
                  },
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return GestureDetector(
      onTap: () {
         Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailScreen(postId: post.id)));
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.symmetric(horizontal: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getAvatarColor(post.author.name),
                  child: Text(post.author.name.isNotEmpty ? post.author.name[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.author.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(_calculateTimeAgo(post.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                  child: Text(post.category.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(post.content, style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            if (post.tags != null)
              Wrap(spacing: 8, children: post.tags!.map((t) => Text("#${t.name}", style: const TextStyle(color: Colors.blue, fontSize: 12))).toList()),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              children: [
                Icon(post.isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border, size: 18, color: post.isLikedByCurrentUser ? Colors.red : Colors.grey[600]),
                const SizedBox(width: 4),
                Text("${post.totalLikes}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text("${post.totalComments}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            )
          ],
        ),
      ),
    );
  }
}