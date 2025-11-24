import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/api_services.dart';
import '../../models/post.dart';
import '../../models/comment_detail.dart';
import '../../models/user.dart';
import '../post/edit_screen.dart'; // Pastikan import EditScreen benar

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
          _totalLikesFromFunction = post.totalLikesViaFunction;
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

  // --- REPORT POST ---
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    
                    // --- LOGIKA EDIT ---
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
                      Text(post.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Oleh: ${post.author.name} • ${post.category.name}', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      Text(post.content, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 16),

                      // --- BAGIAN TAGS (BARU) ---
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
                                child: Text(
                                  "#${tag.name}", 
                                  style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.bold)
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      // --------------------------

                      Row(children: [
                         IconButton(
                            icon: Icon(userHasLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined, color: userHasLiked ? Colors.blue : Colors.grey),
                            onPressed: _isLiking ? null : () => _toggleLikePost(userHasLiked),
                          ),
                         Text('$_totalLikesFromFunction Suka', style: const TextStyle(fontWeight: FontWeight.bold)),
                         const SizedBox(width: 24),
                         const Icon(Icons.comment_outlined, color: Colors.grey),
                         const SizedBox(width: 4),
                         Text('$_currentTotalComments Komentar'),
                      ]),
                      const Divider(height: 32),
                      Text('Komentar', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (_structuredComments.isEmpty)
                        const Text("Belum ada komentar.")
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
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))]),
                  child: Column(
                    children: [
                      if (_replyingToName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.grey.shade200,
                          child: Row(children: [
                            const Icon(Icons.reply, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text("Membalas $_replyingToName...")),
                            GestureDetector(onTap: _cancelReply, child: const Icon(Icons.close, size: 20, color: Colors.red))
                          ]),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(children: [
                          Expanded(child: TextField(
                            controller: _commentController,
                            focusNode: _commentFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Tulis komentar...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          )),
                          const SizedBox(width: 8),
                          IconButton(icon: const Icon(Icons.send), onPressed: _addComment),
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
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Laporkan Komentar"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: "Alasan"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isNotEmpty) {
                await ApiServices().reportContent('comment', comment.commentId, reasonController.text);
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
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(child: Text(comment.commenterName[0].toUpperCase())),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(comment.commenterName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () => _toggleLike(context),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.favorite, size: 14, color: Colors.pinkAccent),
                                          const SizedBox(width: 4),
                                          Text("${comment.totalLikes}", style: const TextStyle(fontSize: 12, color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_horiz, size: 16),
                                    onSelected: (val) {
                                      if (val == 'delete') onDelete(comment.commentId);
                                      if (val == 'report') _showReportDialog(context);
                                    },
                                    itemBuilder: (context) => [
                                      if (canDelete)
                                        const PopupMenuItem(value: 'delete', child: Text("Hapus", style: TextStyle(color: Colors.red))),
                                      if (!isOwner)
                                        const PopupMenuItem(value: 'report', child: Text("Laporkan")),
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                          Text(comment.commentContent),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                      child: Row(
                        children: [
                          Text('${comment.commentCreatedAt.day}/${comment.commentCreatedAt.month}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => onReply(comment.commentId, comment.commenterName),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Text("Balas", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
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