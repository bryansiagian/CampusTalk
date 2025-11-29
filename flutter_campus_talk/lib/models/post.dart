// lib/models/post.dart
import 'user.dart';
import 'category.dart';
import 'tag.dart';

class Post {
  final int id;
  final User author;
  final Category category;
  final String title;
  final String content;
  final int views;
  final String? mediaUrl; // Field baru
  final String? mediaType;
  final int totalLikes; // Ini akan berasal dari 'likes_count' (Eloquent)
  final int totalComments;
  final String createdAt;
  final List<Tag>? tags;
  final bool isLikedByCurrentUser;
  final int totalLikesViaFunction; // <--- PROPERTI BARU UNTUK FUNGSI DB

  Post({
    required this.id,
    required this.author,
    required this.category,
    required this.title,
    required this.content,
    required this.views,
    this.mediaUrl,
    this.mediaType,
    this.totalLikes = 0,
    this.totalComments = 0,
    required this.createdAt,
    this.tags,
    this.isLikedByCurrentUser = false,
    this.totalLikesViaFunction = 0, // <--- DEFAULT VALUE UNTUK PROPERTI BARU
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final dynamic authorJson = json['author'];
    if (authorJson == null || authorJson is! Map<String, dynamic>) {
      // Lebih spesifik jika json['id'] tidak ada
      final postIdForError = (json['id'] is String) ? json['id'] : (json['id']?.toString() ?? 'Unknown');
      throw Exception('Data Author tidak ada atau null untuk Post ID $postIdForError');
    }
    final User parsedAuthor = User.fromJson(authorJson);

    final dynamic categoryJson = json['category'];
    if (categoryJson == null || categoryJson is! Map<String, dynamic>) {
      final postIdForError = (json['id'] is String) ? json['id'] : (json['id']?.toString() ?? 'Unknown');
      throw Exception('Data Kategori tidak ada atau null untuk Post ID $postIdForError');
    }
    final Category parsedCategory = Category.fromJson(categoryJson);

    final List<dynamic>? tagsJsonList = json['tags'] as List<dynamic>?;
    final List<Tag>? parsedTags = tagsJsonList
        ?.map((tagJson) {
          if (tagJson == null || tagJson is! Map<String, dynamic>) {
            print('Peringatan: Tag individual bukan objek JSON (Map) atau null. Tipe aktual: ${tagJson.runtimeType}');
            return null; // Return null agar bisa di-filter
          }
          return Tag.fromJson(tagJson);
        })
        .where((tag) => tag != null) // Filter tag yang null
        .cast<Tag>()
        .toList();

    return Post(
      id: (json['id'] is String) ? int.parse(json['id']) : json['id'] as int,
      author: parsedAuthor,
      category: parsedCategory,
      title: json['title'] as String,
      content: json['content'] as String,
      views: json['views'] ?? 0,
      mediaUrl: json['media_url'],
      mediaType: json['media_type'],
      totalLikes: json['likes_count'] as int? ?? 0, // Dari withCount('likes')
      totalComments: json['comments_count'] as int? ?? 0,
      createdAt: json['created_at'] as String,
      tags: parsedTags,
      isLikedByCurrentUser: json['is_liked_by_current_user'] as bool? ?? false,
      totalLikesViaFunction: json['total_likes_via_function'] as int? ?? 0, // <--- PARSE PROPERTI BARU
    );
  }

  // --- Metode toJson() Anda (perlu disesuaikan jika ingin menggunakannya untuk mengirim data POST) ---
  // Perhatikan bahwa `toJson()` ini biasanya untuk mengirim data ke API,
  // dan mungkin tidak selalu memerlukan semua properti yang berasal dari JOIN/AGGREGATE.
  // Untuk keperluan API Anda, mungkin Anda hanya perlu mengirim `title`, `content`, `category_id`, `tags`.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author.toJson(),
      'category': category.toJson(),
      'title': title,
      'content': content,
      // 'likes_count': totalLikes, // Ini biasanya tidak dikirim, tapi diterima
      // 'comments_count': totalComments, // Ini biasanya tidak dikirim, tapi diterima
      'created_at': createdAt, // ini biasanya tidak dikirim, tapi diterima
      'tags': tags?.map((tag) => tag.toJson()).toList(),
      // `isLikedByCurrentUser` dan `totalLikesViaFunction` juga biasanya tidak dikirim
    };
  }
}