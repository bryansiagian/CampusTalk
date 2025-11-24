import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/api_services.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../models/comment_detail.dart';
import '../auth/login_screen.dart';
import '../post/post_detail_screen.dart'; // <--- 1. PASTIKAN IMPORT INI ADA
import 'admin_post_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final ApiServices _apiServices = ApiServices();
  late TabController _tabController;

  List<Post> _posts = [];
  List<User> _pendingUsers = [];
  List<dynamic> _reports = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchPosts(),
      _fetchUsers(),
      _fetchReports(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchPosts() async {
    try {
      final posts = await _apiServices.getPosts(sortBy: 'latest');
      _posts = posts;
    } catch (e) { print(e); }
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await _apiServices.getPendingUsers();
      _pendingUsers = users;
    } catch (e) { print(e); }
  }

  Future<void> _fetchReports() async {
    try {
      final reports = await _apiServices.getReports();
      _reports = reports;
    } catch (e) { print(e); }
  }

  // --- ACTIONS ---
  Future<void> _deletePost(int postId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Postingan?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _apiServices.deletePost(postId);
      _refreshAll();
    }
  }

  Future<void> _approveUser(int uid) async {
    await _apiServices.approveUser(uid);
    _fetchUsers();
    setState((){});
  }

  Future<void> _rejectUser(int uid) async {
    await _apiServices.rejectUser(uid);
    _fetchUsers();
    setState((){});
  }

  Future<void> _dismissReport(int reportId) async {
    await _apiServices.dismissReport(reportId);
    _fetchReports();
    setState((){});
  }

  Future<void> _handleContentDeletion(Map<String, dynamic> report) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Konten & Laporan?"),
        content: const Text("Konten yang dilaporkan akan dihapus permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      String typeString = report['reportable_type'];
      int id = report['reportable_id'];
      int reportId = report['id'];

      if (typeString.contains('Post')) {
        await _apiServices.deletePost(id);
      } else {
        await _apiServices.deleteComment(id);
      }
      
      await _apiServices.dismissReport(reportId);
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konten dihapus")));
      _refreshAll();
    }
  }

  void _handleLogout() async {
     await _apiServices.logout();
     if (mounted) {
       Navigator.of(context).pushAndRemoveUntil(
         MaterialPageRoute(builder: (context) => const LoginScreen()),
         (route) => false,
       );
     }
  }

  void _showCommentManager(int postId, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AdminCommentModal(postId: postId, postTitle: title),
    );
  }

  // Fungsi Navigasi ke Detail Post
  void _navigateToDetail(int postId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      // UBAH KE SCREEN ADMIN
      builder: (context) => AdminPostDetailScreen(postId: postId), 
    ),
  ).then((_) {
    // Refresh dashboard saat kembali
    _refreshAll(); 
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ADMIN CONSOLE", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshAll),
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.redAccent,
          tabs: const [
            Tab(icon: Icon(Icons.article), text: "Konten"),
            Tab(icon: Icon(Icons.person_add), text: "User"),
            Tab(icon: Icon(Icons.flag), text: "Laporan"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: CONTENT (MODIFIKASI DI SINI)
          _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              final post = _posts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  // 2. TAMBAHKAN OHTAP NAVIGASI KE DETAIL
                  onTap: () => _navigateToDetail(post.id),
                  
                  title: Text(
                    post.title, 
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${post.author.name} • ${post.totalComments} comments"),
                      Text(
                        post.content, 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis, 
                        style: TextStyle(fontSize: 12, color: Colors.grey[700])
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol Quick Manage Comment (Modal)
                      IconButton(
                        icon: const Icon(Icons.mode_comment_outlined),
                        onPressed: () => _showCommentManager(post.id, post.title),
                        tooltip: "Kelola Komentar Cepat",
                      ),
                      // Tombol Hapus Post
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePost(post.id),
                        tooltip: "Hapus Post",
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // TAB 2: USERS
          _isLoading ? const Center(child: CircularProgressIndicator()) : 
          _pendingUsers.isEmpty 
            ? const Center(child: Text("Tidak ada user baru."))
            : ListView.builder(
            itemCount: _pendingUsers.length,
            itemBuilder: (context, index) {
              final user = _pendingUsers[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(user.name[0])),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _approveUser(user.id)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _rejectUser(user.id)),
                    ],
                  ),
                ),
              );
            },
          ),

          // TAB 3: REPORTS
          _isLoading ? const Center(child: CircularProgressIndicator()) : 
          _reports.isEmpty 
              ? const Center(child: Text("Tidak ada laporan pending."))
              : ListView.builder(
            itemCount: _reports.length,
            itemBuilder: (context, index) {
              final r = _reports[index];
              final reporterName = r['reporter'] != null ? r['reporter']['name'] : 'User Terhapus';
              final typeString = r['reportable_type'] ?? '';
              final type = typeString.toString().contains('Post') ? 'Postingan' : 'Komentar';
              final contentId = r['reportable_id'];

              return Card(
                color: Colors.orange.shade50,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  // Bisa juga ditambahkan navigasi ke detail jika reportnya tipe Postingan
                  onTap: type == 'Postingan' ? () => _navigateToDetail(contentId) : null,
                  
                  leading: const Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 32),
                  title: Text("Laporan $type (ID: $contentId)", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Alasan: ${r['reason']}", style: const TextStyle(color: Colors.black87)),
                      Text("Pelapor: $reporterName", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                        onPressed: () => _dismissReport(r['id']),
                        tooltip: "Abaikan",
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: () => _handleContentDeletion(r),
                        tooltip: "Hapus Konten",
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Modal Admin Comment (Tetap Sama)
class AdminCommentModal extends StatefulWidget {
  final int postId;
  final String postTitle;
  const AdminCommentModal({Key? key, required this.postId, required this.postTitle}) : super(key: key);

  @override
  _AdminCommentModalState createState() => _AdminCommentModalState();
}

class _AdminCommentModalState extends State<AdminCommentModal> {
  final ApiServices _apiServices = ApiServices();
  List<CommentDetail> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await _apiServices.getCommentDetails(postId: widget.postId, sortBy: 'latest');
      if (mounted) setState(() { _comments = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _del(int id) async {
    await _apiServices.deleteComment(id);
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        children: [
          Text("Moderasi: ${widget.postTitle}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator()) 
              : _comments.isEmpty
                  ? const Center(child: Text("Tidak ada komentar."))
                  : ListView.separated(
                  itemCount: _comments.length,
                  separatorBuilder: (_,__) => const Divider(),
                  itemBuilder: (context, index) {
                    final c = _comments[index];
                    return ListTile(
                      title: Text(c.commenterName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(c.commentContent),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: () => _del(c.commentId),
                      ),
                    );
                  },
                ),
          )
        ],
      ),
    );
  }
}