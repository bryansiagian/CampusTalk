import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/api_services.dart';
import '../../models/post.dart';
import '../../models/category.dart';

class EditPostScreen extends StatefulWidget {
  final Post post; // Terima data postingan lama
  const EditPostScreen({Key? key, required this.post}) : super(key: key);

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final ApiServices _apiServices = ApiServices();
  
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagsController;
  
  bool _isLoading = false;
  List<Category> _categories = [];
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // 1. Isi Controller dengan data lama
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
    
    // Ubah List<Tag> menjadi String "tag1, tag2"
    String initialTags = "";
    if (widget.post.tags != null) {
      initialTags = widget.post.tags!.map((t) => t.name).join(', ');
    }
    _tagsController = TextEditingController(text: initialTags);

    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      _categories = await _apiServices.getCategories();
      
      // Set kategori awal berdasarkan ID yang ada di post lama
      if (_categories.isNotEmpty) {
        try {
          _selectedCategory = _categories.firstWhere((c) => c.id == widget.post.category.id);
        } catch (e) {
          // Jika kategori lama sudah dihapus admin, default ke null atau index 0
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePost() async {
    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data tidak lengkap.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool success = await _apiServices.updatePost(
        widget.post.id,
        _titleController.text,
        _contentController.text,
        _selectedCategory!.id,
        _tagsController.text,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Postingan diperbarui!')));
        Navigator.pop(context, true); // Kembali dan kirim sinyal refresh
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Postingan', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: SpinKitFadingCircle(color: Theme.of(context).primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      labelText: 'Isi',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 6,
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
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tagsController,
                    decoration: InputDecoration(
                      labelText: 'Tags (Pisahkan koma)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.tag),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _updatePost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Simpan Perubahan", style: TextStyle(fontSize: 18)),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}