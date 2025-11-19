// lib/models/comment.dart
import 'user.dart';

class Comment {
  final int id;
  final User author;
  final int postId;
  final int? parentCommentId;
  final String content;
  final String createdAt;
  final List<Comment>? replies;

  Comment({
    required this.id,
    required this.author,
    required this.postId,
    this.parentCommentId,
    required this.content,
    required this.createdAt,
    this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // --- Penanganan 'author' ---
    final dynamic authorJson = json['author'];
    if (authorJson == null || authorJson is! Map<String, dynamic>) {
      throw Exception('Data Author tidak ada, null, atau bukan Map untuk Komentar ID ${json['id'] ?? 'Unknown'}. Tipe aktual: ${authorJson.runtimeType}');
    }
    final User parsedAuthor = User.fromJson(authorJson);

    // --- Penanganan 'replies' ---
    final List<dynamic>? repliesJsonList = json['replies'] as List<dynamic>?;
    final List<Comment>? parsedReplies = repliesJsonList
        ?.map((replyJson) {
          if (replyJson == null || replyJson is! Map<String, dynamic>) {
            print('Peringatan: Balasan komentar individual bukan objek JSON (Map) atau null. Tipe aktual: ${replyJson.runtimeType}');
            return null;
          }
          return Comment.fromJson(replyJson);
        })
        .where((reply) => reply != null)
        .cast<Comment>()
        .toList();

    return Comment(
      // PERBAIKAN PENTING: Tangani 'id' jika dikirim sebagai String atau int
      id: (json['id'] is String) ? int.parse(json['id']) : json['id'] as int,
      author: parsedAuthor,
      // PERBAIKAN PENTING: Tangani 'post_id' jika dikirim sebagai String atau int
      // Asumsi API menggunakan 'post_id' (snake_case)
      postId: (json['post_id'] is String) ? int.parse(json['post_id']) : json['post_id'] as int,
      // PERBAIKAN PENTING: Tangani 'parent_comment_id' jika dikirim sebagai String, int, atau null
      parentCommentId: (json['parent_comment_id'] != null && json['parent_comment_id'] is String)
          ? int.parse(json['parent_comment_id'])
          : json['parent_comment_id'] as int?,
      content: json['content'] as String,
      createdAt: json['created_at'] as String,
      replies: parsedReplies,
    );
  }
}