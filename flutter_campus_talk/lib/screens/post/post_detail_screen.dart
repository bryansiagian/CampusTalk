import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../models/post.dart';
import '../../models/comment.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final ApiServices _apiServices = ApiServices();
  late Future<Post> _postDetailFuture;
  late Future<List<Comment>> _commentsFuture;
  final TextEditingController _commentController = TextEditingController();
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _fetchPostData();
  }

  void _fetchPostData() {
    setState(() {
      _postDetailFuture = _apiServices.getPostDetail(widget.postId);
      _commentsFuture = _apiServices.getCommentsForPost(widget.postId);
    });
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Komentar tidak boleh kosong.'))
      );
      return;
    }
    try {
      await _apiServices.addComment(widget.postId, _commentController.text);
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Komentar berhasil ditambahkan'))
      );
      _fetchPostData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menemukan komentar: ${e.toString}'))
      );
    }
  }

  Future<void> _toggleLike(bool isLiked) async {
    if (_isLiking) return;
    setState(() {
      _isLiking = true;
    });
    try {
      bool success;
      if (isLiked) {
        success = await _apiServices.unlikePost(widget.postId);
      } else {
        success = await _apiServices.likePost(widget.postId);
      }
      if (success) {
        _fetchPostData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui like'))
        );
      } 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'))
      );
    } finally {
      setState(() {
        _isLiking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Postingan', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: FutureBuilder<Post>(
        future: _postDetailFuture,
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: SpinKitFadingCircle(color: Theme.of(context).primaryColor, size: 50.0,));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData)  {
            return Center(child: Text('Postingan tidak ditemukan'));
          } else {
            final post = snapshot.data!;

            bool userHasLiked = false;

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  post.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Oleh: ${post.author.name} - Kategori: ${post.category.name}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Text(
                  post.content,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(userHasLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined, color: userHasLiked ? Colors.blue : Colors.grey),
                      onPressed: _isLiking ? null : () => _toggleLike(userHasLiked),
                    ),
                    Text('${post.totalLikes} Suka'),
                    const SizedBox(width: 24),
                    Icon(Icons.comment_outlined, color: Colors.grey),
                    Text('${post.totalComments} Komentar'),
                  ],
                ),
                const Divider(height: 32),
                Text(
                  'Komentar',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Tambahkan komentar...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        minLines: 1,
                        maxLines: 5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                      onPressed: _addComment,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Comment>>(
                  future: _commentsFuture,
                  builder: (context, commentsSnapshot) {
                    if (commentsSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: SpinKitThreeBounce(color: Theme.of(context).primaryColor, size: 20.0));
                    } else if (commentsSnapshot.hasError) {
                      return Text('Gagal memuat komentar: ${commentsSnapshot.data!.isEmpty}');
                    } else if (!commentsSnapshot.hasData) {
                      return Text('Belum ada komentar');
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: commentsSnapshot.data!.map((comment) => CommentCard(comment: comment)).toList(),
                      );
                    }
                  }
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
  final Comment comment;
  const CommentCard({Key? key, required this.comment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        color: Colors.blue.shade50,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.author.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(comment.content),
              const SizedBox(height: 4),
              Text(
                '${DateTime.parse(comment.createdAt).day}/${DateTime.parse(comment.createdAt).month}/${DateTime.parse(comment.createdAt).year}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),

              if (comment.replies != null && comment.replies!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: comment.replies!.map((reply) => CommentCard(comment: reply)).toList(),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}