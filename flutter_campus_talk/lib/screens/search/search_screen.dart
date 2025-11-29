import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../models/post.dart';
import '../../models/category.dart';
import '../../models/user.dart';
import '../../services/api_services.dart';
import '../post/post_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiServices _apiServices = ApiServices();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  int _selectedCategoryIndex = 0;
  List<Category> _categories = [];
  bool _isLoadingCategories = true;

  List<Post> _posts = [];
  bool _isLoadingPosts = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchPosts(); // Load awal kosong atau semua
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _fixImageUrl(String url) {
    if (url.startsWith('/')) return 'http://10.0.2.2:8000$url';
    if (url.contains('localhost')) return url.replaceAll('localhost', '10.0.2.2');
    if (url.contains('127.0.0.1')) return url.replaceAll('127.0.0.1', '10.0.2.2');
    return url;
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _apiServices.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoadingPosts = true;
      _hasSearched = true;
    });

    try {
      int? categoryId;
      if (_selectedCategoryIndex > 0 && _categories.isNotEmpty) {
        categoryId = _categories[_selectedCategoryIndex - 1].id;
      }

      String? searchQuery = _searchController.text.isNotEmpty ? _searchController.text : null;

      final posts = await _apiServices.getPosts(
        categoryId: categoryId,
        search: searchQuery,
      );

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPosts = false);
    }
  }

  void _onCategorySelected(int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
    _fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    // --- INISIALISASI TEMA ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    
    // Warna custom untuk background input
    final inputFillColor = isDark ? Colors.grey[800] : Colors.grey[100];
    final textHintColor = isDark ? Colors.grey[400] : Colors.grey[500];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.cardColor,
        elevation: 1,
        iconTheme: theme.iconTheme,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: inputFillColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            textInputAction: TextInputAction.search,
            style: TextStyle(color: textTheme.bodyLarge?.color),
            onSubmitted: (_) => _fetchPosts(),
            decoration: InputDecoration(
              hintText: "Cari topik diskusi...",
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintStyle: TextStyle(color: textHintColor),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, color: textHintColor, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _fetchPosts();
                      },
                    )
                  : null,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: colorScheme.primary),
            onPressed: _fetchPosts,
          )
        ],
      ),
      body: Column(
        children: [
          // 1. KATEGORI FILTER
          Container(
            height: 50,
            color: theme.cardColor,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _isLoadingCategories
                ? Center(child: SpinKitThreeBounce(color: colorScheme.primary, size: 20))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedCategoryIndex;
                      String label = index == 0 ? "Semua" : _categories[index - 1].name;

                      return GestureDetector(
                        onTap: () => _onCategorySelected(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            // Warna background chip dinamis
                            color: isSelected ? colorScheme.primary : inputFillColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? colorScheme.primary : theme.dividerColor,
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? colorScheme.onPrimary : textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          Divider(height: 1, color: theme.dividerColor),

          // 2. HASIL PENCARIAN
          Expanded(
            child: _isLoadingPosts
                ? Center(child: SpinKitFadingCircle(color: colorScheme.primary, size: 40))
                : _posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: textHintColor),
                            const SizedBox(height: 16),
                            Text(
                              _hasSearched ? "Tidak ditemukan" : "Mulai pencarian Anda",
                              style: TextStyle(color: textHintColor),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 20),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          return _buildSearchPostCard(_posts[index], theme, colorScheme);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPostCard(Post post, ThemeData theme, ColorScheme colorScheme) {
    final textSecondary = theme.textTheme.bodyMedium?.color;

    return Card(
      color: theme.cardColor, // Warna kartu sesuai tema
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => PostDetailScreen(postId: post.id))
          ).then((_) => _fetchPosts()); 
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kategori Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer, // Warna container primary
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  post.category.name,
                  style: TextStyle(color: colorScheme.onPrimaryContainer, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                post.title, 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textTheme.bodyLarge?.color)
              ),
              const SizedBox(height: 4),
              Text(
                post.content, 
                maxLines: 2, 
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: post.author.profilePictureUrl != null 
                        ? NetworkImage(_fixImageUrl(post.author.profilePictureUrl!))
                        : null,
                    child: post.author.profilePictureUrl == null 
                        ? const Icon(Icons.person, size: 12, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 6),
                  Text(post.author.name, style: TextStyle(color: textSecondary, fontSize: 12)),
                  const Spacer(),
                  Icon(Icons.favorite, size: 14, color: textSecondary),
                  const SizedBox(width: 4),
                  Text("${post.totalLikes}", style: TextStyle(color: textSecondary, fontSize: 12)),
                  const SizedBox(width: 12),
                  Icon(Icons.chat_bubble, size: 14, color: textSecondary),
                  const SizedBox(width: 4),
                  Text("${post.totalComments}", style: TextStyle(color: textSecondary, fontSize: 12)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}