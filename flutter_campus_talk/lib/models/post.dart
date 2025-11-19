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
    return Post(
      id: json['id'], 
      author: json['author'], 
      category: Category.fromJson(json['category']), 
      title: json['title'], 
      content: json['content'], 
      createdAt: json['createdAt'],
      tags: (json['tags'] as List<dynamic>?)
        ?.map((tagJson) => Tag.fromJson(tagJson))
        .toList(),
    );
  }
}