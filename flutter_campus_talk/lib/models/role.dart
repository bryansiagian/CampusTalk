// lib/models/role.dart
class Role {
  final int id;
  final String name;
  final String? createdAt; // <--- UBAH INI MENJADI NULLABLE
  final String? updatedAt; // <--- UBAH INI MENJADI NULLABLE

  Role({
    required this.id,
    required this.name,
    this.createdAt, // <--- Hapus 'required'
    this.updatedAt, // <--- Hapus 'required'
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: json['created_at'] as String?, // <--- Gunakan 'as String?'
      updatedAt: json['updated_at'] as String?, // <--- Gunakan 'as String?'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}