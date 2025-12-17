import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart'; // Wajib import
import '../../services/api_services.dart';
import '../../models/post.dart';
import '../../models/category.dart';

class EditPostScreen extends StatefulWidget {
  final Post post; 
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

  // VARIABEL GAMBAR
  final ImagePicker _picker = ImagePicker();
  File? _newImageFile; // Gambar baru dari galeri
  bool _isOldImageDeleted = false; // Flag jika user menghapus gambar lama

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
    
    String initialTags = "";
    if (widget.post.tags != null) {
      initialTags = widget.post.tags!.map((t) => t.name).join(', ');
    }
    _tagsController = TextEditingController(text: initialTags);

    _fetchCategories();
  }

  // Helper URL (Sama seperti di screen lain)
  String _fixImageUrl(String url) {
    if (url.startsWith('/')) return 'http://10.0.2.2:8000$url'; // Sesuaikan IP jika pakai HP Fisik
    if (url.contains('localhost')) return url.replaceAll('localhost', '10.0.2.2');
    if (url.contains('127.0.0.1')) return url.replaceAll('127.0.0.1', '10.0.2.2');
    return url;
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      _categories = await _apiServices.getCategories();
      if (_categories.isNotEmpty) {
        try {
          _selectedCategory = _categories.firstWhere((c) => c.id == widget.post.category.id);
        } catch (e) {}
      }
    } catch (e) {
      print("Error fetching categories: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA GAMBAR ---
  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked != null) {
      setState(() {
        _newImageFile = File(picked.path);
        _isOldImageDeleted = false; // Reset flag hapus karena kita ganti baru
      });
    }
  }

  void _removeImage() {
    setState(() {
      _newImageFile = null; // Hapus file baru (jika ada)
      _isOldImageDeleted = true; // Tandai gambar lama dihapus
    });
  }

  // --- FUNGSI UPDATE ---
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
        _newImageFile,      // Kirim file baru (bisa null)
        _isOldImageDeleted, // Kirim status hapus
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Postingan diperbarui!')));
        Navigator.pop(context, true); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal update: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Postingan?"),
        content: const Text("Tindakan ini permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deletePost(); 
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
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
        Navigator.pop(context, 'deleted'); 
      }
    } catch (e) {
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final inputFillColor = isDark ? Colors.grey[800] : Colors.grey[50];
    
    // PERBAIKAN DI SINI: Tambahkan tanda seru (!) di akhir Colors.grey[...]
    final Color borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    
    final textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Postingan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updatePost,
            child: Text("Simpan", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: SpinKitFadingCircle(color: colorScheme.primary, size: 40.0))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Judul", textColor),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: textColor),
                    decoration: _inputDecoration("Judul...", inputFillColor, borderColor, colorScheme.primary),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel("Kategori", textColor),
                  DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: _inputDecoration("Pilih kategori", inputFillColor, borderColor, colorScheme.primary),
                    dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                    style: TextStyle(color: textColor),
                    items: _categories.map((category) {
                      return DropdownMenuItem(value: category, child: Text(category.name, style: TextStyle(color: textColor)));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel("Isi", textColor),
                  TextField(
                    controller: _contentController,
                    maxLines: 8,
                    style: TextStyle(color: textColor),
                    decoration: _inputDecoration("Edit isi...", inputFillColor, borderColor, colorScheme.primary),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel("Tags", textColor),
                  TextField(
                    controller: _tagsController,
                    style: TextStyle(color: textColor),
                    decoration: _inputDecoration("contoh: flutter, bug", inputFillColor, borderColor, colorScheme.primary),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // --- AREA EDIT GAMBAR ---
                  _buildLabel("Media", textColor),
                  // Error sebelumnya hilang karena borderColor sekarang pasti (Color)
                  _buildImagePreview(borderColor), 
                  // ------------------------

                  const SizedBox(height: 40),

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

  // WIDGET PREVIEW GAMBAR
  Widget _buildImagePreview(Color borderColor) {
    // 1. Cek apakah ada gambar baru yang dipilih
    if (_newImageFile != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_newImageFile!, width: double.infinity, height: 200, fit: BoxFit.cover),
          ),
          _buildRemoveButton(),
        ],
      );
    } 
    // 2. Cek apakah ada gambar lama (dan belum dihapus user)
    else if (widget.post.mediaUrl != null && !_isOldImageDeleted) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _fixImageUrl(widget.post.mediaUrl!),
              width: double.infinity, height: 200, fit: BoxFit.cover,
              errorBuilder: (_,__,___) => Container(
                height: 200, color: Colors.grey[200], 
                child: const Center(child: Icon(Icons.broken_image))
              ),
            ),
          ),
          _buildRemoveButton(),
        ],
      );
    }
    // 3. Jika tidak ada gambar / sudah dihapus -> Tampilkan tombol Add
    else {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
              Text("Tambah Foto", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildRemoveButton() {
    return Positioned(
      top: 8, right: 8,
      child: CircleAvatar(
        backgroundColor: Colors.black54,
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _removeImage,
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color? textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, Color? fillColor, Color? borderColor, Color focusColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: focusColor)),
    );
  }
}