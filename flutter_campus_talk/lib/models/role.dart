// lib/models/role.dart
class Role {
  final int id;
  final String name;
  final String? createdAt;
  final String? updatedAt;

  Role({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  // --- Pastikan metode toJson() ini ada dan benar ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}