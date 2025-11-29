import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/api_services.dart';
import '../../models/category.dart';

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

  File? _selectedMedia;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // --- LOGIKA FETCH CATEGORY ---
  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      _categories = await _apiServices.getCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat kategori: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA AMBIL GAMBAR ---
  Future<void> _pickImage() async {
    FocusScope.of(context).unfocus(); // Tutup keyboard
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, 
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedMedia = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error pick image: $e");
    }
  }

  void _removeImage() {
    setState(() {
      _selectedMedia = null;
    });
  }

  // --- LOGIKA NAVIGASI AMAN (CLOSE) ---
  Future<void> _handleClose() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));

    bool hasContent = _titleController.text.isNotEmpty ||
        _contentController.text.isNotEmpty ||
        _selectedMedia != null;

    if (!mounted) return;

    if (hasContent) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Buang postingan?"),
          content: const Text("Perubahan yang belum disimpan akan hilang."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Buang", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (shouldDiscard == true) {
        if (!mounted) return;
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  // --- LOGIKA SUBMIT POST ---
  Future<void> _createPost() async {
    FocusScope.of(context).unfocus();

    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul, isi, dan kategori wajib diisi.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newPost = await _apiServices.createPostWithMedia(
        _titleController.text,
        _contentController.text,
        _selectedCategory!.id,
        _tagsController.text,
        _selectedMedia,
      );

      if (newPost != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Postingan berhasil diterbitkan!')));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: ${e.toString()}')));
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
    // --- SETTING TEMA ---
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final primaryColor = theme.primaryColor;
    final cardColor = theme.cardTheme.color ?? Colors.white;
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) { if (didPop) return; _handleClose(); },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Posting", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- DROPDOWN KATEGORI ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Category>(
                    dropdownColor: cardColor,
                    value: _selectedCategory,
                    hint: Text("Pilih Topik", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    icon: Icon(Icons.keyboard_arrow_down, color: primaryColor),
                    isDense: true,
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.name, style: TextStyle(color: textPrimary)),
                      );
                    }).toList(),
                    onChanged: (Category? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // --- INPUT JUDUL ---
              TextField(
                controller: _titleController,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Judul Diskusi',
                  hintStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.bold),
                  border: InputBorder.none,
                ),
              ),

              const SizedBox(height: 8),

              // --- INPUT KONTEN ---
              TextField(
                controller: _contentController,
                style: TextStyle(fontSize: 16, color: textPrimary, height: 1.5),
                decoration: InputDecoration(
                  hintText: 'Apa yang ingin Anda diskusikan?',
                  hintStyle: TextStyle(color: textSecondary),
                  border: InputBorder.none,
                ),
                maxLines: null,
                minLines: 3,
              ),

              const SizedBox(height: 16),

              // --- INPUT TAGS ---
              Row(
                children: [
                  Icon(Icons.tag, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _tagsController,
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Tags (pisahkan dengan koma)',
                        hintStyle: TextStyle(color: textSecondary),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),

              Divider(height: 32, color: theme.dividerColor),

              // --- MEDIA / UPLOAD FOTO ---
              if (_selectedMedia != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _selectedMedia!,
                        width: double.infinity,
                        height: 250, 
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _removeImage,
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.7),
                          radius: 14,
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    )
                  ],
                )
              else
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          "Tambahkan Foto / Video",
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 40), 
            ],
          ),
        ),
      ),
    );
  }
}