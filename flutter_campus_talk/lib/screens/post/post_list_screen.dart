// lib/screens/post/post_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../models/category.dart';
import '../../models/post.dart';
import '../../services/api_services.dart';
import 'post_detail_screen.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({Key? key}) : super(key: key);

  @override
  _PostListScreenState createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final ApiServices _apiServices = ApiServices();
  late Future<List<Post>> _postsFuture;
  late Future<List<Category>> _categoriesFuture;

  String? _selectedSortBy;
  int? _selectedCategoryId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _categoriesFuture = _apiServices.getCategories();
  }

  void _fetchPosts() {
    setState(() {
      _postsFuture = _apiServices.getPosts(
        sortBy: _selectedSortBy,
        categoryId: _selectedCategoryId,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
    });
  }

  Future<void> _refreshPosts() async {
    _fetchPosts();
  }

  void _applyFilters() {
    _fetchPosts();
    Navigator.of(context).pop(); // Tutup bottom sheet filter
  }

  void _resetFilters() {
    setState(() {
      _selectedSortBy = null;
      _selectedCategoryId = null;
      _searchController.clear();
    });
    _fetchPosts();
    Navigator.of(context).pop(); // Tutup bottom sheet filter
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Postingan',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Cari Postingan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Category>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Gagal memuat kategori: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('Tidak ada kategori tersedia');
                  } else {
                    return DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      hint: const Text('Pilih Kategori'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: snapshot.data!.map((category) {
                        return DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSortBy,
                hint: const Text('Urutkan Berdasarkan'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'latest', child: Text('Terbaru')),
                  DropdownMenuItem(value: 'oldest', child: Text('Terlama')),
                  DropdownMenuItem(value: 'most_likes', child: Text('Suka Terbanyak')),
                  DropdownMenuItem(value: 'most_comments', child: Text('Komentar Terbanyak')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSortBy = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _resetFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey, // Background color
                        foregroundColor: Colors.white, // Text color
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reset', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor, // Background color
                        foregroundColor: Colors.white, // Text color
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Terapkan', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Postingan', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterSheet,
          ),
        ],
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