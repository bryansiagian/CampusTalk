import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/api_services.dart';
import '../../models/post.dart';
import '../../models/comment_detail.dart';

class AdminPostDetailScreen extends StatefulWidget {
  final int postId;
  final bool isDarkMode; // <--- 1. TERIMA PARAMETER TEMA

  const AdminPostDetailScreen({
    Key? key, 
    required this.postId, 
    required this.isDarkMode // Wajib diisi saat navigasi
  }) : super(key: key);

  @override
  _AdminPostDetailScreenState createState() => _AdminPostDetailScreenState();
}

class _AdminPostDetailScreenState extends State<AdminPostDetailScreen> {
  final ApiServices _apiServices = ApiServices();
  final TextEditingController _adminCommentController = TextEditingController();
  
  late Future<Post> _postFuture;
  List<CommentDetail> _comments = [];
  bool _isLoadingComments = true;

  // --- 2. DEFINISI WARNA DINAMIS (Getter) ---
  bool get _isDark => widget.isDarkMode;

  Color get _backgroundColor => _isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
  Color get _cardColor => _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _primaryTextColor => _isDark ? Colors.white : const Color(0xFF1E293B);
  Color get _secondaryTextColor => _isDark ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _headerColor => _isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B);
  Color get _inputFillColor => _isDark ? const Color(0xFF2C2C2C) : Colors.grey[50]!;
  Color get _dividerColor => _isDark ? Colors.grey[800]! : Colors.grey[200]!;
  Color get _codeBlockColor => _isDark ? const Color(0xFF252525) : Colors.grey[50]!;

  @override
  void initState() {
    super.initState();
    _fetchPost();
  }

  void _fetchPost() {
    _postFuture = _apiServices.getPostDetail(widget.postId);
    _postFuture.then((post) {
      _fetchComments(post.id);
    });
  }

  Future<void> _fetchComments(int postId) async {
    setState(() => _isLoadingComments = true);
    try {
      final data = await _apiServices.getCommentDetails(postId: postId, sortBy: 'oldest');
      if (mounted) {
        setState(() {
          _comments = data;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  // --- ACTIONS ---
  Future<void> _nukePost() async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor, // Sesuaikan bg dialog
        title: Text("Hapus Postingan?", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryTextColor)),
        content: Text("Tindakan ini tidak dapat dibatalkan.", style: TextStyle(color: _secondaryTextColor)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Hapus", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _apiServices.deletePost(widget.postId);
      Navigator.pop(context, true);
    }
  }

  Future<void> _nukeComment(int commentId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text("Hapus Komentar?", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryTextColor)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Hapus", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _apiServices.deleteComment(commentId);
      final post = await _postFuture;
      _fetchComments(post.id);
    }
  }

  Future<void> _postAdminComment() async {
    if (_adminCommentController.text.isEmpty) return;
    await _apiServices.addComment(widget.postId, "[ADMIN]: ${_adminCommentController.text}");
    _adminCommentController.clear();
    final post = await _postFuture;
    _fetchComments(post.id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tanggapan Admin terkirim")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text("INSPEKSI KONTEN", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 16, color: Colors.white)),
        backgroundColor: _headerColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Tombol back putih
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: _nukePost,
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
              label: const Text("HAPUS POST", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05)),
            ),
          )
        ],
      ),
      body: FutureBuilder<Post>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: SpinKitCubeGrid(color: _headerColor));
          } else if (!snapshot.hasData) {
            return Center(child: Text("Konten tidak ditemukan / sudah dihapus.", style: TextStyle(color: _secondaryTextColor)));
          } else {
            final post = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 1. DATA POSTINGAN (CARD)
                      Container(
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Meta Info Grid
                              Wrap(
                                spacing: 20,
                                runSpacing: 10,
                                children: [
                                  _buildMetaItem(Icons.tag, "POST ID", "#${post.id}"),
                                  _buildMetaItem(Icons.person, "AUTHOR", post.author.name),
                                  _buildMetaItem(Icons.category, "CATEGORY", post.category.name),
                                  _buildMetaItem(Icons.calendar_today, "DATE", post.createdAt.substring(0, 10)),
                                ],
                              ),
                              Divider(height: 30, color: _dividerColor),
                              
                              // Judul
                              Text(
                                post.title, 
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _primaryTextColor)
                              ),
                              const SizedBox(height: 12),
                              
                              // Konten (Monospace)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _codeBlockColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _dividerColor)
                                ),
                                child: Text(
                                  post.content, 
                                  style: TextStyle(fontSize: 14, fontFamily: 'Monospace', color: _primaryTextColor, height: 1.5)
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              // Tags Chips
                              if (post.tags != null && post.tags!.isNotEmpty)
                                Wrap(
                                  spacing: 6,
                                  children: post.tags!.map((t) => Chip(
                                    label: Text(t.name, style: TextStyle(fontSize: 11, color: _isDark ? Colors.blue[200] : Colors.blueGrey)), 
                                    backgroundColor: _isDark ? Colors.blueGrey.withOpacity(0.2) : Colors.blueGrey[50],
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    side: BorderSide.none,
                                  )).toList(),
                                )
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      // Header Log Komentar
                      Row(
                        children: [
                          Icon(Icons.history, size: 20, color: _secondaryTextColor),
                          const SizedBox(width: 8),
                          Text("LOG AKTIVITAS KOMENTAR (${_comments.length})", style: TextStyle(color: _secondaryTextColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 2. LIST KOMENTAR
                      if (_isLoadingComments)
                        const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                      else if (_comments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _dividerColor)
                          ),
                          child: Center(child: Text("Tidak ada aktivitas komentar.", style: TextStyle(color: _secondaryTextColor))),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _comments.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final c = _comments[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: _cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _dividerColor)
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: _isDark ? Colors.grey[700] : Colors.blueGrey[50],
                                  child: Text(
                                    c.commenterName[0].toUpperCase(), 
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _isDark ? Colors.white : const Color(0xFF1E293B))
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(c.commenterName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _primaryTextColor)),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _isDark ? Colors.black26 : Colors.grey[100], 
                                        borderRadius: BorderRadius.circular(4)
                                      ),
                                      child: Text("ID: ${c.commenterId}", style: TextStyle(fontSize: 9, color: _secondaryTextColor)),
                                    )
                                  ],
                                ),
                                subtitle: Text(c.commentContent, style: TextStyle(fontSize: 13, color: _primaryTextColor.withOpacity(0.9))),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  tooltip: "Hapus Paksa",
                                  onPressed: () => _nukeComment(c.commentId),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),

                // 3. ADMIN ACTION BAR (Sticky Bottom)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: _headerColor, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _adminCommentController,
                          style: TextStyle(color: _primaryTextColor), // Warna teks input
                          decoration: InputDecoration(
                            hintText: "Tulis tindakan admin...",
                            hintStyle: TextStyle(color: _secondaryTextColor),
                            filled: true,
                            fillColor: _inputFillColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _postAdminComment,
                        icon: const Icon(Icons.send_rounded),
                        color: _headerColor, // Kirim pake warna tema header
                        tooltip: "Kirim",
                      )
                    ],
                  ),
                )
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _secondaryTextColor),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _secondaryTextColor)),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primaryTextColor)),
          ],
        )
      ],
    );
  }     
}