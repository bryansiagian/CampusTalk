import 'package:flutter/material.dart';
import 'package:flutter_campus_talk/screens/post/post_detail_screen.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/api_services.dart';
import '../post/create_post_screen.dart';
import '../notification/notification_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  final ApiServices _apiServices = ApiServices();
  
  List<Post> _posts = [];
  bool _isLoadingPosts = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchPosts();
  }

  // Helper URL Gambar
  String _fixImageUrl(String url) {
    if (url.startsWith('/')) return 'http://10.0.2.2:8000$url';
    if (url.contains('localhost')) return url.replaceAll('localhost', '10.0.2.2');
    if (url.contains('127.0.0.1')) return url.replaceAll('127.0.0.1', '10.0.2.2');
    return url;
  }

  Future<void> _fetchUserData() async {
    try {
      final user = await _apiServices.getCurrentUser();
      if (mounted) setState(() => _currentUser = user);
    } catch (e) {
      print("Error fetching user: $e");
    }
  }

  // Fetch Postingan Terbaru (Tanpa Filter Kategori)
  Future<void> _fetchPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      // Langsung ambil semua postingan terbaru
      final posts = await _apiServices.getPosts(
        sortBy: 'latest', 
      );
      
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPosts = false);
      print("Error fetching posts: $e");
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchUserData();
    await _fetchPosts();
  }

  String _calculateTimeAgo(String createdAt) {
    try {
      final DateTime postDate = DateTime.parse(createdAt);
      final Duration difference = DateTime.now().difference(postDate);
      if (difference.inDays > 7) return "${postDate.day}/${postDate.month}/${postDate.year}";
      if (difference.inDays >= 1) return "${difference.inDays}hr";
      if (difference.inHours >= 1) return "${difference.inHours}j";
      if (difference.inMinutes >= 1) return "${difference.inMinutes}m";
      return "Baru saja";
    } catch (e) {
      return "Now";
    }
  }

  Color _getAvatarColor(String name) {
    if (name.isEmpty) return Colors.blue;
    return Colors.primaries[name.codeUnitAt(0) % Colors.primaries.length];
  }

  @override
  Widget build(BuildContext context) {
    // Tema Dinamis
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final searchBarColor = isDark ? Colors.grey[800] : Colors.grey[200];
    final iconColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          "CampusTalk", 
          style: TextStyle(
            color: colorScheme.primary, 
            fontSize: 22, 
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5
          )
        ),
        centerTitle: false,
        actions: [
          // 1. TOMBOL CARI (Menuju SearchScreen)
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen()));
            },
            icon: Icon(Icons.search, color: textTheme.bodyLarge?.color, size: 26),
            tooltip: "Cari Postingan",
          ),
          
          // 2. TOMBOL NOTIFIKASI
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
            },
            icon: Icon(Icons.notifications_none_rounded, color: textTheme.bodyLarge?.color, size: 26),
          ),

          // 3. AVATAR PROFIL
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
                    .then((_) => _handleRefresh());
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: searchBarColor,
                backgroundImage: (_currentUser != null && _currentUser!.profilePictureUrl != null)
                    ? NetworkImage(_fixImageUrl(_currentUser!.profilePictureUrl!))
                    : null,
                child: (_currentUser == null || _currentUser!.profilePictureUrl == null)
                    ? Icon(Icons.person, size: 20, color: iconColor)
                    : null,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.dividerColor, height: 1),
        ),
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
        backgroundColor: colorScheme.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: colorScheme.onPrimary, size: 32),
      ),

      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. LIST POSTINGAN (FEED)
            if (_isLoadingPosts)
              SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: colorScheme.primary)))
            else if (_posts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.forum_outlined, size: 80, color: iconColor),
                      const SizedBox(height: 16),
                      Text("Belum ada postingan terbaru", style: TextStyle(color: iconColor)),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildTwitterStylePost(_posts[index], theme, colorScheme);
                  },
                  childCount: _posts.length,
                ),
              ),
              
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildTwitterStylePost(Post post, ThemeData theme, ColorScheme colorScheme) {
    final textPrimary = theme.textTheme.bodyLarge?.color;
    final textSecondary = theme.textTheme.bodyMedium?.color;
    final borderColor = theme.dividerColor;

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailScreen(postId: post.id)))
            .then((_) => _handleRefresh());
      },
      child: Container(
        // Background color dipindah ke dalam BoxDecoration
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor, 
          border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Penulis
            CircleAvatar(
              radius: 22,
              backgroundColor: _getAvatarColor(post.author.name),
              backgroundImage: post.author.profilePictureUrl != null 
                  ? NetworkImage(_fixImageUrl(post.author.profilePictureUrl!))
                  : null,
              child: post.author.profilePictureUrl == null
                  ? Text(
                      post.author.name.isNotEmpty ? post.author.name[0].toUpperCase() : "?", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            
            // Konten Postingan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (Nama & Waktu)
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          post.author.name,
                          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "• ${_calculateTimeAgo(post.createdAt)}", 
                        style: TextStyle(color: textSecondary, fontSize: 13)
                      ),
                    ],
                  ),
                  
                  // Kategori
                  const SizedBox(height: 2),
                  Text(
                    post.category.name, 
                    style: TextStyle(color: textSecondary, fontSize: 11)
                  ),

                  // Judul & Isi
                  const SizedBox(height: 6),
                  Text(
                    post.title, 
                    style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700)
                  ),
                  Text(
                    post.content, 
                    style: TextStyle(color: textPrimary, fontSize: 14, height: 1.4), 
                    maxLines: 4, 
                    overflow: TextOverflow.ellipsis
                  ),
                  
                  // Media (Gambar)
                  if (post.mediaUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor)
                          ),
                          child: Image.network(
                            _fixImageUrl(post.mediaUrl!),
                            width: double.infinity, height: 200, fit: BoxFit.cover,
                            errorBuilder: (_,__,___) => const SizedBox(),
                          ),
                        ),
                      ),
                    ),

                  // Tags
                  if (post.tags != null && post.tags!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8, 
                        children: post.tags!.map((t) => Text("#${t.name}", style: TextStyle(color: colorScheme.primary, fontSize: 13))).toList()
                      ),
                    ),

                  // Tombol Aksi (Like, Comment, View)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0, right: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildActionIcon(Icons.chat_bubble_outline, "${post.totalComments}", textSecondary),
                        _buildActionIcon(
                          post.isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                          "${post.totalLikes}", 
                          post.isLikedByCurrentUser ? Colors.pink : textSecondary
                        ),
                        _buildActionIcon(Icons.bar_chart_rounded, "${post.views}", textSecondary),
                        Icon(Icons.share_outlined, size: 18, color: textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String count, Color? color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(count, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}