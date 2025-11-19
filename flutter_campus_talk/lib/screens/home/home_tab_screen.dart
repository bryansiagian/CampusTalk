// lib/screens/home/home_tab_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../models/post.dart';
import '../../services/api_services.dart';
import '../post/create_post_screen.dart';
import '../post/post_detail_screen.dart';

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({Key? key}) : super(key: key);

  @override
  _HomeTabScreenState createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  final ApiServices _apiServices = ApiServices();
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _apiServices.getPosts();
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _postsFuture = _apiServices.getPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => CreatePostScreen()),
          );
          if (result == true) {
            _refreshPosts();
          }
        },
        label: const Text('Buat Postingan'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: FutureBuilder<List<Post>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: SpinKitFadingCircle(
                  color: Theme.of(context).primaryColor,
                  size: 50.0,
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}. Tarik untuk refresh.'),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text('Belum ada postingan. Ayo mulai diskusi!', style: TextStyle(fontSize: 16)),
              );
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final post = snapshot.data![index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PostDetailScreen(postId: post.id),
                          ),
                        ).then((_) => _refreshPosts());
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Oleh: ${post.author.name} • Kategori: ${post.category.name}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              post.content,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.thumb_up_alt_outlined, size: 18, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text('${post.totalLikes}', style: TextStyle(color: Colors.grey)),
                                    SizedBox(width: 16),
                                    Icon(Icons.comment_outlined, size: 18, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text('${post.totalComments}', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                                Text(
                                  '${DateTime.parse(post.createdAt).day}/${DateTime.parse(post.createdAt).month}/${DateTime.parse(post.createdAt).year}',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            if (post.tags != null && post.tags!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: post.tags!
                                      .map((tag) => Chip(
                                            label: Text(tag.name),
                                            backgroundColor: Colors.blue.shade50,
                                            labelStyle: TextStyle(color: Colors.blue.shade800, fontSize: 12),
                                          ))
                                      .toList(),
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
      ),
    );
  }
}