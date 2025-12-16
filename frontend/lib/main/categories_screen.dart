import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/category.dart';
import '../../services/category_service.dart';
import '../../widgets/custom_text_field.dart';
import '../main/product_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final categories = await _categoryService.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load categories: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<Category> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    return _categories
        .where(
          (c) =>
              c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.description.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  Future<Uint8List?> _pickImageUniversal() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null) return null;
      return result.files.single.bytes;
    } else {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (image == null) return null;
      return await image.readAsBytes();
    }
  }

  // Show full-screen modal for add/edit
  void _showCategoryModal({Category? category}) {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');
    final formKey = GlobalKey<FormState>();
    Uint8List? pickedImage;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // full screen
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> chooseImage() async {
              final bytes = await _pickImageUniversal();
              if (bytes != null) {
                // update modal state only
                setModalState(() {
                  pickedImage = bytes;
                });
              }
            }

            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setModalState(() => saving = true);
              try {
                if (category == null) {
                  final newCat = Category(
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await _categoryService.addCategory(newCat, pickedImage);
                } else {
                  final updated = category.copyWith(
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    updatedAt: DateTime.now(),
                  );
                  await _categoryService.updateCategory(updated, pickedImage);
                }

                if (mounted) {
                  Navigator.pop(context);
                  await _loadCategories();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        category == null
                            ? 'Category added successfully'
                            : 'Category updated successfully',
                      ),
                      backgroundColor: Theme.of(context).cardColor,
                    ),
                  );
                }
              } catch (e) {
                setModalState(() => saving = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.86,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 18.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 80.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                ? Colors.grey[400]
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Text(
                        category == null ? 'Add Category' : 'Edit Category',
                        style: GoogleFonts.roboto(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? Colors.grey[800]
                              : Colors.white,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      GestureDetector(
                        onTap: chooseImage,
                        child: Container(
                          height: 180.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.grey[300]!
                                  : Colors.white24,
                            ),
                            color: Theme.of(context).cardColor,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child: pickedImage != null
                                ? Image.memory(pickedImage!, fit: BoxFit.cover)
                                : (category?.imagePath != null
                                      ? Image.network(
                                          "http://localhost:3000${category!.imagePath}",
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, _, __) =>
                                              _emptyImagePlaceholder(),
                                        )
                                      : _emptyImagePlaceholder()),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Tap image to change or add',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? Colors.grey[600]
                              : Colors.white70,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Form(
                            key: formKey,
                            child: Column(
                              children: [
                                SizedBox(height: 8.h),
                                CustomTextField(
                                  controller: nameCtrl,
                                  labelText: 'Category Name',
                                  prefixIcon: Icons.category,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Please enter name'
                                      : null,
                                ),
                                SizedBox(height: 12.h),
                                CustomTextField(
                                  controller: descCtrl,
                                  labelText: 'Description',
                                  prefixIcon: Icons.description,
                                  maxLines: 4,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Please enter description'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Colors.grey[200]
                                    : Theme.of(context).cardColor,
                                foregroundColor:
                                    Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Colors.grey[800]
                                    : Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text('Cancel', style: GoogleFonts.inter()),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: saving ? null : submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B6F47),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: saving
                                  ? SizedBox(
                                      height: 18.h,
                                      width: 18.h,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      category == null ? 'Add' : 'Update',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyImagePlaceholder() {
    return Container(
      color: Theme.of(context).cardColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: 48.sp,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[600]
                  : Colors.white70,
            ),
            SizedBox(height: 8.h),
            Text(
              'Add an image',
              style: GoogleFonts.inter(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[600]
                    : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Category category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Delete "${category.name}"?',
          style: GoogleFonts.inter(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey[800]
                : Colors.white,
          ),
        ),
        content: Text(
          'This action cannot be undone.',
          style: GoogleFonts.inter(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey[600]
                : Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _categoryService.deleteCategory(category.id!);
                if (mounted) {
                  Navigator.pop(ctx);
                  await _loadCategories();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category deleted')),
                  );
                }
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // _buildTopBar removed (replaced by _buildHeader)

  Widget _buildCategoryCard(Category c) {
    return GestureDetector(
      onTap: () => _navigateToProducts(c),
      onLongPress: () => _showCategoryOptions(c),
      child: Container(
        height: 160.h,
        margin: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey.shade600.withValues(alpha: 0.5)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            children: [
              // quick actions (edit/delete)
              Positioned(
                top: 10.h,
                right: 10.w,
                child: Row(
                  children: [
                    _circleIcon(
                      icon: Icons.edit_outlined,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[800]!
                          : Colors.white,
                      bg: Colors.black.withOpacity(0.35),
                      onTap: () => _showCategoryModal(category: c),
                    ),
                    SizedBox(width: 8.w),
                    _circleIcon(
                      icon: Icons.delete_outline,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[800]!
                          : Colors.white,
                      bg: Colors.red.withOpacity(0.35),
                      onTap: () => _showDeleteConfirmation(c),
                    ),
                  ],
                ),
              ),
              // background image or color
              Positioned.fill(
                child: c.imagePath != null
                    ? Image.network(
                        "http://localhost:3000${c.imagePath}",
                        fit: BoxFit.cover,
                      )
                    : Container(color: Theme.of(context).cardColor),
              ),
              // dark gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.35),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // text
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 18.h,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        c.name.toUpperCase(),
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              blurRadius: 6,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.white.withOpacity(0.4)
                                  : Colors.black.withOpacity(0.4),
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        c.description,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 14.sp,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              // bottom action bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.white.withOpacity(0.28)
                        : Colors.black.withOpacity(0.28),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showCategoryModal(category: c),
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          'Edit',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      TextButton.icon(
                        onPressed: () => _showDeleteConfirmation(c),
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          'Delete',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryOptions(Category category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: Text(
                'Edit Category',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showCategoryModal(category: category);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.white),
              title: Text(
                'Delete Category',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteConfirmation(category);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProducts(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductsScreen(category: category)),
    );
  }

  Widget _circleIcon({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18.sp),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryModal(),
        backgroundColor: const Color(0xFF8B6F47),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(color: Colors.red),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(
                        top: 12.h,
                        bottom: MediaQuery.of(context).padding.bottom + 96.h,
                      ),
                      itemCount: _filteredCategories.length,
                      itemBuilder: (ctx, idx) =>
                          _buildCategoryCard(_filteredCategories[idx]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top header with title and search; no static nav items to keep layout reusable.
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Categories',
                style: GoogleFonts.roboto(
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[800]
                      : Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).cardColor,
                ),
                child: Icon(
                  Icons.category_outlined,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[800]
                      : Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            height: 52.h,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF8B6F47)
                    : Colors.white.withValues(alpha: 0.25),
                width: 1.1,
              ),
              boxShadow: Theme.of(context).brightness == Brightness.light
                  ? [
                      BoxShadow(
                        color: Colors.grey.shade600.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: TextField(
              style: GoogleFonts.inter(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[800]
                    : Colors.white,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[800]
                      : Colors.white,
                ),
                hintText: 'Search categories...',
                hintStyle: GoogleFonts.inter(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[600]
                      : Colors.white70,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
