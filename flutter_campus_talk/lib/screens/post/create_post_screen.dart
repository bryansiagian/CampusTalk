import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../models/category.dart';
import '../../models/tag.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final ApiServices _apiServices = ApiServices();
  bool _isLoading = false;

  List<Category> _categories = [];
  Category? _selectedCategory;

  List<Tag> _allTags = [];
  List<Tag> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _fetchCategoriesAndTags();
  }

  Future<void> _fetchCategoriesAndTags() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _categories = await _apiServices.getCategories();
      _allTags = await _apiServices.getTags();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createPost() async {
    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Judul, isi, dan kategori harus diisi.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<int> tagIds = _selectedTags.map((tag) => tag.id).toList();
      final newPost = await _apiServices.createPost(
        _titleController.text,
        _contentController.text,
        _selectedCategory!.id,
        tagIds,
      );

      if (newPost != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Postingan berhasil dibuat!')));
        Navigator.of(context).pop(true); // Kembali dan beritahu HomeScreen untuk refresh
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat postingan: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Postingan Baru', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: SpinKitFadingCircle(color: Theme.of(context).primaryColor, size: 50.0))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Postingan',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      labelText: 'Isi Postingan',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 8,
                    minLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (Category? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pilih Tag (opsional):',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: _allTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag.name),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.removeWhere((element) => element.id == tag.id);
                            }
                          });
                        },
                        selectedColor: Colors.blue.shade100,
                        checkmarkColor: Colors.blue.shade800,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.blue.shade800 : Colors.black87,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _createPost,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Buat Postingan', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}