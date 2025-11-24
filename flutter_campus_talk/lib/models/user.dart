import '../models/role.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String? nim;  
  final String? prodi;
  final int? angkatan; 
  final Role? role; // Objek Role
  final String? emailVerifiedAt;
  final String? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.nim,      
    this.prodi,    
    this.angkatan, 
    this.role,
    this.emailVerifiedAt,
    this.createdAt,
  });

  // Getter untuk mengecek apakah user ini admin
  // Mengembalikan true jika nama role adalah 'admin'
  bool get isAdmin => role?.name == 'admin';

  factory User.fromJson(Map<String, dynamic> json) {
    // Parsing Role secara aman
    final dynamic roleJson = json['role'];
    Role? parsedRole;
    
    if (roleJson != null && roleJson is Map<String, dynamic>) {
      parsedRole = Role.fromJson(roleJson);
    }

    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      nim: json['nim'] as String?,           // <--- Baru
      prodi: json['prodi'] as String?,       // <--- Baru
      // Parsing angkatan (bisa string atau int dari JSON, amannya di-cast)
      angkatan: json['angkatan'] != null ? int.tryParse(json['angkatan'].toString()) : null,
      role: parsedRole,
      emailVerifiedAt: json['email_verified_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'nim': nim,
      'prodi': prodi,
      'angkatan': angkatan,
      'role': role?.toJson(),
      'email_verified_at': emailVerifiedAt,
      'created_at': createdAt,
    };
  }
}