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
  
  // State Notifikasi
  int _unreadNotificationCount = 0; 

  // State Filter Kategori
  int _selectedCategoryIndex = 0;
  final List<String> _categories = [
    "Semua", "Tugas Kuliah", "Pengumuman", "Magang", "Skripsi", "Tips & Trik"
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchPosts();
    _fetchUnreadNotifications();
  }

  final String _serverIp = '10.180.3.115'; 
  final String _port = '8000';

  String _fixImageUrl(String url) {
    if (url.isEmpty) return "";
    
    // 1. Bersihkan spasi
    url = url.trim();

    // 2. Jika URL sudah lengkap (http/https), kita hanya perlu mengganti Host-nya
    if (url.startsWith('http')) {
      return url
          .replaceAll('localhost', _serverIp)
          .replaceAll('127.0.0.1', _serverIp)
          .replaceAll('10.0.2.2', _serverIp);
    }

    // 3. Menangani Path Relatif (Contoh: "/storage/posts/..." atau "posts/...")
    
    // Hapus slash di depan jika ada, agar penggabungan rapi
    if (url.startsWith('/')) {
      url = url.substring(1); 
    }

    // Cek apakah path sudah mengandung kata 'storage'
    // Laravel biasanya menyimpan di 'public/posts/img.jpg', tapi diakses lewat 'storage/posts/img.jpg'
    // Jika path dari DB adalah 'posts/img.jpg', kita harus tambahkan 'storage/'
    if (!url.startsWith('storage')) {
      url = 'storage/$url';
    }

    // Gabungkan menjadi URL utuh
    final finalUrl = 'http://$_serverIp:$_port/$url';
    
    // DEBUG: Cek URL ini di terminal jika masih gagal
    print("Fixed URL: $finalUrl"); 
    
    return finalUrl;
  }

  Future<void> _fetchUserData() async {
    try {
      final user = await _apiServices.getCurrentUser();
      if (mounted) setState(() => _currentUser = user);
    } catch (e) {
      print("Error fetching user: $e");
    }
  }

  Future<void> _fetchUnreadNotifications() async {
    try {
      final count = await _apiServices.getUnreadNotificationCount();
      if (mounted) setState(() => _unreadNotificationCount = count);
    } catch (e) {
      print("Error fetching notification count: $e");
    }
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      final posts = await _apiServices.getPosts(sortBy: 'latest');
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
    await Future.wait([
      _fetchUserData(),
      _fetchPosts(),
      _fetchUnreadNotifications(),
    ]);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final searchBarColor = isDark ? Colors.grey[800] : Colors.grey[200];
    final iconColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      
      // Floating Action Button tetap di Scaffold
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

      // Body menggunakan CustomScrollView untuk efek Sliver
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            
            // 1. APP BAR YANG BISA HILANG (SLIVER)
            SliverAppBar(
              backgroundColor: theme.appBarTheme.backgroundColor ?? theme.cardColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              
              // --- KONFIGURASI HIDE ON SCROLL ---
              floating: true, // Muncul segera saat scroll ke atas
              snap: true,     // Langsung muncul penuh
              pinned: false,  // Ikut menghilang saat scroll ke bawah
              // ----------------------------------
              
              title: Text(
                "CampusTalk", 
                style: TextStyle(color: colorScheme.primary, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.5)
              ),
              centerTitle: false,
              actions: [
                // SEARCH
                IconButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen()));
                  },
                  icon: Icon(Icons.search, color: textTheme.bodyLarge?.color, size: 26),
                ),
                
                // NOTIFIKASI
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()))
                            .then((_) => _fetchUnreadNotifications());
                      },
                      icon: Icon(Icons.notifications_none_rounded, color: textTheme.bodyLarge?.color, size: 26),
                    ),
                    if (_unreadNotificationCount > 0)
                      Positioned(
                        right: 8, top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            _unreadNotificationCount > 9 ? '9+' : '$_unreadNotificationCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),

                // PROFIL
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
                      backgroundImage: (_currentUser != null && _currentUser!.profilePictureUrl != null && _currentUser!.profilePictureUrl!.isNotEmpty)
                          ? NetworkImage(_fixImageUrl(_currentUser!.profilePictureUrl!))
                          : null,
                      child: (_currentUser == null || _currentUser!.profilePictureUrl == null || _currentUser!.profilePictureUrl!.isEmpty)
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

            // 3. LIST POSTINGAN
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
            
            // Spacer bawah agar FAB tidak menutupi konten terakhir
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

    // Cek apakah Author punya foto
    bool hasAuthorPhoto = post.author.profilePictureUrl != null && post.author.profilePictureUrl!.isNotEmpty;

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailScreen(postId: post.id)))
            .then((_) => _handleRefresh());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor, 
          border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AVATAR PENULIS
            CircleAvatar(
              radius: 22,
              backgroundColor: _getAvatarColor(post.author.name),
              backgroundImage: hasAuthorPhoto 
                  ? NetworkImage(_fixImageUrl(post.author.profilePictureUrl!))
                  : null,
              onBackgroundImageError: hasAuthorPhoto 
                  ? (_, __) { print("Error load author image"); } 
                  : null,
              child: !hasAuthorPhoto
                  ? Text(
                      post.author.name.isNotEmpty ? post.author.name[0].toUpperCase() : "?", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER (NAMA & WAKTU)
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
                  const SizedBox(height: 2),
                  Text(
                    post.category.name, 
                    style: TextStyle(color: textSecondary, fontSize: 11)
                  ),
                  const SizedBox(height: 6),
                  
                  // KONTEN TEKS
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
                  
                  // KONTEN GAMBAR
                  if (post.mediaUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: borderColor)),
                          child: Image.network(
                            _fixImageUrl(post.mediaUrl!),
                            width: double.infinity, height: 200, fit: BoxFit.cover,
                            errorBuilder: (_,__,___) => const SizedBox(),
                          ),
                        ),
                      ),
                    ),
                  
                  // TAGS
                  if (post.tags != null && post.tags!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8, 
                        children: post.tags!.map((t) => Text("#${t.name}", style: TextStyle(color: colorScheme.primary, fontSize: 13))).toList()
                      ),
                    ),
                  
                  // ACTION BUTTONS
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