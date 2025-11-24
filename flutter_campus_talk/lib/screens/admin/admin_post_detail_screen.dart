import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/api_services.dart';
import '../../models/post.dart';
import '../../models/comment_detail.dart';

class AdminPostDetailScreen extends StatefulWidget {
  final int postId;
  const AdminPostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _AdminPostDetailScreenState createState() => _AdminPostDetailScreenState();
}

class _AdminPostDetailScreenState extends State<AdminPostDetailScreen> {
  final ApiServices _apiServices = ApiServices();
  final TextEditingController _adminCommentController = TextEditingController();
  
  late Future<Post> _postFuture;
  List<CommentDetail> _comments = [];
  bool _isLoadingComments = true;

  @override
  void initState() {
    super.initState();
    _fetchPost();
  }

  void _fetchPost() {
    _postFuture = _apiServices.getPostDetail(widget.postId);
    _postFuture.then((post) {
      _fetchComments(post.id); // Gunakan ID, bukan Judul
    });
  }

  Future<void> _fetchComments(int postId) async {
    setState(() => _isLoadingComments = true);
    try {
      // Admin melihat semua komentar (flat atau tree terserah, disini kita pakai list agar mudah hapus)
      // Kita ambil 'latest' agar admin melihat yang baru
      final data = await _apiServices.getCommentDetails(postId: postId, sortBy: 'oldest');
      
      if (mounted) {
        setState(() {
          _comments = data; // Admin melihat data mentah (flat) lebih efisien untuk moderasi cepat
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  // FITUR ADMIN: Hapus Postingan
  Future<void> _nukePost() async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("⚠️ HAPUS POSTINGAN?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("Postingan ini dan semua komentarnya akan dihapus permanen dari database."),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("BATAL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("YA, HAPUS", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _apiServices.deletePost(widget.postId);
      Navigator.pop(context, true); // Kembali ke dashboard dengan sinyal refresh
    }
  }

  // FITUR ADMIN: Hapus Komentar
  Future<void> _nukeComment(int commentId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Komentar?", style: TextStyle(color: Colors.red)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus")),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _apiServices.deleteComment(commentId);
      // Refresh komentar
      final post = await _postFuture;
      _fetchComments(post.id);
    }
  }

  // FITUR ADMIN: Balas sebagai Admin
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
      backgroundColor: Colors.grey[200], // Background abu-abu (Kesan teknikal)
      appBar: AppBar(
        title: const Text("INSPEKSI KONTEN", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.blueGrey[900], // Header Gelap
        actions: [
          // Tombol Hapus Besar di Atas
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: _nukePost,
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              label: const Text("HAPUS POST", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(backgroundColor: Colors.white10),
            ),
          )
        ],
      ),
      body: FutureBuilder<Post>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: SpinKitCubeGrid(color: Colors.blueGrey));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Konten tidak ditemukan / sudah dihapus."));
          } else {
            final post = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      // 1. INFORMASI TEKNIS POSTINGAN (Kotak Data)
                      Card(
                        color: Colors.white,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), // Kotak tajam
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMetaRow("POST ID", "#${post.id}"),
                              _buildMetaRow("AUTHOR", "${post.author.name} (ID: ${post.author.id})"),
                              _buildMetaRow("CREATED", post.createdAt),
                              _buildMetaRow("CATEGORY", post.category.name),
                              const Divider(thickness: 2, color: Colors.black12),
                              const SizedBox(height: 8),
                              Text(post.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 8),
                              Text(post.content, style: const TextStyle(fontSize: 15, fontFamily: 'Monospace')), // Font Monospace biar beda
                              const SizedBox(height: 12),
                              // Tags
                              if (post.tags != null)
                                Wrap(
                                  spacing: 4,
                                  children: post.tags!.map((t) => Chip(
                                    label: Text(t.name), 
                                    backgroundColor: Colors.grey[300],
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  )).toList(),
                                )
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        color: Colors.blueGrey[800],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("LOG KOMENTAR (${_comments.length})", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const Icon(Icons.history, color: Colors.white54, size: 18)
                          ],
                        ),
                      ),

                      // 2. LIST KOMENTAR (Tampilan Padat / Log)
                      if (_isLoadingComments)
                        const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                      else if (_comments.isEmpty)
                        const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("Tidak ada aktivitas komentar.")))
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _comments.length,
                          separatorBuilder: (ctx, i) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final c = _comments[index];
                            return Container(
                              color: Colors.white,
                              child: ListTile(
                                dense: true, // Tampilan lebih padat
                                visualDensity: VisualDensity.compact,
                                leading: Text("#${c.commentId}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                title: Row(
                                  children: [
                                    Text(c.commenterName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(width: 5),
                                    Text("(User ID: ${c.commenterId})", style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                                  ],
                                ),
                                subtitle: Text(c.commentContent),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
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

                // 3. ADMIN ACTION BAR
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.blueGrey.shade200, width: 2))
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _adminCommentController,
                          decoration: const InputDecoration(
                            hintText: "Tulis peringatan / balasan admin...",
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[900]),
                        onPressed: _postAdminComment,
                        child: const Icon(Icons.send, color: Colors.white, size: 18),
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

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}