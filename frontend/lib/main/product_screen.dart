import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/custom_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ProductsScreen extends StatefulWidget {
  final Category category;
  const ProductsScreen({super.key, required this.category});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  final String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProductsByCategory();
  }

  Future<void> _loadProductsByCategory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final all = await _productService.getAllProducts();
      if (mounted) {
        setState(() {
          _products = all
              .where((p) => p.categoryId == widget.category.id)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load products: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.uniqueCode.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  Future<Uint8List?> _pickImage() async {
    if (kIsWeb) {
      final res = await FilePicker.platform.pickFiles(type: FileType.image);
      return res?.files.single.bytes;
    } else {
      final XFile? file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      return await file?.readAsBytes();
    }
  }

  void _showProductDialog({Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final descController = TextEditingController(
      text: product?.description ?? '',
    );
    final priceController = TextEditingController(
      text: product?.price.toString() ?? '',
    );
    final stockController = TextEditingController(
      text: product?.stockQuantity.toString() ?? '',
    );
    final codeController = TextEditingController(
      text: product?.uniqueCode ?? '',
    );
    final formKey = GlobalKey<FormState>();
    Uint8List? imageBytes;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.86,
                  padding: EdgeInsets.all(18.w),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 80.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        product == null ? 'Add Product' : 'Edit Product',
                        style: GoogleFonts.roboto(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? Colors.grey[800]
                              : Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      GestureDetector(
                        onTap: () async {
                          final b = await _pickImage();
                          if (b != null) setStateModal(() => imageBytes = b);
                        },
                        child: Container(
                          height: 160.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            color: Theme.of(context).cardColor,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: imageBytes != null
                                ? Image.memory(imageBytes!, fit: BoxFit.cover)
                                : (product?.imagePath != null
                                      ? Image.network(
                                          "http://localhost:3000${product!.imagePath}",
                                          fit: BoxFit.cover,
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.add_a_photo,
                                            size: 36.sp,
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.light
                                                ? Colors.grey[600]
                                                : Theme.of(context)
                                                      .iconTheme
                                                      .color
                                                      ?.withValues(alpha: 0.7),
                                          ),
                                        )),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Form(
                            key: formKey,
                            child: Column(
                              children: [
                                CustomTextField(
                                  controller: nameController,
                                  labelText: 'Product Name',
                                  prefixIcon: Icons.label,
                                  validator: (v) =>
                                      v!.isEmpty ? 'Enter product name' : null,
                                ),
                                SizedBox(height: 10.h),
                                CustomTextField(
                                  controller: descController,
                                  labelText: 'Description',
                                  prefixIcon: Icons.description,
                                  maxLines: 2,
                                  validator: (v) =>
                                      v!.isEmpty ? 'Enter description' : null,
                                ),
                                SizedBox(height: 10.h),
                                CustomTextField(
                                  controller: codeController,
                                  labelText: '5-digit Product Code',
                                  prefixIcon: Icons.qr_code,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Enter code';
                                    }
                                    if (v.length != 5) {
                                      return 'Must be 5 digits';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 10.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        controller: priceController,
                                        labelText: 'Price',
                                        prefixIcon: Icons.currency_rupee,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: CustomTextField(
                                        controller: stockController,
                                        labelText: 'Stock',
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 18.h),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      setStateModal(() => saving = true);
                                      try {
                                        if (product == null) {
                                          final newP = Product(
                                            id: 0,
                                            uniqueCode: codeController.text
                                                .trim(),
                                            name: nameController.text.trim(),
                                            description: descController.text
                                                .trim(),
                                            categoryId: widget.category.id!,
                                            price: double.parse(
                                              priceController.text,
                                            ),
                                            stockQuantity: int.parse(
                                              stockController.text,
                                            ),
                                            createdAt: DateTime.now(),
                                            updatedAt: DateTime.now(),
                                          );
                                          await _productService.addProduct(
                                            newP,
                                            webImage: imageBytes,
                                          );
                                        } else {
                                          final updated = product.copyWith(
                                            uniqueCode: codeController.text
                                                .trim(),
                                            name: nameController.text.trim(),
                                            description: descController.text
                                                .trim(),
                                            price: double.parse(
                                              priceController.text,
                                            ),
                                            stockQuantity: int.parse(
                                              stockController.text,
                                            ),
                                            updatedAt: DateTime.now(),
                                          );
                                          await _productService.updateProduct(
                                            updated,
                                            webImage: imageBytes,
                                          );
                                        }
                                        if (mounted) {
                                          Navigator.pop(context);
                                          await _loadProductsByCategory();
                                        }
                                      } catch (e) {
                                        setStateModal(() => saving = false);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    },
                              child: saving
                                  ? SizedBox(
                                      height: 18.h,
                                      width: 18.h,
                                      child: CircularProgressIndicator(
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.light
                                            ? const Color(0xFF8B6F47)
                                            : Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(product == null ? 'Add' : 'Update'),
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

  Future<void> _deleteProduct(Product p) async {
    try {
      await _productService.deleteProduct(p.id!);
      await _loadProductsByCategory();
    } catch (e) {
      final s = e.toString();
      final lower = s.toLowerCase();

      // If backend returned a 400 referencing bill items, show a clear message
      if (s.contains('API_ERROR:400') || lower.contains('referenc')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You cannot delete this product because you used it in bills',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildGridItem(Product p) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: Theme.of(context).cardColor,
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: Colors.grey.shade600.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
                child: p.imagePath != null
                    ? Image.network(
                        "http://localhost:3000${p.imagePath}",
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: Theme.of(context).cardColor,
                        child: Center(
                          child: Icon(
                            Icons.diamond_outlined,
                            size: 36.sp,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                ? Colors.grey[800]!.withValues(alpha: 0.7)
                                : Theme.of(context).textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: GoogleFonts.roboto(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[800]
                          : Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Code: ${p.uniqueCode}',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[600]
                          : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹ ${p.price.toStringAsFixed(2)}',
                        style: GoogleFonts.roboto(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8B6F47),
                        ),
                      ),
                      PopupMenuButton<String>(
                        color: Theme.of(context).cardColor,
                        icon: Icon(
                          Icons.more_vert,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        onSelected: (v) {
                          if (v == 'edit') _showProductDialog(product: p);
                          if (v == 'delete') _deleteProduct(p);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(
                              'Edit',
                              style: GoogleFonts.inter(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: GoogleFonts.inter(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          widget.category.name,
          style: GoogleFonts.roboto(
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontSize: 22.sp,
          ),
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).appBarTheme.foregroundColor,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).iconTheme.color,
              ),
            )
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _filteredProducts.isEmpty
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 64.sp,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'No products in this category. Tap + to add products.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: GridView.builder(
                itemCount: _filteredProducts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 14.h,
                ),
                itemBuilder: (ctx, i) {
                  return _buildGridItem(_filteredProducts[i]);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        backgroundColor: const Color(0xFF8B6F47),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: Container(
        height: 80.h,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Text(
            '',
          ), // keep bottom bar simple; your main app likely draws nav elsewhere
        ),
      ),
    );
  }
}
