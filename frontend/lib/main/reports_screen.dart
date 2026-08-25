import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/report_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final ReportService _reportService = ReportService();

  bool _isLoading = true;
  String? _error;

  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _monthlySales = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _categoryBreakdown = [];

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const List<Color> _chartColors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _loadAll();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _reportService.getSummary(),
        _reportService.getMonthlySales(),
        _reportService.getTopProducts(),
        _reportService.getCategoryBreakdown(),
      ]);
      setState(() {
        _summary = results[0] as Map<String, dynamic>;
        _monthlySales = results[1] as List<Map<String, dynamic>>;
        _topProducts = results[2] as List<Map<String, dynamic>>;
        _categoryBreakdown = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
      _animCtrl.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(24.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSummaryCards(),
                              SizedBox(height: 28.h),
                              _buildSectionTitle('Monthly Sales (This Year)'),
                              SizedBox(height: 12.h),
                              _buildMonthlySalesChart(),
                              SizedBox(height: 28.h),
                              _buildSectionTitle('Top 5 Selling Products'),
                              SizedBox(height: 12.h),
                              _buildTopProductsChart(),
                              SizedBox(height: 28.h),
                              _buildSectionTitle('Revenue by Category'),
                              SizedBox(height: 12.h),
                              _buildCategoryBreakdown(),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0xFFE2E8F0), blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.analytics_rounded,
              color: const Color(0xFF1E3A8A), size: 28.w),
          SizedBox(width: 12.w),
          Text(
            'Reports & Analytics',
            style: GoogleFonts.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _loadAll,
            icon: Icon(Icons.refresh, color: const Color(0xFF3B82F6), size: 22.w),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E3A8A),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 52.w, color: Colors.red),
          SizedBox(height: 12.h),
          Text(_error!,
              style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.red),
              textAlign: TextAlign.center),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ─── Summary Cards ────────────────────────────────────────────────────────
  Widget _buildSummaryCards() {
    final cards = [
      {
        'label': 'Total Revenue',
        'value': '₹${_fmt(_summary['totalRevenue'])}',
        'icon': Icons.currency_rupee,
        'color': const Color(0xFF10B981),
      },
      {
        'label': 'Total Bills',
        'value': '${_summary['totalBills'] ?? 0}',
        'icon': Icons.receipt_long,
        'color': const Color(0xFF3B82F6),
      },
      {
        'label': 'Avg Bill Value',
        'value': '₹${_summary['avgBillValue'] ?? 0}',
        'icon': Icons.trending_up,
        'color': const Color(0xFFF59E0B),
      },
      {
        'label': 'Low Stock Items',
        'value': '${_summary['lowStockCount'] ?? 0}',
        'icon': Icons.warning_amber_rounded,
        'color': const Color(0xFFEF4444),
      },
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16.w,
      mainAxisSpacing: 16.h,
      childAspectRatio: 2.2,
      children: cards.map((c) => _buildSummaryCard(c)).toList(),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> c) {
    final color = c['color'] as Color;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(c['icon'] as IconData, color: color, size: 22.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(c['label'] as String,
                    style: GoogleFonts.poppins(
                        fontSize: 11.sp, color: Colors.grey[600])),
                Text(c['value'] as String,
                    style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Monthly Sales Bar Chart ──────────────────────────────────────────────
  Widget _buildMonthlySalesChart() {
    if (_monthlySales.isEmpty) {
      return _buildEmptyChart('No sales data for this year yet.');
    }

    final maxY = _monthlySales
        .map((e) => (e['revenue'] as num).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      height: 280.h,
      padding: EdgeInsets.all(20.w),
      decoration: _cardDecoration(),
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.25,
          barGroups: _monthlySales.asMap().entries.map((entry) {
            final i = entry.key;
            final data = entry.value;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (data['revenue'] as num).toDouble(),
                  color: const Color(0xFF3B82F6),
                  width: 18.w,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52.w,
                getTitlesWidget: (val, _) => Text(
                  '₹${_shortNum(val)}',
                  style: GoogleFonts.poppins(
                      fontSize: 9.sp, color: Colors.grey[600]),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= _monthlySales.length)
                    return const SizedBox();
                  final name =
                      (_monthlySales[idx]['monthName'] as String).substring(0, 3);
                  return Padding(
                    padding: EdgeInsets.only(top: 6.h),
                    child: Text(name,
                        style: GoogleFonts.poppins(
                            fontSize: 10.sp, color: Colors.grey[700])),
                  );
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (val) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  // ─── Top Products Horizontal Bar Chart ───────────────────────────────────
  Widget _buildTopProductsChart() {
    if (_topProducts.isEmpty) {
      return _buildEmptyChart('No sales data yet.');
    }

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: _cardDecoration(),
      child: Column(
        children: _topProducts.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final sold = (p['totalSold'] as num).toDouble();
          final maxSold = (_topProducts.first['totalSold'] as num).toDouble();
          final pct = maxSold > 0 ? sold / maxSold : 0.0;
          final color = _chartColors[i % _chartColors.length];

          return Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        p['name'] as String,
                        style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${sold.toInt()} sold • ₹${_fmt(p['totalRevenue'])}',
                      style: GoogleFonts.poppins(
                          fontSize: 11.sp, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8.h,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Category Breakdown Table ─────────────────────────────────────────────
  Widget _buildCategoryBreakdown() {
    if (_categoryBreakdown.isEmpty) {
      return _buildEmptyChart('No category data available.');
    }

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          // Header row
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.06),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14.r),
                topRight: Radius.circular(14.r),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: _headerCell('Category')),
                Expanded(child: _headerCell('Products')),
                Expanded(child: _headerCell('Sold')),
                Expanded(flex: 2, child: _headerCell('Revenue')),
              ],
            ),
          ),
          // Data rows
          ..._categoryBreakdown.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            return Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: i.isEven ? Colors.white : Colors.grey.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: _chartColors[i % _chartColors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(c['categoryName'] as String,
                            style: GoogleFonts.poppins(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1E293B))),
                      ],
                    ),
                  ),
                  Expanded(
                      child: _dataCell('${c['productCount']}')),
                  Expanded(child: _dataCell('${c['totalSold']}')),
                  Expanded(
                      flex: 2,
                      child: _dataCell(
                          '₹${_fmt(c['totalRevenue'])}',
                          bold: true)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _headerCell(String text) => Text(
        text,
        style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E3A8A)),
      );

  Widget _dataCell(String text, {bool bold = false}) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13.sp,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: bold ? const Color(0xFF10B981) : const Color(0xFF475569),
        ),
      );

  Widget _buildEmptyChart(String msg) => Container(
        height: 100.h,
        decoration: _cardDecoration(),
        child: Center(
          child: Text(msg,
              style: GoogleFonts.poppins(
                  fontSize: 14.sp, color: Colors.grey[500])),
        ),
      );

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      );

  String _fmt(dynamic val) {
    if (val == null) return '0';
    final n = double.tryParse(val.toString()) ?? 0.0;
    return n.toStringAsFixed(n == n.truncateToDouble() ? 0 : 2);
  }

  String _shortNum(double val) {
    if (val >= 100000) return '${(val / 100000).toStringAsFixed(1)}L';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toInt().toString();
  }
}
