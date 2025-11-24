// lib/models/notification.dart
import 'post.dart';
import 'user.dart';

class AppNotification {
  final int id;
  final String type; // e.g., 'like_post', 'comment_post', 'reply_comment'
  final String message;
  final Post? relatedPost; // Postingan yang terkait dengan notifikasi
  final User? sender; // Pengguna yang memicu notifikasi
  final bool isRead;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.message,
    this.relatedPost,
    this.sender,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    Post? parsedRelatedPost;
    // Backend sudah mengubah 'source' menjadi 'related_post'
    if (json['related_post'] != null && json['related_post'] is Map<String, dynamic>) {
      parsedRelatedPost = Post.fromJson(json['related_post'] as Map<String, dynamic>);
    }

    User? parsedSender;
    // Backend sudah memuat 'sender'
    if (json['sender'] != null && json['sender'] is Map<String, dynamic>) {
      parsedSender = User.fromJson(json['sender'] as Map<String, dynamic>);
    }

    return AppNotification(
      id: (json['id'] is String) ? int.parse(json['id']) : json['id'] as int,
      type: json['type'] as String,
      message: json['message'] as String,
      relatedPost: parsedRelatedPost,
      sender: parsedSender,
      isRead: json['is_read'] as bool,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'related_post': relatedPost?.toJson(),
      'sender': sender?.toJson(),
      'is_read': isRead,
      'created_at': createdAt,
    };
  }
}