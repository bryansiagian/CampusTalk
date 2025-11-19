import '../models/role.dart'; // <--- Import model Role yang baru dibuat

class User {
  final int id;
  final String name;
  final String email;
  final Role role; // <--- UBAH TIPE DARI String MENJADI Role
  final String? emailVerifiedAt;
  final String createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role, // <--- UBAH TIPE
    this.emailVerifiedAt,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: Role.fromJson(json['role']), // <--- UBAH CARA MEMBACA: Panggil Role.fromJson
      emailVerifiedAt: json['email_verified_at'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toJson(), // <--- UBAH CARA MENULIS: Panggil role.toJson
      'email_verified_at': emailVerifiedAt,
      'created_at': createdAt,
    };
  }
}