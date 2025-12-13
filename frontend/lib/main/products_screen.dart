import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/product_service.dart';
import '../widgets/custom_button.dart';

class ProductsScreen extends StatefulWidget {
  final Category category;

  const ProductsScreen({super.key, required this.category});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAdmin = true; // Set based on your auth logic
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, In Stock, Low Stock
  String _selectedSort = 'Name'; // Name, Price Low, Price High, Newest

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _loadProducts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Replace with actual API call filtered by category
      // final products = await _productService.getProductsByCategory(widget.category.id);

      // Mock data for demonstration
      await Future.delayed(const Duration(milliseconds: 800));
      _products = _generateMockProducts();
      _applyFiltersAndSort();
      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load products: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Product> _generateMockProducts() {
    // Generate mock products based on category
    return List.generate(
      12,
      (index) => Product(
        id: index + 1,
        uniqueCode: 'JWL${1000 + index}',
        name: '${widget.category.name} ${index + 1}',
        description:
            'Beautiful ${widget.category.name.toLowerCase()} with premium quality craftsmanship',
        categoryId: widget.category.id ?? 1,
        price: 1500 + (index * 250).toDouble(),
        stockQuantity: index % 3 == 0 ? 3 : 15 + index,
        imagePath: null,
        createdAt: DateTime.now().subtract(Duration(days: index)),
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _applyFiltersAndSort() {
    _filteredProducts = List.from(_products);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredProducts = _filteredProducts.where((product) {
        return product.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            product.uniqueCode.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
      }).toList();
    }

    // Apply stock filter
    if (_selectedFilter == 'In Stock') {
      _filteredProducts = _filteredProducts
          .where((p) => p.stockQuantity > 5)
          .toList();
    } else if (_selectedFilter == 'Low Stock') {
      _filteredProducts = _filteredProducts.where((p) => p.isLowStock).toList();
    }

    // Apply sorting
    switch (_selectedSort) {
      case 'Name':
        _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Price Low':
        _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price High':
        _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Newest':
        _filteredProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchAndFilters(),
            _buildStatsBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingWidget()
                  : _errorMessage != null
                  ? _buildErrorWidget()
                  : _buildProductsGrid(),
            ),
          ],
        ),
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddProductDialog,
              backgroundColor: const Color(0xFFB48F85),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Add Product',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            )
          : null,
    );
  }

  // App Bar with back button
  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category.name,
                  style: GoogleFonts.poppins(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  widget.category.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.favorite_border,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {},
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFB48F85),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '0',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Search and Filter Bar
  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: Column(
        children: [
          // Search Bar
          Container(
            height: 48.h,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F6),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              onChanged: (value) {
                _searchQuery = value;
                _applyFiltersAndSort();
              },
              style: GoogleFonts.poppins(fontSize: 14.sp),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xFFB48F85)),
                hintText: 'Search products...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.grey[500],
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Filter and Sort Chips
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', _selectedFilter == 'All', () {
                        setState(() => _selectedFilter = 'All');
                        _applyFiltersAndSort();
                      }),
                      SizedBox(width: 8.w),
                      _buildFilterChip(
                        'In Stock',
                        _selectedFilter == 'In Stock',
                        () {
                          setState(() => _selectedFilter = 'In Stock');
                          _applyFiltersAndSort();
                        },
                      ),
                      SizedBox(width: 8.w),
                      _buildFilterChip(
                        'Low Stock',
                        _selectedFilter == 'Low Stock',
                        () {
                          setState(() => _selectedFilter = 'Low Stock');
                          _applyFiltersAndSort();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              PopupMenuButton<String>(
                icon: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB48F85),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sort, color: Colors.white, size: 20),
                      SizedBox(width: 4.w),
                      Text(
                        'Sort',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                onSelected: (value) {
                  setState(() => _selectedSort = value);
                  _applyFiltersAndSort();
                },
                itemBuilder: (context) => [
                  _buildSortMenuItem('Name', Icons.sort_by_alpha),
                  _buildSortMenuItem('Price Low', Icons.arrow_downward),
                  _buildSortMenuItem('Price High', Icons.arrow_upward),
                  _buildSortMenuItem('Newest', Icons.new_releases),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB48F85) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(String label, IconData icon) {
    return PopupMenuItem(
      value: label,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFB48F85), size: 20),
          SizedBox(width: 12.w),
          Text(label, style: GoogleFonts.poppins(fontSize: 14.sp)),
        ],
      ),
    );
  }

  // Stats Bar
  Widget _buildStatsBar() {
    int totalProducts = _products.length;
    int inStock = _products.where((p) => p.stockQuantity > 5).length;
    int lowStock = _products.where((p) => p.isLowStock).length;

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFB48F85).withOpacity(0.15),
            const Color(0xFF8B7E74).withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFB48F85).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.inventory_2,
            'Total',
            totalProducts.toString(),
            Colors.blue,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            Icons.check_circle,
            'In Stock',
            inStock.toString(),
            Colors.green,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            Icons.warning_amber_rounded,
            'Low Stock',
            lowStock.toString(),
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A3A),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 50.h, width: 1, color: Colors.grey[300]);
  }

  // Products Grid
  Widget _buildProductsGrid() {
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              'No products found',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                color: Colors.grey[600],
              ),
            ),
            if (_searchQuery.isNotEmpty || _selectedFilter != 'All') ...[
              SizedBox(height: 12.h),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedFilter = 'All';
                  });
                  _applyFiltersAndSort();
                },
                icon: const Icon(Icons.refresh),
                label: Text('Clear Filters', style: GoogleFonts.poppins()),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB48F85),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: GridView.builder(
            padding: EdgeInsets.all(16.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16.h,
              crossAxisSpacing: 16.w,
              childAspectRatio: 0.75,
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              return _buildProductCard(_filteredProducts[index]);
            },
          ),
        );
      },
    );
  }

  // Product Card
  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => _showProductDetails(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Stack(
              children: [
                Container(
                  height: 180.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFB48F85).withOpacity(0.3),
                        const Color(0xFF8B7E74).withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16.r),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.diamond_outlined,
                      size: 60,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),

                // Stock Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: product.isLowStock ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      product.isLowStock ? 'Low Stock' : 'In Stock',
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Admin Actions
                if (_isAdmin)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        _buildSmallIconButton(
                          Icons.edit_outlined,
                          () => _showEditProductDialog(product),
                        ),
                        SizedBox(width: 4.w),
                        _buildSmallIconButton(
                          Icons.delete_outline,
                          () => _showDeleteConfirmation(product),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Product Details
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.uniqueCode,
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        color: const Color(0xFFB48F85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3A3A3A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      product.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${product.price.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFB48F85),
                              ),
                            ),
                            Text(
                              'Stock: ${product.stockQuantity}',
                              style: GoogleFonts.poppins(
                                fontSize: 11.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB48F85),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallIconButton(
    IconData icon,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: color ?? const Color(0xFFB48F85),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  // Loading Widget
  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFB48F85)),
          SizedBox(height: 16.h),
          Text(
            'Loading products...',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Error Widget
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          SizedBox(height: 16.h),
          Text(
            _errorMessage ?? 'Something went wrong',
            style: GoogleFonts.poppins(fontSize: 16.sp, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          CustomButton(
            text: 'Retry',
            onPressed: _loadProducts,
            width: 120.w,
            backgroundColor: const Color(0xFFB48F85),
          ),
        ],
      ),
    );
  }

  // Product Details Dialog
  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: 500.w, maxHeight: 600.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB48F85), Color(0xFF8B7E74)],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.r),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: const Icon(
                        Icons.diamond,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: GoogleFonts.poppins(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            product.uniqueCode,
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        Icons.description,
                        'Description',
                        product.description,
                      ),
                      SizedBox(height: 16.h),
                      _buildDetailRow(
                        Icons.attach_money,
                        'Price',
                        '₹${product.price.toStringAsFixed(2)}',
                      ),
                      SizedBox(height: 16.h),
                      _buildDetailRow(
                        Icons.inventory,
                        'Stock Quantity',
                        '${product.stockQuantity} units',
                      ),
                      SizedBox(height: 16.h),
                      _buildDetailRow(
                        Icons.category,
                        'Category',
                        widget.category.name,
                      ),
                      SizedBox(height: 16.h),
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Created',
                        '${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}',
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20.r),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditProductDialog(product);
                        },
                        icon: const Icon(Icons.edit),
                        label: Text('Edit', style: GoogleFonts.poppins()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB48F85),
                          side: const BorderSide(color: Color(0xFFB48F85)),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Add to cart functionality
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.shopping_cart),
                        label: Text(
                          'Add to Cart',
                          style: GoogleFonts.poppins(),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB48F85),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF1E6E3),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: const Color(0xFFB48F85), size: 20),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A3A3A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Add Product Dialog (Placeholder)
  void _showAddProductDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Add Product functionality - To be implemented',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFFB48F85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  // Edit Product Dialog (Placeholder)
  void _showEditProductDialog(Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Edit ${product.name} - To be implemented',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFFB48F85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  // Delete Confirmation
  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Delete Product',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 15.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Delete product logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Product deleted successfully',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFFB48F85),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
