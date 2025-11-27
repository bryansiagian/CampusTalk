import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/api_services.dart';
import '../../models/post.dart';
import '../../models/category.dart';

class EditPostScreen extends StatefulWidget {
  final Post post; // Data postingan lama
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
    // 1. Isi form dengan data lama
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
    
    // Ubah List<Tag> menjadi string (misal: "flutter, dart")
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
      
      // Set kategori awal agar sesuai dengan postingan lama
      if (_categories.isNotEmpty) {
        try {
          _selectedCategory = _categories.firstWhere((c) => c.id == widget.post.category.id);
        } catch (e) {
          // Jika kategori lama tidak ditemukan (mungkin dihapus admin), biarkan null
        }
      }
    } catch (e) {
      print("Error fetching categories: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI UPDATE ---
  Future<void> _updatePost() async {
    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul, Isi, dan Kategori tidak boleh kosong.')));
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

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Postingan berhasil diperbarui!')));
        Navigator.pop(context, true); // Kembali ke detail screen dengan sinyal refresh
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal update: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI DELETE DENGAN KONFIRMASI ---
  Future<void> _confirmDelete() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Postingan?"),
        content: const Text("Tindakan ini tidak dapat dibatalkan. Postingan Anda akan dihapus secara permanen."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(), // Tutup dialog
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Tutup dialog
              _deletePost(); // Jalankan hapus
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost() async {
    setState(() => _isLoading = true);
    try {
      bool success = await _apiServices.deletePost(widget.post.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Postingan telah dihapus.')));
        
        // Logic Navigasi setelah hapus:
        // Kita harus menutup halaman Edit, DAN menutup halaman Detail agar kembali ke List
        // Cara sederhana: Pop dengan hasil 'deleted'
        Navigator.pop(context, 'deleted'); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
      setState(() => _isLoading = false);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Postingan', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updatePost,
            child: const Text("Simpan", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: SpinKitFadingCircle(color: Colors.blue, size: 40.0))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul
                  _buildLabel("Judul Postingan"),
                  TextField(
                    controller: _titleController,
                    decoration: _inputDecoration("Judul..."),
                  ),
                  const SizedBox(height: 20),

                  // Kategori
                  _buildLabel("Kategori"),
                  DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: _inputDecoration("Pilih kategori"),
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
                  const SizedBox(height: 20),

                  // Isi
                  _buildLabel("Isi Postingan"),
                  TextField(
                    controller: _contentController,
                    maxLines: 8,
                    decoration: _inputDecoration("Edit isi postingan..."),
                  ),
                  const SizedBox(height: 20),

                  // Tags
                  _buildLabel("Tags (Pisahkan dengan koma)"),
                  TextField(
                    controller: _tagsController,
                    decoration: _inputDecoration("contoh: flutter, bug"),
                  ),

                  const SizedBox(height: 50),

                  // TOMBOL HAPUS
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text("Hapus Postingan Ini", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // --- Helper Widgets agar kode bersih ---
  
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blue),
      ),
    );
  }
}