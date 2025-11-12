import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/category.dart';
import '../../services/category_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/category_card.dart';
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
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load categories: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Category> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    return _categories
        .where(
          (category) =>
              category.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              category.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? _buildErrorWidget()
                  : _buildResponsiveGrid(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        backgroundColor: const Color(0xFFB48F85),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Category',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // HEADER BAR
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Categories',
            style: GoogleFonts.poppins(
              fontSize: 26.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFB48F85),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Container(
              height: 45.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search categories...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.grey[500],
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 10.h,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // RESPONSIVE GRID
  Widget _buildResponsiveGrid() {
    final filteredCategories = _filteredCategories;
    if (filteredCategories.isEmpty) {
      return Center(
        child: Text(
          'No categories found',
          style: GoogleFonts.poppins(fontSize: 16.sp, color: Colors.grey[600]),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount;
          if (constraints.maxWidth >= 1400) {
            crossAxisCount = 4;
          } else if (constraints.maxWidth >= 1000) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth >= 700) {
            crossAxisCount = 2;
          } else {
            crossAxisCount = 1;
          }

          return GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 20.h,
              crossAxisSpacing: 20.w,
              childAspectRatio: 1.15,
            ),
            itemCount: filteredCategories.length,
            itemBuilder: (context, index) {
              final category = filteredCategories[index];
              return _buildCategoryCard(category);
            },
          );
        },
      ),
    );
  }

  // CATEGORY CARD
  Widget _buildCategoryCard(Category category) {
    return GestureDetector(
      onTap: () => _navigateToProducts(category),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1E6E3), // Light brown background
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.category_rounded,
                    color: const Color(0xFFB48F85),
                    size: 28.w,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'edit') _showEditCategoryDialog(category);
                    if (value == 'delete') _showDeleteConfirmation(category);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, color: Color(0xFFB48F85)),
                          SizedBox(width: 8.w),
                          const Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8.w),
                          const Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Category Name
            Text(
              category.name,
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5A4039), // darker brown text
              ),
            ),

            SizedBox(height: 8.h),

            // Description
            Text(
              category.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey[700],
              ),
            ),
            const Spacer(),

            // Bottom Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    SizedBox(width: 6.w),
                    Text(
                      'Updated today',
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEDDD8), // light brown chip
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'Active',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFB48F85),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64.w, color: Colors.red),
        SizedBox(height: 16.h),
        Text(
          _errorMessage ?? 'Unknown error',
          style: GoogleFonts.poppins(fontSize: 16.sp, color: Colors.red),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        CustomButton(
          text: 'Retry',
          onPressed: _loadCategories,
          width: 120.w,
          backgroundColor: const Color(0xFFB48F85),
        ),
      ],
    ),
  );

  // ADD / EDIT DIALOG
  void _showAddCategoryDialog() => _showCategoryDialog();
  void _showEditCategoryDialog(Category category) =>
      _showCategoryDialog(category: category);

  void _showCategoryDialog({Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(
      text: category?.description ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          category == null ? 'Add Category' : 'Edit Category',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFFB48F85),
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: nameController,
                labelText: 'Category Name',
                prefixIcon: Icons.category_outlined,
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter category name'
                    : null,
              ),
              SizedBox(height: 16.h),
              CustomTextField(
                controller: descriptionController,
                labelText: 'Description',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter description' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
          ),
          CustomButton(
            text: category == null ? 'Add' : 'Update',
            onPressed: () => _saveCategory(
              formKey,
              nameController.text,
              descriptionController.text,
              category,
            ),
            width: 100.w,
            backgroundColor: const Color(0xFFB48F85),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCategory(
    GlobalKey<FormState> formKey,
    String name,
    String description,
    Category? existingCategory,
  ) async {
    if (!formKey.currentState!.validate()) return;
    try {
      if (existingCategory == null) {
        final category = Category(
          name: name.trim(),
          description: description.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _categoryService.addCategory(category);
      } else {
        final updatedCategory = existingCategory.copyWith(
          name: name.trim(),
          description: description.trim(),
          updatedAt: DateTime.now(),
        );
        await _categoryService.updateCategory(updatedCategory);
      }

      if (mounted) {
        Navigator.pop(context);
        _loadCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existingCategory == null
                  ? 'Category added successfully'
                  : 'Category updated successfully',
            ),
            backgroundColor: const Color(0xFFB48F85),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _showDeleteConfirmation(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Delete Category',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          CustomButton(
            text: 'Delete',
            onPressed: () => _deleteCategory(category),
            backgroundColor: const Color(0xFFB48F85),
            width: 100.w,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    try {
      await _categoryService.deleteCategory(category.id!);
      if (mounted) {
        Navigator.pop(context);
        _loadCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category deleted successfully'),
            backgroundColor: Color(0xFFB48F85),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _navigateToProducts(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductsScreen(category: category),
      ),
    );
  }
}
