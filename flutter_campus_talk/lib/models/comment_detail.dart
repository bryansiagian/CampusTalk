class CommentDetail {
  final int commentId;
  final String commentContent;
  final int commenterId;   // Pastikan ini ada
  final String commenterName;
  final int postId;        // <--- Tambahkan ini
  final String postTitle;
  final DateTime commentCreatedAt;
  final int? parentCommentId;
  final int totalLikes;
  List<CommentDetail> replies;

  CommentDetail({
    required this.commentId,
    required this.commentContent,
    required this.commenterId,
    required this.commenterName,
    required this.postId, // <--- Tambahkan
    required this.postTitle,
    required this.commentCreatedAt,
    this.parentCommentId,
    required this.totalLikes,
    this.replies = const [],
  });

  factory CommentDetail.fromJson(Map<String, dynamic> json) {
    return CommentDetail(
      commentId: json['comment_id'],
      commentContent: json['comment_content'],
      commenterId: json['commenter_id'], // Jika View DB belum diupdate, ini akan Error NULL
      commenterName: json['commenter_name'],
      postId: json['post_id'], // <--- Ambil dari JSON
      postTitle: json['post_title'],
      commentCreatedAt: DateTime.parse(json['comment_created_at']),
      parentCommentId: json['parent_comment_id'],
      totalLikes: json['total_likes'] ?? 0,
      replies: [],
    );
  }
}