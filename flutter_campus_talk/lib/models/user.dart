// lib/models/user.dart
import '../models/role.dart';

class User {
  final int id;
  final String name;
  final String email;
  final Role? role;
  final String? emailVerifiedAt;
  final String? createdAt; // <--- UBAH INI MENJADI NULLABLE!

  User({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.emailVerifiedAt,
    this.createdAt, // <--- Hapus 'required' di sini
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // === Penanganan 'role' ===
    final dynamic roleJson = json['role'];
    Role? parsedRole;
    if (roleJson != null && roleJson is Map<String, dynamic>) {
      parsedRole = Role.fromJson(roleJson);
    } else {
      print('Peringatan: Data Role tidak ada, null, atau bukan Map untuk User ID ${json['id'] ?? 'Unknown'}. Tipe aktual: ${roleJson.runtimeType}');
    }

    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: parsedRole,
      emailVerifiedAt: json['email_verified_at'] as String?,
      createdAt: json['created_at'] as String?, // <--- Gunakan 'as String?' untuk menanganinya sebagai nullable
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role?.toJson(),
      'email_verified_at': emailVerifiedAt,
      'created_at': createdAt,
    };
  }
}