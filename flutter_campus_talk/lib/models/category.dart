// lib/models/category.dart
class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  // --- TAMBAHKAN METODE toJson() INI ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}