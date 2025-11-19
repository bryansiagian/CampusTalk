// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/api_services.dart';
import '../post/post_detail_screen.dart';
import 'dart:async'; // Pastikan ini diimpor untuk Future

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiServices _apiServices = ApiServices();
  // Inisialisasi awal Future untuk menghindari LateInitializationError
  late Future<User?> _userProfileFuture = Future.value(null);
  late Future<List<Post>> _userPostsFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  void _fetchProfileData() {
    setState(() {
      // Panggil getCurrentUser dan tangkap error, kembalikan null jika gagal
      _userProfileFuture = _apiServices.getCurrentUser().catchError((error) {
        print('Error fetching current user: $error');
        return null; // Mengembalikan null untuk _userProfileFuture jika ada error
      });

      // Chain _userPostsFuture setelah _userProfileFuture selesai
      _userPostsFuture = _userProfileFuture.then((user) {
        if (user != null) {
          // Jika user berhasil didapatkan, ambil postingannya
          return _apiServices.getPostsByUser(user.id);
        } else {
          // Jika user null, kembalikan Future<List<Post>> kosong
          return Future.value(<Post>[]);
        }
      }).catchError((error) {
        // Tangkap error jika _apiServices.getPostsByUser gagal
        print('Error fetching user posts: $error');
        // Kembalikan Future<List<Post>> kosong jika ada error
        return Future.value(<Post>[]);
      });
    });
  }

  Future<void> _refreshProfileAndPosts() async {
    _fetchProfileData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfileAndPosts,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<User?>(
                  future: _userProfileFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: SpinKitFadingCircle(color: Theme.of(context).primaryColor, size: 30.0));
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error memuat profil: ${snapshot.error}. Pastikan API /user berfungsi dengan benar.'));
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return Center(child: Text('Profil pengguna tidak ditemukan. Pastikan Anda sudah login dan API berfungsi.'));
                    } else {
                      final user = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Role: ${user.role?.name ?? 'Tidak Ada'}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Text(
                            'Postingan Saya',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }
                  },
                ),
                FutureBuilder<List<Post>>(
                  future: _userPostsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: SpinKitThreeBounce(color: Theme.of(context).primaryColor, size: 20.0));
                    } else if (snapshot.hasError) {
                      return Text('Error memuat postingan: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('Anda belum membuat postingan apa pun.'));
                    } else {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final post = snapshot.data![index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PostDetailScreen(postId: post.id),
                                  ),
                                ).then((_) => _refreshProfileAndPosts());
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post.title,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      post.content,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        'Dibuat pada: ${DateTime.parse(post.createdAt).day}/${DateTime.parse(post.createdAt).month}/${DateTime.parse(post.createdAt).year}',
                                        style: TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}