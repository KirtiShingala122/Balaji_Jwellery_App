import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

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
  String _searchQuery = '';

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
      final allProducts = await _productService.getAllProducts();
      setState(() {
        _products = allProducts
            .where((p) => p.categoryId == widget.category.id)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load products: $e';
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(90.h),
        child: SafeArea(child: _buildHeader(context)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildError()
                : _buildGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEF),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0B132B),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            "${widget.category.name} Products",
            style: GoogleFonts.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0B132B),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 280.w,
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: 'Search products...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          CustomButton(
            text: 'Add Product',
            icon: Icons.add,
            backgroundColor: const Color(0xFF0B132B),
            onPressed: _showAddProductDialog,
            width: 150.w,
          ),
        ],
      ),
    );
  }

  Widget _buildError() => Center(
    child: Text(
      _errorMessage ?? "Error loading products",
      style: GoogleFonts.poppins(color: Colors.red, fontSize: 16.sp),
    ),
  );

  Widget _buildGrid() {
    final filtered = _filteredProducts;
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          "No products found",
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 18.sp),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) =>
            _buildProductCard(filtered[index], index),
      ),
    );
  }

  int _getCrossAxisCount() {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    return 2;
  }

  Widget _buildProductCard(Product p, int index) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  "http://localhost:3000${p.imagePath}",
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) => Container(
                    color: Colors.grey.shade200,
                    height: 100,
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                ),
              ),
            SizedBox(height: 8.h),
            Text(
              p.name,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18.sp,
                color: const Color(0xFF0B132B),
              ),
            ),
            Text(
              p.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "₹${p.price}",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE43D60),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _showProductDialog(product: p),
                      icon: const Icon(Icons.edit, color: Colors.blue),
                    ),
                    IconButton(
                      onPressed: () => _deleteProduct(p.id!),
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  void _showAddProductDialog() => _showProductDialog();

  void _showProductDialog({Product? product}) {
    final formKey = GlobalKey<FormState>();
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

    Uint8List? imageBytes;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          product == null ? "Add Product" : "Edit Product",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                CustomTextField(
                  controller: nameController,
                  labelText: "Product Name",
                  prefixIcon: Icons.label,
                  validator: (v) => v!.isEmpty ? "Enter product name" : null,
                ),
                SizedBox(height: 10.h),
                CustomTextField(
                  controller: descController,
                  labelText: "Description",
                  prefixIcon: Icons.description,
                  maxLines: 2,
                  validator: (v) => v!.isEmpty ? "Enter description" : null,
                ),
                SizedBox(height: 10.h),
                CustomTextField(
                  controller: codeController,
                  labelText: "5-digit Product Code",
                  prefixIcon: Icons.qr_code,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Enter product code";
                    if (v.length != 5) return "Code must be 5 digits";
                    return null;
                  },
                ),
                SizedBox(height: 10.h),
                GestureDetector(
                  onTap: () async {
                    final bytes = await _pickImageUniversal();
                    if (bytes != null) setState(() => imageBytes = bytes);
                  },
                  child: _buildImagePreview(imageBytes, product),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: priceController,
                        labelText: "Price",
                        prefixIcon: Icons.currency_rupee,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: CustomTextField(
                        controller: stockController,
                        labelText: "Stock",
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          CustomButton(
            text: product == null ? "Add" : "Update",
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final newProduct = Product(
                id: product?.id ?? 0,
                uniqueCode: codeController.text.trim(),
                name: nameController.text.trim(),
                description: descController.text.trim(),
                categoryId: widget.category.id!,
                price: double.parse(priceController.text),
                stockQuantity: int.parse(stockController.text),
                createdAt: product?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );

              try {
                await _uploadProduct(newProduct, imageBytes, product != null);
                if (mounted) {
                  Navigator.pop(context);
                  _loadProductsByCategory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        product == null
                            ? "Product Added Successfully"
                            : "Product Updated Successfully",
                      ),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            backgroundColor: const Color(0xFF0B132B),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(Uint8List? bytes, Product? product) {
    if (bytes != null) {
      return Image.memory(bytes, height: 120, fit: BoxFit.cover);
    }
    if (product?.imagePath != null) {
      return Image.network(
        "http://localhost:3000${product!.imagePath}",
        height: 120,
        fit: BoxFit.cover,
      );
    }
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: const Center(child: Icon(Icons.camera_alt, color: Colors.grey)),
    );
  }

  Future<void> _uploadProduct(
    Product product,
    Uint8List? imageBytes,
    bool isUpdate,
  ) async {
    final dio = Dio();
    final url = isUpdate
        ? "http://localhost:3000/api/products/${product.id}"
        : "http://localhost:3000/api/products";

    final formData = FormData.fromMap({
      "uniqueCode": product.uniqueCode,
      "name": product.name,
      "description": product.description,
      "categoryId": product.categoryId.toString(),
      "price": product.price.toString(),
      "stockQuantity": product.stockQuantity.toString(),
      if (imageBytes != null)
        "image": MultipartFile.fromBytes(imageBytes, filename: "product.jpg"),
    });

    if (isUpdate) {
      await dio.put(url, data: formData);
    } else {
      await dio.post(url, data: formData);
    }
  }

  Future<void> _deleteProduct(int id) async {
    await _productService.deleteProduct(id);
    _loadProductsByCategory();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Product deleted")));
  }
}
