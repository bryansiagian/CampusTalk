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
  
  // Controllers Pencarian
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _tagSearchController = TextEditingController(); // <--- Baru

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
        tagSearch: _tagSearchController.text.isNotEmpty ? _tagSearchController.text : null, // <--- Kirim Tag
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
      _tagSearchController.clear(); // <--- Reset Tag
    });
    _fetchPosts();
    Navigator.of(context).pop();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Filter & Pencarian',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // 1. Pencarian Judul
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Cari Judul / Konten',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Pencarian Tag (BARU)
              TextField(
                controller: _tagSearchController,
                decoration: InputDecoration(
                  labelText: 'Cari berdasarkan Tag',
                  hintText: 'Misal: flutter',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Filter Kategori
              FutureBuilder<List<Category>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(); // Loading diam-diam atau container kosong
                  } else {
                    return DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      hint: const Text('Filter Kategori'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        prefixIcon: const Icon(Icons.category),
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

              // 4. Sorting
              DropdownButtonFormField<String>(
                value: _selectedSortBy,
                hint: const Text('Urutkan Berdasarkan'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  prefixIcon: const Icon(Icons.sort),
                ),
                items: const [
                  DropdownMenuItem(value: 'latest', child: Text('Terbaru')),
                  DropdownMenuItem(value: 'oldest', child: Text('Terlama')),
                  DropdownMenuItem(value: 'popular', child: Text('Terpopuler')), // Sesuai backend
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSortBy = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Tombol Reset & Terapkan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetFilters,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Terapkan'),
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
          // Indikator jika sedang ada filter aktif
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: _showFilterSheet,
              ),
              if (_searchController.text.isNotEmpty || 
                  _tagSearchController.text.isNotEmpty || 
                  _selectedCategoryId != null || 
                  _selectedSortBy != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: Colors.orangeAccent,
                  ),
                )
            ],
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: ${snapshot.error}. Tarik untuk refresh.', textAlign: TextAlign.center),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text('Tidak ada postingan yang cocok.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              );
            } else {
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final post = snapshot.data![index];
                  return _buildPostCard(post);
                },
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
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
              // Kategori
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  post.category.name,
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              
              // Judul
              Text(
                post.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text('Oleh: ${post.author.name}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              
              const SizedBox(height: 8),
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),

              // Tags Chips
              if (post.tags != null && post.tags!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Wrap(
                    spacing: 6.0,
                    runSpacing: 0.0,
                    children: post.tags!.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text("#${tag.name}", style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                      );
                    }).toList(),
                  ),
                ),

              // Footer Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${post.totalLikes}', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(width: 16),
                      Icon(Icons.comment_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${post.totalComments}', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  Text(
                    '${DateTime.parse(post.createdAt).day}/${DateTime.parse(post.createdAt).month}/${DateTime.parse(post.createdAt).year}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}