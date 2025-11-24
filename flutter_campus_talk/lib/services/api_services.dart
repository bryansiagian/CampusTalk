// lib/services/api_services.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/comment_detail.dart';
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

  Future<bool> register(String name, String email, String password, String passwordConfirmation, String nim, String prodi, String angkatan) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: await _getHeaders(requireAuth: false),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'nim': nim,
        'prodi': prodi,
        'angkatan': angkatan,
      }),
    );

    if (response.statusCode == 201) {
      return true; // Sukses, tapi belum login
    } else {
      print('Registrasi Gagal: ${response.body}');
      final body = jsonDecode(response.body);
      throw Exception(jsonDecode(response.body)['message'] ?? 'Registrasi gagal.');
    }
  }

  // --- ADMIN USER MANAGEMENT ---
  Future<List<User>> getPendingUsers() async {
    final response = await http.get(Uri.parse('$_baseUrl/admin/pending-users'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      return data.map((e) => User.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> approveUser(int userId) async {
    final response = await http.put(Uri.parse('$_baseUrl/admin/users/$userId/approve'), headers: await _getHeaders());
    return response.statusCode == 200;
  }

  Future<bool> rejectUser(int userId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/admin/users/$userId/reject'), headers: await _getHeaders());
    return response.statusCode == 200;
  }

  Future<void> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: await _getHeaders(),
      );

      // Logika Baru:
      // Sukses (200) ATAU Unauthenticated (401) dianggap berhasil logout secara lokal
      if (response.statusCode == 200 || response.statusCode == 401) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('token'); // Hapus token lokal
      } else {
        // Error lain (misal 500 Server Error)
        print('Logout Gagal di Server: ${response.statusCode} - ${response.body}');
        // Tetap hapus token lokal agar user tidak terjebak
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
      }
    } catch (e) {
      // Jika koneksi internet mati, tetap hapus token lokal
      print("Error koneksi saat logout: $e");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
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
    String? tagSearch,
  }) async {
    Map<String, String> queryParams = {};
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    if (categoryId != null) queryParams['category_id'] = categoryId.toString();
    if (search != null) queryParams['search'] = search;
    if (tagSearch != null && tagSearch.isNotEmpty) queryParams['tag'] = tagSearch;

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

  Future<Post?> createPost(String title, String content, int categoryId, String tags) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/posts'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'title': title,
        'content': content,
        'category_id': categoryId,
        'tags': tags,
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

  Future<bool> updatePost(int postId, String title, String content, int categoryId, String tags) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/posts/$postId'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'title': title,
        'content': content,
        'category_id': categoryId,
        'tags': tags, // Kirim string "tag1, tag2"
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Gagal update post: ${response.body}');
      throw Exception('Gagal memperbarui postingan.');
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

  Future<bool> deleteComment(int commentId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/comments/$commentId'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200;
  }

  // --- Like ---
  Future<bool> likePost(int postId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/posts/$postId/likes'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      print('Gagal like postingan: ${response.statusCode} - ${response.body}');
      return false;
    }
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
      Uri.parse('$_baseUrl/notifications'), // Sesuai dengan routes/api.php
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final dynamic decodedBody = jsonDecode(response.body);
      if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('data')) {
        List<dynamic> data = decodedBody['data'];
        return data.map((json) => AppNotification.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } else {
      print('Gagal mengambil notifikasi: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat notifikasi.');
    }
  }

  Future<int> getUnreadNotificationCount() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications/unread-count'), // Sesuai dengan routes/api.php
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('count')) {
          return data['count'] as int;
        }
      }
      return 0;
    } catch (e) {
      print('Error fetching unread notification count: $e');
      return 0;
    }
  }

  Future<bool> markNotificationAsRead(int notificationId) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/notifications/$notificationId/read'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200;
  }

  Future<bool> markAllNotificationsAsRead() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/notifications/read-all'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200;
  }

  Future<List<CommentDetail>> getCommentDetails({
    String? authorName,
    int? postId, // <--- Ganti postTitle jadi postId
    String? sortBy, 
    int page = 1,
  }) async {
    Map<String, String> queryParams = {
      'page': page.toString(),
    };

    if (postId != null) {
      queryParams['post_id'] = postId.toString(); // <--- Kirim ID
    }

    Uri uri = Uri.parse('$_baseUrl/comments/details').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      try {
        final dynamic decodedBody = jsonDecode(response.body);
        if (decodedBody is! Map<String, dynamic>) {
          throw Exception('Format respons API top-level untuk comments/details bukan Map. Tipe aktual: ${decodedBody.runtimeType}.');
        }

        final dynamic paginationData = decodedBody['data'];
        if (paginationData is! Map<String, dynamic>) {
          throw Exception('Format respons API tidak valid: Kunci "data" pertama dalam respons comments/details bukan Map. Tipe aktual: ${paginationData.runtimeType}.');
        }

        final dynamic commentsList = paginationData['data']; // Ini adalah array data dari Laravel Paginate
        if (commentsList is! List<dynamic>) {
          throw Exception('Format respons API tidak valid: Kunci "data" bersarang dalam respons comments/details bukan List. Tipe aktual: ${commentsList.runtimeType}.');
        }
        return commentsList.map((json) => CommentDetail.fromJson(json as Map<String, dynamic>)).toList();
      } catch (e) {
        print('Error memparsing respons API detail komentar: $e. Body: ${response.body}');
        throw Exception('Gagal memparsing detail komentar dari respons API: ${e.toString()}');
      }
    } else {
      print('Gagal mengambil detail komentar: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat detail komentar. Status code: ${response.statusCode}');
    }
  }


  // --- ADMIN FEATURES ---
  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/dashboard-stats'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      print('Gagal load admin stats: ${response.body}');
      throw Exception('Gagal memuat statistik admin');
    }
  }
  
  // Fungsi delete post (jika belum ada)
  Future<bool> deletePost(int postId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/posts/$postId'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200;
  }

  // Like Komentar
  Future<bool> toggleCommentLike(int commentId) async {
    final response = await http.post(Uri.parse('$_baseUrl/comments/$commentId/like'), headers: await _getHeaders());
    return response.statusCode == 200;
  }

  // Lapor Konten
  Future<bool> reportContent(String type, int id, String reason) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/reports'),
      headers: await _getHeaders(),
      body: jsonEncode({'type': type, 'id': id, 'reason': reason}),
    );
    return response.statusCode == 200;
  }
  
  // Admin: Get Reports
  Future<List<dynamic>> getReports() async {
    final response = await http.get(Uri.parse('$_baseUrl/admin/reports'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    }
    return [];
  }
  
  // Admin: Dismiss Report
  Future<void> dismissReport(int id) async {
    await http.delete(Uri.parse('$_baseUrl/admin/reports/$id'), headers: await _getHeaders());
  }
}