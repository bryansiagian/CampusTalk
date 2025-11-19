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
    return Comment(
      id: json['id'], 
      author: User.fromJson(json['author']), 
      postId: json['postId'], 
      parentCommentId: json['parent_comment_id'],
      content: json['content'], 
      createdAt: json['created_at'],
      replies: (json['replies'] as List<dynamic>?)
        ?.map((replyJson) => Comment.fromJson(replyJson))
        .toList(),
    );
  }
}