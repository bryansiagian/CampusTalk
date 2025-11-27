import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/api_services.dart';
import '../../models/category.dart';
import '../../models/user.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  
  final ApiServices _apiServices = ApiServices();
  bool _isLoading = false;

  List<Category> _categories = [];
  Category? _selectedCategory;
  User? _currentUser;
  
  final List<String> _suggestedTags = ["algoritma", "web", "mobile", "database", "skripsi"];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      _categories = await _apiServices.getCategories();
      _currentUser = await _apiServices.getCurrentUser();
    } catch (e) {
      // Handle error quietly or show snackbar
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createPost() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul, Kategori, dan Isi wajib diisi.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final newPost = await _apiServices.createPost(
        _titleController.text, _contentController.text, _selectedCategory!.id, _tagsController.text,
      );
      if (newPost != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Postingan berhasil dibuat!')));
        Navigator.pop(context, true); // Kembali ke halaman sebelumnya
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        // --- BAGIAN INI DITAMBAHKAN (TOMBOL KEMBALI) ---
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        // -----------------------------------------------
        title: const Text('Buat Postingan Baru', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text("Posting", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: _isLoading && _categories.isEmpty
          ? Center(child: SpinKitFadingCircle(color: Colors.blue, size: 40.0))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentUser != null)
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(_currentUser!.name[0], style: const TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_currentUser!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("Posting sebagai mahasiswa", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        )
                      ],
                    ),
                  const SizedBox(height: 24),
                  _buildLabel("Judul Postingan *"),
                  TextField(controller: _titleController, decoration: _inputDecoration("Tulis judul...")),
                  const SizedBox(height: 20),
                  _buildLabel("Kategori *"),
                  DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: _inputDecoration("Pilih kategori"),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel("Isi Postingan *"),
                  TextField(controller: _contentController, maxLines: 6, decoration: _inputDecoration("Jelaskan detail...")),
                  const SizedBox(height: 20),
                  _buildLabel("Tag (Opsional)"),
                  TextField(controller: _tagsController, decoration: _inputDecoration("Contoh: flutter, error (pisahkan koma)")),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _suggestedTags.map((tag) => InkWell(
                      onTap: () => _tagsController.text = _tagsController.text.isEmpty ? tag : "${_tagsController.text}, $tag",
                      child: Chip(label: Text("#$tag", style: const TextStyle(fontSize: 11)), backgroundColor: Colors.grey[100]),
                    )).toList(),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Panduan Posting", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        SizedBox(height: 8),
                        Text("• Gunakan bahasa yang sopan\n• Pastikan kategori sesuai\n• Jelas dan deskriptif", style: TextStyle(color: Colors.blue, fontSize: 12, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)));
  InputDecoration _inputDecoration(String hint) => InputDecoration(hintText: hint, filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)));
}