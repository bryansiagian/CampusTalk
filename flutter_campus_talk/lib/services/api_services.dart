// lib/services/api_services.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/category.dart';
import '../models/notification.dart';
import '../models/tag.dart';

class ApiServices {
  static const String _baseUrl = 'http://10.0.2.2:8000/api';

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requireAuth) {
      String? token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // --- Autentikasi & Registrasi ---
  Future<User?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: await _getHeaders(requireAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      return User.fromJson(data['user'] as Map<String, dynamic>); // Tambahkan cast
    } else {
      print('Login Gagal: ${response.statusCode} - ${response.body}');
      throw Exception('Login gagal. Periksa email atau password Anda.');
    }
  }

  Future<User?> register(String name, String email, String password, String passwordConfirmation) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: await _getHeaders(requireAuth: false),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      return User.fromJson(data['user'] as Map<String, dynamic>); // Tambahkan cast
    } else {
      print('Registrasi Gagal: ${response.statusCode} - ${response.body}');
      throw Exception('Registrasi gagal. Coba lagi.');
    }
  }

  Future<void> logout() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/logout'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    } else {
      print('Logout Gagal: ${response.statusCode} - ${response.body}');
      throw Exception('Logout gagal. Coba lagi.');
    }
  }

  // --- Fungsi Baru: Mendapatkan data pengguna saat ini ---
  Future<User?> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/user'), // Asumsi ada endpoint /user yang mengembalikan user terautentikasi
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Asumsi API mengembalikan user langsung, atau di dalam kunci 'data'
      if (data is Map<String, dynamic>) {
         // Cek apakah user ada di dalam kunci 'data' atau langsung
        if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
          return User.fromJson(data['data'] as Map<String, dynamic>);
        } else {
          return User.fromJson(data); // Jika user langsung di root
        }
      }
      return null;
    } else {
      print('Gagal mengambil profil pengguna: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat profil pengguna.');
    }
  }

  // --- Postingan (Forum Diskusi) ---
  Future<List<Post>> getPosts({
    String? sortBy,
    int? categoryId,
    String? search,
  }) async {
    Map<String, String> queryParams = {};
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    if (categoryId != null) queryParams['category_id'] = categoryId.toString();
    if (search != null) queryParams['search'] = search;

    Uri uri = Uri.parse('$_baseUrl/posts').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      try {
        final dynamic decodedBody = jsonDecode(response.body);
        if (decodedBody is! Map<String, dynamic>) {
          print('Error: Respons API top-level untuk /posts bukan Map. Tipe aktual: ${decodedBody.runtimeType}. Body: ${response.body}');
          throw Exception('Format respons API tidak valid: Respons top-level bukan objek JSON.');
        }

        final dynamic paginationData = decodedBody['data'];
        if (paginationData is! Map<String, dynamic>) {
          print('Error: Kunci "data" pertama dalam respons API /posts bukan Map. Tipe aktual: ${paginationData.runtimeType}. Body: ${response.body}');
          throw Exception('Format respons API tidak valid: Kunci "data" pertama bukan objek JSON.');
        }

        final dynamic postsList = paginationData['data'];
        if (postsList is! List<dynamic>) {
          print('Error: Kunci "data" bersarang dalam respons API /posts bukan List. Tipe aktual: ${postsList.runtimeType}. Body: ${response.body}');
          throw Exception('Format respons API tidak valid: Kunci "data" bersarang bukan array JSON.');
        }
        return postsList.map((json) => Post.fromJson(json as Map<String, dynamic>)).toList(); // Tambahkan cast
      } catch (e) {
        print('Error memparsing respons API postingan: $e. Body: ${response.body}');
        throw Exception('Gagal memparsing postingan dari respons API: ${e.toString()}');
      }
    } else {
      print('Gagal mengambil postingan: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat postingan. Status code: ${response.statusCode}');
    }
  }

  // --- Fungsi Baru: Mendapatkan postingan berdasarkan user ID ---
  Future<List<Post>> getPostsByUser(int userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/$userId/posts'), // Asumsi endpoint users/{id}/posts
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      try {
        final dynamic decodedBody = jsonDecode(response.body);
        if (decodedBody is! Map<String, dynamic>) {
          print('Error: Respons API top-level untuk /users/$userId/posts bukan Map. Tipe aktual: ${decodedBody.runtimeType}. Body: ${response.body}');
          throw Exception('Format respons API tidak valid: Respons top-level bukan objek JSON.');
        }

        final dynamic postsList = decodedBody['data']; // Asumsi tidak ada paginasi ganda di sini
        if (postsList is! List<dynamic>) {
          print('Error: Kunci "data" dalam respons API /users/$userId/posts bukan List. Tipe aktual: ${postsList.runtimeType}. Body: ${response.body}');
          throw Exception('Format respons API tidak valid: Kunci "data" bukan array JSON.');
        }
        return postsList.map((json) => Post.fromJson(json as Map<String, dynamic>)).toList();
      } catch (e) {
        print('Error memparsing respons API postingan user: $e. Body: ${response.body}');
        throw Exception('Gagal memparsing postingan user dari respons API: ${e.toString()}');
      }
    } else {
      print('Gagal mengambil postingan user: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat postingan user. Status code: ${response.statusCode}');
    }
  }

  Future<Post> getPostDetail(int postId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/posts/$postId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final dynamic decodedBody = jsonDecode(response.body);
      if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('data')) {
        return Post.fromJson(decodedBody['data'] as Map<String, dynamic>); // Tambahkan cast
      }
      throw Exception('Format respons API detail postingan tidak sesuai.');
    } else {
      print('Gagal mengambil detail postingan: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat detail postingan.');
    }
  }

  Future<Post?> createPost(String title, String content, int categoryId, List<int> tagIds) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/posts'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'title': title,
        'content': content,
        'category_id': categoryId,
        'tags': tagIds,
      }),
    );

    if (response.statusCode == 201) {
      final dynamic decodedBody = jsonDecode(response.body);
      if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('data')) {
        return Post.fromJson(decodedBody['data'] as Map<String, dynamic>); // Tambahkan cast
      }
      return null;
    } else {
      print('Gagal membuat postingan: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal membuat postingan.');
    }
  }

  // --- Komentar ---
  Future<List<Comment>> getCommentsForPost(int postId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/posts/$postId/comments'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final dynamic decodedBody = jsonDecode(response.body);
      if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('data')) {
        final dynamic commentsList = decodedBody['data'];
        if (commentsList is List<dynamic>) {
          return commentsList.map((json) => Comment.fromJson(json as Map<String, dynamic>)).toList(); // Tambahkan cast
        }
      }
      return [];
    } else {
      print('Gagal mengambil komentar: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat komentar.');
    }
  }

  Future<Comment?> addComment(int postId, String content, {int? parentCommentId}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/posts/$postId/comments'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'content': content,
        'parent_comment_id': parentCommentId,
      }),
    );

    if (response.statusCode == 201) {
      final dynamic decodedBody = jsonDecode(response.body);
      if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('data')) {
        return Comment.fromJson(decodedBody['data'] as Map<String, dynamic>); // Tambahkan cast
      }
      return null;
    } else {
      print('Gagal menambahkan komentar: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal menambahkan komentar.');
    }
  }

  // --- Like ---
  Future<bool> likePost(int postId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/posts/$postId/likes'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> unlikePost(int postId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/posts/$postId/likes'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // --- Kategori & Tag ---
  Future<List<Category>> getCategories() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/categories'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final dynamic decodedBody = jsonDecode(response.body);
      if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('data')) {
        List<dynamic> data = decodedBody['data'];
        return data.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList(); // Tambahkan cast
      }
      return [];
    } else {
      print('Gagal mengambil kategori: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat kategori.');
    }
  }

  Future<List<Tag>> getTags() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/tags'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final dynamic decodedBody = jsonDecode(response.body);
      if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('data')) {
        List<dynamic> data = decodedBody['data'];
        return data.map((json) => Tag.fromJson(json as Map<String, dynamic>)).toList(); // Tambahkan cast
      }
      return [];
    } else {
      print('Gagal mengambil tag: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat tag.');
    }
  }

  // --- Notifikasi ---
  Future<List<AppNotification>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/notifications'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final dynamic decodedBody = jsonDecode(response.body);
      if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('data')) {
        List<dynamic> data = decodedBody['data'];
        return data.map((json) => AppNotification.fromJson(json as Map<String, dynamic>)).toList(); // Tambahkan cast
      }
      return [];
    } else {
      print('Gagal mengambil notifikasi: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat notifikasi.');
    }
  }

  Future<bool> markNotificationAsRead(int notificationId) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/notifications/$notificationId/read'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200;
  }

  // --- Admin Dashboard (Fitur Khusus Admin) ---
  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/dashboard-stats'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      print('Gagal mengambil statistik admin: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat statistik admin.');
    }
  }
}