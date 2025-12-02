import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/api_services.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../models/comment_detail.dart';
import '../auth/login_screen.dart';
import '../post/post_detail_screen.dart';
import 'admin_post_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final ApiServices _apiServices = ApiServices();
  late TabController _tabController;

  // --- STATE TEMA ---
  bool _isDarkMode = false; // Default Light Mode

  // --- COLOR PALETTE DINAMIS ---
  // Menggunakan Getter agar warna berubah saat setState dipanggil
  Color get _backgroundColor => _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
  Color get _cardColor => _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _textColorPrimary => _isDarkMode ? Colors.white : const Color(0xFF1E293B);
  Color get _textColorSecondary => _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _appBarColor => _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFF1E293B);
  Color get _dividerColor => _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
  
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
    await Future.wait([_fetchPosts(), _fetchUsers(), _fetchReports()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchPosts() async {
    try {
      final posts = await _apiServices.getPosts(sortBy: 'latest');
      if (mounted) setState(() => _posts = posts);
    } catch (e) { print(e); }
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await _apiServices.getPendingUsers();
      if (mounted) setState(() => _pendingUsers = users);
    } catch (e) { print(e); }
  }

  Future<void> _fetchReports() async {
    try {
      final reports = await _apiServices.getReports();
      if (mounted) setState(() => _reports = reports);
    } catch (e) { print(e); }
  }

  // --- ACTIONS ---
  Future<void> _deletePost(int postId) async {
    bool confirm = await _showConfirmDialog("Hapus Postingan?", "Tindakan ini permanen.", isDestructive: true);
    if (confirm) {
      await _apiServices.deletePost(postId);
      _refreshAll();
      _showSnackbar("Postingan dihapus", Colors.green);
    }
  }

  Future<void> _approveUser(int uid) async {
    await _apiServices.approveUser(uid);
    _fetchUsers();
    _showSnackbar("User disetujui", Colors.green);
  }

  Future<void> _rejectUser(int uid) async {
    await _apiServices.rejectUser(uid);
    _fetchUsers();
    _showSnackbar("User ditolak", Colors.red);
  }

  Future<void> _dismissReport(int reportId) async {
    await _apiServices.dismissReport(reportId);
    _fetchReports();
    _showSnackbar("Laporan diabaikan", Colors.grey);
  }

  Future<void> _handleContentDeletion(Map<String, dynamic> report) async {
    bool confirm = await _showConfirmDialog("Hapus Konten & Laporan?", "Konten akan dihapus permanen.", isDestructive: true);
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
      _showSnackbar("Konten dieksekusi", Colors.green);
      _refreshAll();
    }
  }

  void _handleLogout() async {
     await _apiServices.logout();
     if (mounted) {
       Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
     }
  }

  void _showCommentManager(int postId, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Pass status Dark Mode ke Modal
      builder: (context) => AdminCommentModal(postId: postId, postTitle: title, isDarkMode: _isDarkMode),
    );
  }

  void _navigateToDetail(int postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminPostDetailScreen(
          postId: postId, 
          isDarkMode: _isDarkMode, // <--- KIRIM STATUS TEMA DI SINI
        ), 
      ),
    ).then((_) {
      _refreshAll(); 
    });
  }

  // --- UI HELPERS ---
  Future<bool> _showConfirmDialog(String title, String content, {bool isDestructive = false}) async {
    return await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDestructive ? Colors.red : _textColorPrimary)),
        content: Text(content, style: TextStyle(color: _textColorSecondary)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(isDestructive ? "Hapus" : "Ya", style: const TextStyle(color: Colors.white))
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _appBarColor,
        elevation: 0,
        title: Row(
          children: [
            // --- PERUBAHAN DI SINI ---
            const Icon(Icons.school, color: Colors.white, size: 28), // Icon Topi Wisuda
            const SizedBox(width: 12),
            const Text(
              "ADMIN", // Judul Baru
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                letterSpacing: 1, 
                fontSize: 18, 
                color: Colors.white
              )
            ),
            // -------------------------
          ],
        ),
        actions: [
          // ... actions tetap sama ...
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
            tooltip: "Ganti Tema",
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _refreshAll),
          IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: _handleLogout),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: "KONTEN"),
            Tab(text: "APPROVAL"),
            Tab(text: "LAPORAN"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContentTab(),
          _buildUserTab(),
          _buildReportTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: KONTEN
  // ===========================================================================
  Widget _buildContentTab() {
    if (_isLoading) return Center(child: SpinKitCubeGrid(color: _isDarkMode ? Colors.white : const Color(0xFF1E293B)));
    if (_posts.isEmpty) return _buildEmptyState("Tidak ada konten.", Icons.dashboard_customize_outlined);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: InkWell(
            onTap: () => _navigateToDetail(post.id),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        child: Text(
                          post.author.name.isNotEmpty ? post.author.name[0].toUpperCase() : "?", 
                          style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold)
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.author.name, 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textColorPrimary)
                            ),
                            Text("ID: ${post.id}", style: TextStyle(fontSize: 12, color: _textColorSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isDarkMode ? Colors.blue.withOpacity(0.2) : Colors.blue[50], 
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text(post.category.name, style: TextStyle(color: Colors.blue[400], fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
                
                // 2. Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title, 
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w800, 
                          color: _textColorPrimary,
                          height: 1.2
                        ), 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.content, 
                        style: TextStyle(color: _textColorSecondary, height: 1.4, fontSize: 13), 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    border: Border(top: BorderSide(color: _dividerColor))
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Row(
                          children: [
                            Icon(Icons.comment, size: 16, color: _textColorSecondary),
                            const SizedBox(width: 4),
                            Text("${post.totalComments}", style: TextStyle(fontWeight: FontWeight.bold, color: _textColorSecondary)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _showCommentManager(post.id, post.title),
                        icon: Icon(Icons.forum_outlined, size: 18, color: _isDarkMode ? Colors.lightBlueAccent : const Color(0xFF1E293B)),
                        label: Text("Komentar", style: TextStyle(color: _isDarkMode ? Colors.lightBlueAccent : const Color(0xFF1E293B))),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _deletePost(post.id),
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white),
                        label: const Text("Hapus", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 2: APPROVAL
  // ===========================================================================
  Widget _buildUserTab() {
    if (_isLoading) return Center(child: SpinKitCubeGrid(color: _isDarkMode ? Colors.white : const Color(0xFF1E293B)));
    if (_pendingUsers.isEmpty) return _buildEmptyState("Semua user sudah disetujui.", Icons.check_circle_outline);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingUsers.length,
      separatorBuilder: (_,__) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = _pendingUsers[index];
        return Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: _isDarkMode ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50,
              child: Text(user.name[0].toUpperCase(), style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ),
            title: Text(user.name, style: TextStyle(fontWeight: FontWeight.bold, color: _textColorPrimary)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email, style: TextStyle(color: _textColorSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                  child: const Text("Pending Approval", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionButton(Icons.close, Colors.red.withOpacity(0.1), Colors.red, () => _rejectUser(user.id)),
                const SizedBox(width: 8),
                _actionButton(Icons.check, Colors.green.withOpacity(0.1), Colors.green, () => _approveUser(user.id)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionButton(IconData icon, Color bg, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  // ===========================================================================
  // TAB 3: REPORTS
  // ===========================================================================
  Widget _buildReportTab() {
    if (_isLoading) return Center(child: SpinKitCubeGrid(color: _isDarkMode ? Colors.white : const Color(0xFF1E293B)));
    if (_reports.isEmpty) return _buildEmptyState("Tidak ada laporan.", Icons.security);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final r = _reports[index];
        final typeString = r['reportable_type'] ?? '';
        final type = typeString.toString().contains('Post') ? 'Postingan' : 'Komentar';
        final contentId = r['reportable_id'];
        final reporterName = r['reporter'] != null ? r['reporter']['name'] : 'Unknown';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border(left: const BorderSide(color: Colors.redAccent, width: 4)), 
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Text("Laporan $type #$contentId", style: TextStyle(fontWeight: FontWeight.bold, color: _textColorPrimary)),
                      ],
                    ),
                    Text(r['created_at'].toString().substring(0, 10), style: TextStyle(color: _textColorSecondary, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _isDarkMode ? Colors.black26 : Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Alasan: ${r['reason']}", style: TextStyle(fontWeight: FontWeight.w600, color: _textColorPrimary)),
                      const SizedBox(height: 4),
                      Text("Pelapor: $reporterName", style: TextStyle(color: _textColorSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _dismissReport(r['id']),
                      child: Text("Abaikan", style: TextStyle(color: _textColorSecondary)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _handleContentDeletion(r),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent, 
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                      icon: const Icon(Icons.delete_forever, size: 16),
                      label: const Text("Hapus Konten"),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ============================================================================
// MODAL ADMIN COMMENT (SUPPORT DARK MODE)
// ============================================================================
class AdminCommentModal extends StatefulWidget {
  final int postId;
  final String postTitle;
  final bool isDarkMode; // Terima status tema
  const AdminCommentModal({Key? key, required this.postId, required this.postTitle, required this.isDarkMode}) : super(key: key);

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
    // Definisi Warna Lokal Modal
    final bgColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = widget.isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final headerColor = widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFF1E293B);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[500], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.security, size: 20, color: headerColor), // Pakai warna gelap/terang header
                const SizedBox(width: 8),
                Expanded(child: Text("Moderasi Komentar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor))),
                IconButton(icon: Icon(Icons.close, color: textColor), onPressed: () => Navigator.pop(context))
              ],
            ),
          ),
          Divider(height: 1, color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[200]),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator()) 
              : _comments.isEmpty
                  ? Center(child: Text("Tidak ada komentar.", style: TextStyle(color: subTextColor)))
                  : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _comments.length,
                  separatorBuilder: (_,__) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final c = _comments[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!)
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: widget.isDarkMode ? Colors.grey[700] : Colors.blueGrey[100],
                            child: Text(c.commenterName[0].toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(c.commenterName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                                    Text("ID: ${c.commentId}", style: TextStyle(fontSize: 10, color: subTextColor)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(c.commentContent, style: TextStyle(color: textColor)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                            onPressed: () => _del(c.commentId),
                            tooltip: "Hapus Permanen",
                          ),
                        ],
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