import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/customer.dart';
import '../models/product.dart';
import '../services/bill_service.dart';
import '../services/customer_service.dart';
import '../services/product_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final BillService _billService = BillService();
  final CustomerService _customerService = CustomerService();
  final ProductService _productService = ProductService();

  bool _loading = true;
  String? _error;

  int _totalCustomers = 0;
  double _totalSales = 0.0;
  double _totalProfit = 0.0;
  String _trendingItem = 'No data';
  int _trendingItemCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load all data concurrently
      final results = await Future.wait([
        _customerService.getAllCustomers(),
        _billService.getBills(),
        _productService.getAllProducts(),
      ]);

      final customers = results[0] as List<Customer>;
      final bills = results[1] as List<BillRecord>;
      final products = results[2] as List<Product>;

      // Calculate metrics
      _totalCustomers = customers.length;

      _totalSales = bills.fold(0.0, (sum, bill) => sum + bill.bill.totalAmount);

      // Calculate profit (assuming 30% profit margin for simplicity)
      _totalProfit = _totalSales * 0.3;

      // Find trending item (most sold product)
      await _calculateTrendingItem(bills, products);

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _calculateTrendingItem(
    List<BillRecord> bills,
    List<Product> products,
  ) async {
    if (bills.isEmpty || products.isEmpty) {
      _trendingItem = 'No sales data';
      _trendingItemCount = 0;
      return;
    }

    // Count product sales by getting detailed bill information
    Map<int, int> productSales = {};

    try {
      // Get detailed bill information with items for each bill
      for (final billRecord in bills.take(50)) {
        // Limit to avoid too many API calls
        final billDetail = await _billService.getBillWithItems(
          billRecord.bill.id!,
        );
        if (billDetail != null) {
          for (final item in billDetail.items) {
            final productId = item.productId;
            final quantity = item.quantity;
            productSales[productId] = (productSales[productId] ?? 0) + quantity;
          }
        }
      }
    } catch (e) {
      _trendingItem = 'Error loading sales data';
      _trendingItemCount = 0;
      return;
    }

    if (productSales.isEmpty) {
      _trendingItem = 'No sales data';
      _trendingItemCount = 0;
      return;
    }

    // Find most sold product
    int mostSoldProductId = productSales.keys.first;
    int maxQuantity = productSales[mostSoldProductId]!;

    for (final entry in productSales.entries) {
      if (entry.value > maxQuantity) {
        mostSoldProductId = entry.key;
        maxQuantity = entry.value;
      }
    }

    // Find product name
    final trendingProduct = products.firstWhere(
      (p) => p.id == mostSoldProductId,
      orElse: () => Product(
        id: 0,
        uniqueCode: '',
        name: 'Unknown Product',
        description: '',
        categoryId: 0,
        price: 0,
        stockQuantity: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    _trendingItem = trendingProduct.name;
    _trendingItemCount = maxQuantity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _buildErrorState()
                  : _buildDashboardContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 20.h),
      child: Row(
        children: [
          Text(
            'Dashboard',
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
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.white
                  : Colors.white12,
              boxShadow: Theme.of(context).brightness == Brightness.light
                  ? [
                      BoxShadow(
                        color: Colors.grey.shade600.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.analytics_outlined,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[800]
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: Colors.red[400]),
          SizedBox(height: 16.h),
          Text(
            'Failed to load dashboard data',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[800]
                  : Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[600]
                  : Colors.white70,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: _loadDashboardData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B6F47),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        child: Column(
          children: [
            // Top row - Customers and Sales
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Customers',
                    value: _totalCustomers.toString(),
                    icon: Icons.people_outline,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Sales',
                    value: '₹${_totalSales.toStringAsFixed(2)}',
                    icon: Icons.trending_up,
                    color: const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            // Second row - Profit and Trending Item
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Profit',
                    value: '₹${_totalProfit.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF8B6F47),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(child: _buildTrendingCard()),
              ],
            ),
            SizedBox(height: 24.h),
            // Summary card
            _buildSummaryCard(),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.grey.shade600.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: color, size: 24.sp),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[600]
                  : Colors.white70,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[800]
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.grey.shade600.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.star_outline,
                  color: const Color(0xFFFF9800),
                  size: 24.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Trending Item',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[600]
                  : Colors.white70,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _trendingItem,
            style: GoogleFonts.roboto(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[800]
                  : Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            'Sold: $_trendingItemCount units',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFFFF9800),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.grey.shade600.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B6F47).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.summarize_outlined,
                  color: const Color(0xFF8B6F47),
                  size: 28.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Business Summary',
                style: GoogleFonts.roboto(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[800]
                      : Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildSummaryRow('Active Customers', '$_totalCustomers'),
          SizedBox(height: 12.h),
          _buildSummaryRow(
            'Revenue Generated',
            '₹${_totalSales.toStringAsFixed(2)}',
          ),
          SizedBox(height: 12.h),
          _buildSummaryRow(
            'Estimated Profit',
            '₹${_totalProfit.toStringAsFixed(2)}',
          ),
          SizedBox(height: 12.h),
          _buildSummaryRow('Top Selling Item', _trendingItem),
          if (_trendingItemCount > 0) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                SizedBox(width: 120.w), // Align with value column
                Text(
                  '($_trendingItemCount units sold)',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFFFF9800),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120.w,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[600]
                  : Colors.white70,
            ),
          ),
        ),
        Text(
          ': ',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey[600]
                : Colors.white70,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[800]
                  : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
