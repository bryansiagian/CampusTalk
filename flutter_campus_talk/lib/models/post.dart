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
  final int totalLikes;
  final int totalComments;
  final String createdAt;
  final List<Tag>? tags;

  Post({
    required this.id,
    required this.author,
    required this.category,
    required this.title,
    required this.content,
    this.totalLikes = 0,
    this.totalComments = 0,
    required this.createdAt,
    this.tags,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // --- Penanganan 'author' ---
    final dynamic authorJson = json['author'];
    if (authorJson == null || authorJson is! Map<String, dynamic>) {
      throw Exception('Data Author tidak ada atau null untuk Post ID ${json['id'] ?? 'Unknown'}. Tipe aktual: ${authorJson.runtimeType}');
    }
    final User parsedAuthor = User.fromJson(authorJson);

    // --- Penanganan 'category' ---
    final dynamic categoryJson = json['category'];
    if (categoryJson == null || categoryJson is! Map<String, dynamic>) {
      throw Exception('Data Kategori tidak ada atau null untuk Post ID ${json['id'] ?? 'Unknown'}. Tipe aktual: ${categoryJson.runtimeType}');
    }
    final Category parsedCategory = Category.fromJson(categoryJson);

    // --- Penanganan 'tags' ---
    final List<dynamic>? tagsJsonList = json['tags'] as List<dynamic>?;
    final List<Tag>? parsedTags = tagsJsonList
        ?.map((tagJson) {
          if (tagJson == null || tagJson is! Map<String, dynamic>) {
            print('Peringatan: Tag individual bukan objek JSON (Map) atau null. Tipe aktual: ${tagJson.runtimeType}');
            return null;
          }
          return Tag.fromJson(tagJson);
        })
        .where((tag) => tag != null)
        .cast<Tag>()
        .toList();

    return Post(
      // PERBAIKAN PENTING: Tangani 'id' jika dikirim sebagai String atau int
      id: (json['id'] is String) ? int.parse(json['id']) : json['id'] as int,
      author: parsedAuthor,
      category: parsedCategory,
      title: json['title'] as String,
      content: json['content'] as String,
      // totalLikes dan totalComments sudah cukup baik dengan 'as int? ?? 0'
      totalLikes: json['likes_count'] as int? ?? 0,
      totalComments: json['comments_count'] as int? ?? 0,
      createdAt: json['created_at'] as String,
      tags: parsedTags,
    );
  }
}