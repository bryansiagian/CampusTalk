import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/api_services.dart';
import '../../models/post.dart';
import '../../models/comment_detail.dart';
import '../../models/user.dart';
import '../post/edit_post_screen.dart';
import '../profile/profile_screen.dart'; // <--- 1. IMPORT PROFILE SCREEN

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
  
  // MAP PENTING: Menyimpan ID Komentar -> Nama user yang dibalas
  final Map<int, String> _replyingToUserMap = {}; 
  
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
          _totalLikesFromFunction = post.totalLikesViaFunction;
        });
        _fetchAndStructureComments(post.id);
      }
    });
  }

  // --- LOGIKA UTAMA: MERATAKAN TREE & MENCATAT "MEMBALAS SIAPA" ---
  Future<void> _fetchAndStructureComments(int postId) async {
    setState(() => _isLoadingComments = true);
    try {
      List<CommentDetail> flatComments = await _apiServices.getCommentDetails(
        postId: postId, 
        sortBy: 'oldest' 
      );

      List<CommentDetail> rootComments = [];
      Map<int, CommentDetail> commentMap = {};
      _replyingToUserMap.clear(); // Reset map info balasan

      // 1. Mapping ID ke Object
      for (var c in flatComments) {
        commentMap[c.commentId] = c;
        c.replies = []; 
      }

      // 2. Susun Struktur & Deteksi Balasan
      for (var c in flatComments) {
        if (c.parentCommentId == null) {
          // LEVEL 1: Komentar Utama
          rootComments.add(c);
        } else {
          // LEVEL 2+: Balasan
          CommentDetail? directParent = commentMap[c.parentCommentId];
          
          if (directParent != null) {
            // Cari Induk Paling Atas (Root)
            CommentDetail? ultimateRoot = _findUltimateRoot(directParent, commentMap);
            
            if (ultimateRoot != null) {
              // Masukkan ke list replies milik ROOT (agar tampilan cuma 2 level)
              ultimateRoot.replies.add(c);

              // LOGIKA KETERANGAN "MEMBALAS SIAPA":
              if (directParent.commentId != ultimateRoot.commentId) {
                _replyingToUserMap[c.commentId] = directParent.commenterName;
              }
            }
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

  // Fungsi Rekursif cari Root
  CommentDetail? _findUltimateRoot(CommentDetail current, Map<int, CommentDetail> map) {
    if (current.parentCommentId == null) return current; 
    CommentDetail? parent = map[current.parentCommentId];
    if (parent == null) return null; 
    return _findUltimateRoot(parent, map);
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
      _fetchPostData(); 
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
        Navigator.pop(context);
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
          decoration: const InputDecoration(hintText: "Alasan"),
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

  // --- FUNGSI NAVIGASI KE PROFIL ---
  void _navigateToProfile(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final primaryColor = theme.primaryColor;
    final cardColor = theme.cardTheme.color ?? Colors.white;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Detail Postingan', style: TextStyle(color: Colors.white)),
        centerTitle: true,
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
                        MaterialPageRoute(
                          builder: (context) => EditPostScreen(post: post),
                        ),
                      );
                      if (result == true) _fetchPostData(); 
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
            return Center(child: SpinKitFadingCircle(color: Theme.of(context).primaryColor));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Data tidak ditemukan'));
          } else {
            final post = snapshot.data!;
            bool userHasLiked = _currentUserHasLiked;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // --- HEADER POSTINGAN DENGAN NAVIGASI PROFIL ---
                      Row(
                        children: [
                          // 1. AVATAR (KLIK UNTUK LIHAT PROFIL)
                          InkWell(
                            onTap: () => _navigateToProfile(post.author.id),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: primaryColor,
                              backgroundImage: post.author.profilePictureUrl != null 
                                  ? NetworkImage(_fixImageUrl(post.author.profilePictureUrl!))
                                  : null,
                              child: post.author.profilePictureUrl == null ? Text(post.author.name[0].toUpperCase()) : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // 2. NAMA & KATEGORI
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // NAMA (KLIK UNTUK LIHAT PROFIL)
                                InkWell(
                                  onTap: () => _navigateToProfile(post.author.id),
                                  child: Text(
                                    post.author.name, 
                                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16)
                                  ),
                                ),
                                Text(post.category.name, style: TextStyle(color: textSecondary, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // ---------------------------------------------
                      
                      const SizedBox(height: 12),
                      
                      if(post.title.isNotEmpty) Text(post.title, style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(post.content, style: TextStyle(color: textPrimary, fontSize: 16, height: 1.5)),
                      const SizedBox(height: 12),

                      if (post.mediaUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _fixImageUrl(post.mediaUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const SizedBox(),
                            ),
                          ),
                        ),

                      if (post.tags != null && post.tags!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: post.tags!.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade100)
                                ),
                                child: Text("#${tag.name}", style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                              );
                            }).toList(),
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Text("${DateTime.parse(post.createdAt).day}/${DateTime.parse(post.createdAt).month}/${DateTime.parse(post.createdAt).year}", style: TextStyle(color: textSecondary, fontSize: 12)),
                            const Spacer(),
                            Icon(Icons.bar_chart_rounded, size: 16, color: textSecondary),
                            Text(" ${post.views} Views", style: TextStyle(color: textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Divider(height: 24, color: theme.dividerColor),

                      Row(children: [
                         IconButton(
                            icon: Icon(userHasLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined, color: userHasLiked ? Colors.blue : Colors.grey),
                            onPressed: _isLiking ? null : () => _toggleLikePost(userHasLiked),
                          ),
                         Text('$_totalLikesFromFunction Suka', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                         const SizedBox(width: 24),
                         const Icon(Icons.comment_outlined, color: Colors.grey),
                         const SizedBox(width: 4),
                         Text('$_currentTotalComments Komentar', style: TextStyle(color: textPrimary)),
                      ]),
                      const Divider(height: 32),
                      
                      Text('Komentar', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      // LIST KOMENTAR
                      if (_structuredComments.isEmpty)
                        Text("Belum ada komentar.", style: TextStyle(color: textSecondary))
                      else
                         Column(
                           children: _structuredComments.map((comment) => 
                             CommentCard(
                               comment: comment, 
                               currentUser: _currentUser, 
                               onReply: _startReplying,
                               onDelete: _deleteComment,
                               onRefresh: () => _fetchAndStructureComments(post.id),
                               theme: theme,
                               // KIRIM MAP KE WIDGET ANAK
                               replyingMap: _replyingToUserMap, 
                             )
                           ).toList(),
                         ),
                    ],
                  ),
                ),
                // Input Area
                Container(
                  decoration: BoxDecoration(color: cardColor, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))]),
                  child: Column(
                    children: [
                      if (_replyingToName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Row(children: [
                            Icon(Icons.reply, size: 16, color: primaryColor),
                            const SizedBox(width: 8),
                            Expanded(child: Text("Membalas $_replyingToName...", style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold))),
                            GestureDetector(onTap: _cancelReply, child: const Icon(Icons.close, size: 20, color: Colors.red))
                          ]),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(children: [
                          Expanded(child: TextField(
                            controller: _commentController,
                            focusNode: _commentFocusNode,
                            style: TextStyle(color: textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Tulis komentar...',
                              hintStyle: TextStyle(color: textSecondary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              filled: true,
                              fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
                            ),
                          )),
                          const SizedBox(width: 8),
                          IconButton(icon: Icon(Icons.send, color: primaryColor), onPressed: _addComment),
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

class CommentCard extends StatelessWidget {
  final CommentDetail comment;
  final User? currentUser;
  final Function(int, String) onReply;
  final Function(int) onDelete;
  final VoidCallback onRefresh;
  final ThemeData theme;
  final Map<int, String>? replyingMap; // TERIMA MAP DARI PARENT

  const CommentCard({
    Key? key, 
    required this.comment, 
    required this.currentUser, 
    required this.onReply, 
    required this.onDelete,
    required this.onRefresh,
    required this.theme,
    this.replyingMap,
  }) : super(key: key);

  Future<void> _toggleLike() async {
    await ApiServices().toggleCommentLike(comment.commentId);
    onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final primaryColor = theme.primaryColor;

    bool canDelete = false;
    if (currentUser != null) {
      if (currentUser!.id == comment.commenterId || currentUser!.isAdmin) canDelete = true;
    }

    // CEK APAKAH KOMENTAR INI MEMBALAS SESEORANG
    String? replyName;
    if (replyingMap != null && replyingMap!.containsKey(comment.commentId)) {
      replyName = replyingMap![comment.commentId];
    }

    return Column(
      children: [
        // --- TAMPILAN KOMENTAR UTAMA ---
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16, 
                child: Text(comment.commenterName.isNotEmpty ? comment.commenterName[0].toUpperCase() : "?", style: const TextStyle(fontSize: 12))
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100], 
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(comment.commenterName, style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                              if (canDelete)
                                GestureDetector(
                                  onTap: () => onDelete(comment.commentId),
                                  child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                )
                            ],
                          ),
                          
                          // --- TAMPILKAN "Membalas @Nama" JIKA ADA ---
                          RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 14, color: textPrimary, fontFamily: 'Roboto'),
                              children: [
                                if (replyName != null)
                                  TextSpan(
                                    text: "@$replyName ", 
                                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)
                                  ),
                                TextSpan(text: comment.commentContent),
                              ],
                            ),
                          ),
                          // ----------------------------------------
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                      child: Row(
                        children: [
                          Text('${comment.commentCreatedAt.day}/${comment.commentCreatedAt.month}', style: TextStyle(fontSize: 11, color: textSecondary)),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => onReply(comment.commentId, comment.commenterName),
                            child: const Text("Balas", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: _toggleLike,
                            child: Row(children: [
                              const Icon(Icons.favorite, size: 12, color: Colors.pinkAccent),
                              const SizedBox(width: 2),
                              Text("${comment.totalLikes}", style: const TextStyle(fontSize: 12)),
                            ]),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // --- RENDER BALASAN (FLAT LEVEL 2) ---
        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40.0), // Indentasi untuk anak
            child: Column(
              children: comment.replies.map((reply) => 
                CommentCard(
                  comment: reply, 
                  currentUser: currentUser, 
                  onReply: onReply, 
                  onDelete: onDelete, 
                  onRefresh: onRefresh, 
                  theme: theme,
                  replyingMap: replyingMap, // Teruskan Map ke anak
                )
              ).toList()
            ),
          ),
      ],
    );
  }
}