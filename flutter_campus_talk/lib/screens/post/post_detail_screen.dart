import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/api_services.dart';
import '../../models/post.dart';
import '../../models/comment_detail.dart';
import '../../models/user.dart';
import '../post/edit_screen.dart'; // Pastikan nama file sesuai

class PostDetailScreen extends StatefulWidget {
  final int postId;
  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final ApiServices _apiServices = ApiServices();
  late Future<Post> _postDetailFuture;
  User? _currentUser;
  
  List<CommentDetail> _structuredComments = [];
  bool _isLoadingComments = true;
  
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode(); 

  bool _isLiking = false;
  bool _currentUserHasLiked = false;
  int _currentTotalComments = 0;
  int _totalLikesFromFunction = 0;
  
  int? _replyingToId;       
  String? _replyingToName;  

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _fetchPostData();
  }

  Future<void> _loadCurrentUser() async {
    try {
      User? user = await _apiServices.getCurrentUser();
      if (mounted) setState(() => _currentUser = user);
    } catch (e) {
      print("Gagal memuat user: $e");
    }
  }

  void _fetchPostData() {
    _postDetailFuture = _apiServices.getPostDetail(widget.postId);
    _postDetailFuture.then((post) {
      if (mounted) {
        setState(() {
          _currentUserHasLiked = post.isLikedByCurrentUser;
          _currentTotalComments = post.totalComments;
          _totalLikesFromFunction = post.totalLikesViaFunction; // Pastikan model Post punya ini
        });
        _fetchAndStructureComments(post.id);
      }
    });
  }

  Future<void> _fetchAndStructureComments(int postId) async {
    setState(() => _isLoadingComments = true);
    try {
      List<CommentDetail> flatComments = await _apiServices.getCommentDetails(
        postId: postId, 
        sortBy: 'oldest'
      );

      // Logika menyusun komentar (Parent -> Child)
      List<CommentDetail> rootComments = [];
      Map<int, CommentDetail> commentMap = {};

      for (var c in flatComments) {
        commentMap[c.commentId] = c;
        c.replies = [];
      }

      for (var c in flatComments) {
        if (c.parentCommentId == null) {
          rootComments.add(c);
        } else {
          if (commentMap.containsKey(c.parentCommentId)) {
            commentMap[c.parentCommentId]!.replies.add(c);
          }
        }
      }

      if (mounted) {
        setState(() {
          _structuredComments = rootComments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;
    try {
      await _apiServices.addComment(
        widget.postId, 
        _commentController.text, 
        parentCommentId: _replyingToId
      );
      _commentController.clear();
      _cancelReply(); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Komentar terkirim')));
      _fetchPostData(); // Refresh data untuk update jumlah komentar
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _deletePost() async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Postingan?"),
        content: const Text("Tindakan ini permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await _apiServices.deletePost(widget.postId);
      if (success) {
        Navigator.pop(context); // Tutup screen
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Postingan dihapus.")));
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Komentar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await _apiServices.deleteComment(commentId);
      if (success) _fetchPostData();
    }
  }

  Future<void> _toggleLikePost(bool isLiked) async {
    if (_isLiking) return;
    setState(() { _isLiking = true; });
    try {
      bool success;
      if (isLiked) {
        success = await _apiServices.unlikePost(widget.postId);
      } else {
        success = await _apiServices.likePost(widget.postId);
      }
      if (success) _fetchPostData();
    } catch (e) {
      print(e);
    } finally {
      setState(() { _isLiking = false; });
    }
  }

  Future<void> _reportPost() async {
    final reasonController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Laporkan Postingan"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: "Alasan (misal: spam, kasar)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isNotEmpty) {
                await _apiServices.reportContent('post', widget.postId, reasonController.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Laporan terkirim")));
              }
            },
            child: const Text("Lapor"),
          )
        ],
      ),
    );
  }

  void _startReplying(int commentId, String userName) {
    setState(() {
      _replyingToId = commentId;
      _replyingToName = userName;
    });
    FocusScope.of(context).requestFocus(_commentFocusNode);
  }

  void _cancelReply() {
    setState(() {
      _replyingToId = null;
      _replyingToName = null;
    });
    FocusScope.of(context).unfocus();
  }

  // Helper Warna Avatar
  Color _getAvatarColor(String name) {
    if (name.isEmpty) return Colors.blue;
    return Colors.primaries[name.codeUnitAt(0) % Colors.primaries.length];
  }

  // Helper Waktu
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
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background putih sesuai Figma
      appBar: AppBar(
        title: const Text('Detail Postingan', style: TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.blue, // AppBar Biru
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          FutureBuilder<Post>(
            future: _postDetailFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && _currentUser != null) {
                final post = snapshot.data!;
                bool isOwner = post.author.id == _currentUser!.id;
                bool isAdmin = _currentUser!.isAdmin;
                
                return PopupMenuButton<String>(
                  onSelected: (val) async {
                    if (val == 'delete') _deletePost();
                    if (val == 'report') _reportPost();
                    
                    if (val == 'edit') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditPostScreen(post: post)),
                      );
                      // Jika kembali dengan 'deleted', tutup juga screen ini
                      if (result == 'deleted') {
                        Navigator.pop(context, true);
                      } else if (result == true) {
                        _fetchPostData(); 
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    if (isOwner)
                      const PopupMenuItem(value: 'edit', child: Text("Edit Postingan")),
                    if (isOwner || isAdmin)
                      const PopupMenuItem(value: 'delete', child: Text("Hapus Postingan", style: TextStyle(color: Colors.red))),
                    if (!isOwner)
                      const PopupMenuItem(value: 'report', child: Text("Laporkan Postingan")),
                  ],
                );
              }
              return const SizedBox();
            },
          )
        ],
      ),
      body: FutureBuilder<Post>(
        future: _postDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: SpinKitFadingCircle(color: Colors.blue));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Data tidak ditemukan'));
          } else {
            final post = snapshot.data!;
            bool userHasLiked = _currentUserHasLiked;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20.0),
                    children: [
                      // --- HEADER USER ---
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: _getAvatarColor(post.author.name),
                            child: Text(post.author.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.author.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(_calculateTimeAgo(post.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                          ),
                          // Badge Kategori
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(post.category.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // --- KONTEN POSTINGAN ---
                      Text(post.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(post.content, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
                      const SizedBox(height: 16),

                      // --- TAGS ---
                      if (post.tags != null && post.tags!.isNotEmpty)
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: post.tags!.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                "#${tag.name}", 
                                style: TextStyle(color: Colors.blue[800], fontSize: 12, fontWeight: FontWeight.w600)
                              ),
                            );
                          }).toList(),
                        ),
                      
                      const SizedBox(height: 20),

                      // --- STATS ROW (Like & Comment) ---
                      Row(
                        children: [
                          InkWell(
                            onTap: _isLiking ? null : () => _toggleLikePost(userHasLiked),
                            borderRadius: BorderRadius.circular(5),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Row(
                                children: [
                                  Icon(
                                    userHasLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined, 
                                    color: userHasLiked ? Colors.blue : Colors.grey[600],
                                    size: 20
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "$_totalLikesFromFunction Suka", 
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      color: userHasLiked ? Colors.blue : Colors.grey[700]
                                    )
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Row(
                            children: [
                              Icon(Icons.chat_bubble_outline, color: Colors.grey[600], size: 20),
                              const SizedBox(width: 6),
                              Text("$_currentTotalComments Komentar", style: TextStyle(color: Colors.grey[700])),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 10),

                      // --- HEADER KOMENTAR ---
                      Text('Komentar', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      if (_structuredComments.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text("Belum ada komentar.", style: TextStyle(color: Colors.grey[500])),
                          ),
                        )
                      else
                         Column(
                           children: _structuredComments.map((comment) => 
                             CommentCard(
                               comment: comment, 
                               currentUser: _currentUser, 
                               onReply: _startReplying,
                               onDelete: _deleteComment,
                               onRefresh: () => _fetchAndStructureComments(post.id),
                             )
                           ).toList(),
                         ),
                      
                      // Spacer agar tidak tertutup input field
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
                
                // --- INPUT KOMENTAR (Sticky Bottom) ---
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_replyingToName != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.blue[50],
                          child: Row(children: [
                            const Icon(Icons.reply, size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(child: Text("Membalas $_replyingToName...", style: TextStyle(color: Colors.blue[800], fontSize: 12))),
                            GestureDetector(onTap: _cancelReply, child: const Icon(Icons.close, size: 18, color: Colors.blue))
                          ]),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(children: [
                          Expanded(child: TextField(
                            controller: _commentController,
                            focusNode: _commentFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Tulis komentar...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          )),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: _addComment),
                          ),
                        ]),
                      ),
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
}

// --- WIDGET KOMENTAR ---
class CommentCard extends StatelessWidget {
  final CommentDetail comment;
  final User? currentUser;
  final Function(int, String) onReply;
  final Function(int) onDelete;
  final VoidCallback onRefresh;

  const CommentCard({
    Key? key, 
    required this.comment, 
    required this.currentUser, 
    required this.onReply, 
    required this.onDelete,
    required this.onRefresh,
  }) : super(key: key);

  Future<void> _toggleLike(BuildContext context) async {
    await ApiServices().toggleCommentLike(comment.commentId);
    onRefresh();
  }

  void _showReportDialog(BuildContext context) {
    // ... logic report sama seperti sebelumnya ...
  }

  // Helper Warna Avatar
  Color _getAvatarColor(String name) {
    if (name.isEmpty) return Colors.blue;
    return Colors.primaries[name.codeUnitAt(0) % Colors.primaries.length];
  }

  @override
  Widget build(BuildContext context) {
    bool canDelete = false;
    bool isOwner = false;
    if (currentUser != null) {
      isOwner = currentUser!.id == comment.commenterId;
      if (isOwner || currentUser!.isAdmin) canDelete = true;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _getAvatarColor(comment.commenterName),
                child: Text(comment.commenterName[0].toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.white)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bubble Komentar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50], // Abu sangat muda
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        border: Border.all(color: Colors.grey[200]!)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(comment.commenterName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              
                              // Menu Kebab Kecil untuk Report/Delete
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.more_horiz, size: 16, color: Colors.grey),
                                  onSelected: (val) {
                                    if (val == 'delete') onDelete(comment.commentId);
                                  },
                                  itemBuilder: (context) => [
                                    if (canDelete)
                                      const PopupMenuItem(value: 'delete', child: Text("Hapus", style: TextStyle(color: Colors.red, fontSize: 12))),
                                    if (!isOwner)
                                      const PopupMenuItem(value: 'report', child: Text("Laporkan", style: TextStyle(fontSize: 12))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(comment.commentContent, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                        ],
                      ),
                    ),
                    
                    // Footer Komentar (Like, Reply, Time)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, top: 6.0),
                      child: Row(
                        children: [
                          // Tanggal
                          Text(
                            '${comment.commentCreatedAt.day}/${comment.commentCreatedAt.month}', 
                            style: TextStyle(fontSize: 10, color: Colors.grey[500])
                          ),
                          const SizedBox(width: 12),
                          
                          // Tombol Balas
                          InkWell(
                            onTap: () => onReply(comment.commentId, comment.commenterName),
                            child: const Text("Balas", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                          ),
                          
                          const Spacer(),

                          // Like Komentar
                          InkWell(
                            onTap: () => _toggleLike(context),
                            child: Row(
                              children: [
                                Icon(Icons.favorite, size: 12, color: comment.totalLikes > 0 ? Colors.pinkAccent : Colors.grey[300]),
                                const SizedBox(width: 4),
                                if (comment.totalLikes > 0)
                                  Text("${comment.totalLikes}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Render Replies (Recursion)
        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40.0), // Indentasi untuk balasan
            child: Column(
              children: comment.replies.map((reply) => 
                CommentCard(
                  comment: reply, 
                  currentUser: currentUser, 
                  onReply: onReply, 
                  onDelete: onDelete,
                  onRefresh: onRefresh,
                )
              ).toList()
            ),
          ),
      ],
    );
  }
}