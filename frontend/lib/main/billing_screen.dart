import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/bill.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final List<_InvoiceViewModel> _allInvoices = [];
  final List<String> _statusFilters = ['All', 'Paid', 'Pending', 'Overdue'];

  String _selectedStatus = 'All';
  String _selectedSort = 'Newest';
  DateTimeRange? _selectedRange;
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<_InvoiceViewModel> get _visibleInvoices => _filterAndSortInvoices();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _bootstrap();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _allInvoices
      ..clear()
      ..addAll(_generateMockInvoices());
    setState(() => _isLoading = false);
    _animationController.forward();
  }

  List<_InvoiceViewModel> _filterAndSortInvoices() {
    Iterable<_InvoiceViewModel> data = _allInvoices;

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      data = data.where(
        (invoice) =>
            invoice.bill.billNumber.toLowerCase().contains(query) ||
            invoice.customerName.toLowerCase().contains(query),
      );
    }

    if (_selectedStatus != 'All') {
      data = data.where(
        (invoice) =>
            invoice.bill.paymentStatus.toLowerCase() ==
            _selectedStatus.toLowerCase(),
      );
    }

    if (_selectedRange != null) {
      data = data.where(
        (invoice) =>
            invoice.bill.billDate.isAfter(
              _selectedRange!.start.subtract(const Duration(days: 1)),
            ) &&
            invoice.bill.billDate.isBefore(
              _selectedRange!.end.add(const Duration(days: 1)),
            ),
      );
    }

    final list = data.toList();

    switch (_selectedSort) {
      case 'Newest':
        list.sort((a, b) => b.bill.billDate.compareTo(a.bill.billDate));
        break;
      case 'Oldest':
        list.sort((a, b) => a.bill.billDate.compareTo(b.bill.billDate));
        break;
      case 'Amount High':
        list.sort((a, b) => b.bill.totalAmount.compareTo(a.bill.totalAmount));
        break;
      case 'Amount Low':
        list.sort((a, b) => a.bill.totalAmount.compareTo(b.bill.totalAmount));
        break;
    }

    return list;
  }

  double get _totalRevenue => _visibleInvoices.fold(
    0,
    (previousValue, element) => previousValue + element.bill.totalAmount,
  );

  int get _pendingCount => _visibleInvoices
      .where((invoice) => invoice.bill.paymentStatus.toLowerCase() == 'pending')
      .length;

  int get _overdueCount => _visibleInvoices
      .where((invoice) => invoice.bill.paymentStatus.toLowerCase() == 'overdue')
      .length;

  int get _paidCount => _visibleInvoices
      .where((invoice) => invoice.bill.paymentStatus.toLowerCase() == 'paid')
      .length;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedRange,
    );

    if (picked != null) {
      setState(() => _selectedRange = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = 'All';
      _selectedSort = 'Newest';
      _selectedRange = null;
      _searchController.clear();
    });
  }

  void _showInvoiceDetails(_InvoiceViewModel invoice) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          maxChildSize: 0.9,
          initialChildSize: 0.75,
          minChildSize: 0.6,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        height: 6.h,
                        width: 60.w,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1E6E3),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Color(0xFFB48F85),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invoice.bill.billNumber,
                                style: GoogleFonts.poppins(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3A3A3A),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Issued on · ${_formatDate(invoice.bill.billDate)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusChip(invoice.bill.paymentStatus),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Customer Information',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A3A3A),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildDetailRow(label: 'Name', value: invoice.customerName),
                    _buildDetailRow(
                      label: 'Contact',
                      value: invoice.customerContact,
                    ),
                    _buildDetailRow(
                      label: 'Email',
                      value: invoice.customerEmail,
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Items',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A3A3A),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    ...invoice.items.map(
                      (item) => Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7F6),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '${item.quantity} pcs · ₹${item.unitPrice.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${item.totalPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB48F85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Divider(color: Colors.grey[300]),
                    SizedBox(height: 16.h),
                    _buildSummaryRow('Subtotal', invoice.bill.subtotal),
                    _buildSummaryRow('Tax', invoice.bill.taxAmount),
                    _buildSummaryRow(
                      'Discount',
                      -invoice.bill.discountAmount,
                      valueColor: Colors.red[400],
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Grand Total',
                              style: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '₹${invoice.bill.totalAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB48F85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (invoice.bill.notes != null &&
                        invoice.bill.notes!.trim().isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(top: 12.h),
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1E6E3),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          invoice.bill.notes!,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            color: const Color(0xFF6B5E54),
                          ),
                        ),
                      ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showEditInvoiceDialog(invoice);
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(
                              'Edit Invoice',
                              style: GoogleFonts.poppins(),
                            ),
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
                              Navigator.of(context).pop();
                              _showMarkAsPaidDialog(invoice);
                            },
                            icon: const Icon(Icons.verified_outlined),
                            label: Text(
                              'Mark as Paid',
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
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateInvoiceSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _InvoiceFormSheet(
          onSubmit: (invoice) {
            setState(() => _allInvoices.insert(0, invoice));
          },
        );
      },
    );
  }

  void _showEditInvoiceDialog(_InvoiceViewModel invoice) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _InvoiceFormSheet(
          existingInvoice: invoice,
          onSubmit: (updated) {
            final index = _allInvoices.indexWhere(
              (element) => element.bill.billNumber == updated.bill.billNumber,
            );
            if (index != -1) {
              setState(() => _allInvoices[index] = updated);
            }
          },
        );
      },
    );
  }

  void _showMarkAsPaidDialog(_InvoiceViewModel invoice) {
    if (invoice.bill.paymentStatus.toLowerCase() == 'paid') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invoice is already marked as paid.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFB48F85),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            'Mark as Paid',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to mark invoice ${invoice.bill.billNumber} as paid?',
            style: GoogleFonts.poppins(fontSize: 14.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  final index = _allInvoices.indexWhere(
                    (element) =>
                        element.bill.billNumber == invoice.bill.billNumber,
                  );
                  if (index != -1) {
                    final updated = invoice.copyWith(
                      bill: invoice.bill.copyWith(paymentStatus: 'Paid'),
                    );
                    _allInvoices[index] = updated;
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB48F85),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              ),
              child: Text('Confirm', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterBar(),
            _buildSummaryStrip(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _isLoading
                    ? _buildLoadingState()
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: _visibleInvoices.isEmpty
                            ? _buildEmptyState()
                            : _buildResponsiveListing(),
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateInvoiceSheet,
        backgroundColor: const Color(0xFFB48F85),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Create Invoice',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: const BoxDecoration(
              color: Color(0xFFB48F85),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Billing & Invoices',
                style: GoogleFonts.poppins(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                'Track payments, generate invoices, and manage billing records',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _showExportDialog(),
            icon: const Icon(Icons.download_outlined, color: Colors.white),
          ),
          IconButton(
            onPressed: () => _showSettingsDialog(),
            icon: const Icon(Icons.tune_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F6),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.poppins(fontSize: 14.sp),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFB48F85),
                      ),
                      hintText: 'Search by invoice number or customer name...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.grey[500],
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              IconButton(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
                color: const Color(0xFFB48F85),
                tooltip: 'Clear filters',
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ..._statusFilters.map(
                (status) => _buildChip(
                  label: status,
                  isActive: _selectedStatus == status,
                  onSelected: () => setState(() => _selectedStatus = status),
                ),
              ),
              _buildOutlinedButton(
                icon: Icons.calendar_month_outlined,
                label: _selectedRange == null
                    ? 'Date Range'
                    : '${_formatDate(_selectedRange!.start)} · ${_formatDate(_selectedRange!.end)}',
                onPressed: _pickDateRange,
              ),
              PopupMenuButton<String>(
                initialValue: _selectedSort,
                onSelected: (value) => setState(() => _selectedSort = value),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'Newest', child: Text('Sort · Newest')),
                  PopupMenuItem(value: 'Oldest', child: Text('Sort · Oldest')),
                  PopupMenuItem(
                    value: 'Amount High',
                    child: Text('Amount · High to Low'),
                  ),
                  PopupMenuItem(
                    value: 'Amount Low',
                    child: Text('Amount · Low to High'),
                  ),
                ],
                child: _buildMenuTriggerButton(
                  icon: Icons.sort_outlined,
                  label: _selectedSort,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStrip() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          final cards = [
            _SummaryCardData(
              title: 'Total Revenue',
              value: '₹${_totalRevenue.toStringAsFixed(2)}',
              subtitle: '${_visibleInvoices.length} invoices',
              icon: Icons.trending_up,
              gradient: const [Color(0xFFB48F85), Color(0xFF9A7A6F)],
            ),
            _SummaryCardData(
              title: 'Paid Invoices',
              value: _paidCount.toString(),
              subtitle: 'Cleared payments',
              icon: Icons.verified_outlined,
              gradient: const [Color(0xFF34D399), Color(0xFF059669)],
            ),
            _SummaryCardData(
              title: 'Pending Amounts',
              value: _pendingCount.toString(),
              subtitle: 'Awaiting confirmation',
              icon: Icons.schedule_outlined,
              gradient: const [Color(0xFFFCD34D), Color(0xFFF59E0B)],
            ),
            _SummaryCardData(
              title: 'Overdue Alerts',
              value: _overdueCount.toString(),
              subtitle: 'Require follow-up',
              icon: Icons.warning_amber_outlined,
              gradient: const [Color(0xFFF87171), Color(0xFFDC2626)],
            ),
          ];

          return Wrap(
            spacing: 16.w,
            runSpacing: 16.h,
            children: cards
                .map(
                  (card) => SizedBox(
                    width: isWide
                        ? (constraints.maxWidth - 48.w) / 4
                        : constraints.maxWidth > 650
                        ? (constraints.maxWidth - 32.w) / 2
                        : constraints.maxWidth,
                    child: _SummaryCard(data: card),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildResponsiveListing() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 950) {
          return _buildDesktopTable();
        }
        if (constraints.maxWidth > 600) {
          return _buildTabletGrid();
        }
        return _buildMobileList();
      },
    );
  }

  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Row(
              children: [
                _buildTableHeaderCell('Invoice', flex: 3),
                _buildTableHeaderCell('Customer', flex: 3),
                _buildTableHeaderCell('Issued On'),
                _buildTableHeaderCell('Status'),
                _buildTableHeaderCell('Total', textAlign: TextAlign.right),
                SizedBox(width: 48.w),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _visibleInvoices.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, index) {
                final invoice = _visibleInvoices[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 16.h,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.bill.billNumber,
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3A3A3A),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '${invoice.items.length} items',
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.customerName,
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              invoice.customerContact,
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatDate(invoice.bill.billDate),
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _buildStatusChip(invoice.bill.paymentStatus),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '₹${invoice.bill.totalAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFB48F85),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      _buildViewButton(invoice),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletGrid() {
    return GridView.builder(
      padding: EdgeInsets.only(bottom: 80.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 1.45,
      ),
      itemCount: _visibleInvoices.length,
      itemBuilder: (context, index) {
        final invoice = _visibleInvoices[index];
        return _BillingCard(
          invoice: invoice,
          onTap: () => _showInvoiceDetails(invoice),
          onMarkPaid: () => _showMarkAsPaidDialog(invoice),
          onEdit: () => _showEditInvoiceDialog(invoice),
        );
      },
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: EdgeInsets.only(bottom: 80.h),
      itemCount: _visibleInvoices.length,
      itemBuilder: (context, index) {
        final invoice = _visibleInvoices[index];
        return _BillingCard(
          invoice: invoice,
          onTap: () => _showInvoiceDetails(invoice),
          onMarkPaid: () => _showMarkAsPaidDialog(invoice),
          onEdit: () => _showEditInvoiceDialog(invoice),
        );
      },
    );
  }

  Widget _buildViewButton(_InvoiceViewModel invoice) {
    return ElevatedButton(
      onPressed: () => _showInvoiceDetails(invoice),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFB48F85),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: Text('View', style: GoogleFonts.poppins(fontSize: 13.sp)),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFB48F85)),
          SizedBox(height: 16.h),
          Text(
            'Fetching billing data...',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'No invoices found',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try adjusting your filters or create a new invoice.',
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 16.h),
          OutlinedButton.icon(
            onPressed: _showCreateInvoiceSheet,
            icon: const Icon(Icons.add),
            label: Text('Create Invoice', style: GoogleFonts.poppins()),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB48F85),
              side: const BorderSide(color: Color(0xFFB48F85)),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(
    String label, {
    int flex = 1,
    TextAlign textAlign = TextAlign.left,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: textAlign,
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6B5E54),
        ),
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3A3A3A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF3A3A3A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isActive,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFFB48F85), Color(0xFF9A7A6F)],
                )
              : null,
          color: isActive ? null : Colors.grey[200],
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: const Color(0xFFB48F85)),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFB48F85),
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFB48F85)),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.r),
        ),
      ),
    );
  }

  Widget _buildMenuTriggerButton({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFFB48F85)),
        ),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFB48F85)),
          SizedBox(width: 8.w),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFB48F85),
            ),
          ),
          SizedBox(width: 4.w),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: Color(0xFFB48F85),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    late Color bg;
    late Color fg;
    switch (status.toLowerCase()) {
      case 'paid':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        break;
      case 'pending':
        bg = const Color(0xFFFFF7E6);
        fg = const Color(0xFFB45309);
        break;
      case 'overdue':
        bg = const Color(0xFFFFE4E6);
        fg = const Color(0xFFB91C1C);
        break;
      default:
        bg = const Color(0xFFE5E7EB);
        fg = const Color(0xFF1F2937);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Future<void> _showExportDialog() async {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            'Export Invoices',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExportOption(
                Icons.picture_as_pdf_outlined,
                'Export as PDF',
              ),
              _buildExportOption(Icons.grid_on_outlined, 'Export as Excel'),
              _buildExportOption(Icons.share_outlined, 'Share summary report'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Export task queued.',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFFB48F85),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB48F85),
                foregroundColor: Colors.white,
              ),
              child: Text('Confirm', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExportOption(IconData icon, String label) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFFB48F85)),
      title: Text(label, style: GoogleFonts.poppins(fontSize: 14.sp)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }

  void _showSettingsDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            'Billing Preferences',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: true,
                onChanged: (_) {},
                title: Text(
                  'Include tax summary on PDF',
                  style: GoogleFonts.poppins(),
                ),
                activeColor: const Color(0xFFB48F85),
              ),
              SwitchListTile(
                value: true,
                onChanged: (_) {},
                title: Text(
                  'Send email notifications to customers',
                  style: GoogleFonts.poppins(),
                ),
                activeColor: const Color(0xFFB48F85),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB48F85),
                foregroundColor: Colors.white,
              ),
              child: Text('Save', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }

  List<_InvoiceViewModel> _generateMockInvoices() {
    final random = Random();
    final customers = [
      _Customer(
        name: 'Aarav Patel',
        contact: '+91 98765 32109',
        email: 'aarav.patel@mail.com',
      ),
      _Customer(
        name: 'Diya Shah',
        contact: '+91 98220 12345',
        email: 'diya.s@fashionstudio.com',
      ),
      _Customer(
        name: 'Krishna Mehta',
        contact: '+91 98989 45678',
        email: 'krish.m@ensemble.in',
      ),
      _Customer(
        name: 'Sneha Verma',
        contact: '+91 98111 90876',
        email: 'sneha.v@stylelane.com',
      ),
      _Customer(
        name: 'Rahul Desai',
        contact: '+91 90909 70707',
        email: 'rahul.desai@ornate.co',
      ),
    ];

    final statuses = ['Paid', 'Pending', 'Overdue'];
    final List<_InvoiceViewModel> invoices = [];

    for (int i = 0; i < 14; i++) {
      final customer = customers[random.nextInt(customers.length)];
      final billNumber = '#INV-${202400 + i}';
      final billDate = DateTime.now().subtract(
        Duration(days: random.nextInt(45)),
      );

      final itemsCount = random.nextInt(4) + 2;
      final items = List<_InvoiceItem>.generate(itemsCount, (index) {
        final quantity = random.nextInt(4) + 1;
        final price = (random.nextInt(20) + 5) * 150.0;
        final name = [
          'Designer Necklace',
          'Polki Earrings',
          'Kundan Bracelet',
          'Antique Ring',
          'Temple Maangtikka',
          'Choker Set',
        ][random.nextInt(6)];
        return _InvoiceItem(
          name: name,
          quantity: quantity,
          unitPrice: price,
          totalPrice: quantity * price,
        );
      });

      final subtotal = items.fold<double>(
        0,
        (prev, item) => prev + item.totalPrice,
      );
      final tax = subtotal * 0.05;
      final discount = subtotal * (random.nextBool() ? 0.08 : 0.12);
      final total = subtotal + tax - discount;
      final status = statuses[random.nextInt(statuses.length)];

      final bill = Bill(
        billNumber: billNumber,
        customerId: customers.indexOf(customer) + 1,
        subtotal: subtotal,
        taxAmount: tax,
        discountAmount: discount,
        totalAmount: total,
        billDate: billDate,
        paymentStatus: status,
        notes: random.nextBool()
            ? 'Custom-made order. Deliver after polishing and quality check.'
            : null,
        createdAt: DateTime.now().subtract(Duration(days: random.nextInt(60))),
      );

      invoices.add(
        _InvoiceViewModel(
          bill: bill,
          customerName: customer.name,
          customerContact: customer.contact,
          customerEmail: customer.email,
          items: items,
        ),
      );
    }

    return invoices;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} ${_monthShort(date.month)} ${date.year}';
  }

  String _monthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _SummaryCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;

  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryCardData data;

  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: data.gradient.last.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(data.icon, color: Colors.white),
              ),
              const Spacer(),
              Icon(Icons.more_horiz, color: Colors.white.withOpacity(0.7)),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            data.value,
            style: GoogleFonts.poppins(
              fontSize: 26.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            data.title,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            data.subtitle,
            style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _InvoiceViewModel {
  final Bill bill;
  final String customerName;
  final String customerContact;
  final String customerEmail;
  final List<_InvoiceItem> items;

  const _InvoiceViewModel({
    required this.bill,
    required this.customerName,
    required this.customerContact,
    required this.customerEmail,
    required this.items,
  });

  _InvoiceViewModel copyWith({Bill? bill}) {
    return _InvoiceViewModel(
      bill: bill ?? this.bill,
      customerName: customerName,
      customerContact: customerContact,
      customerEmail: customerEmail,
      items: items,
    );
  }
}

class _InvoiceItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const _InvoiceItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class _Customer {
  final String name;
  final String contact;
  final String email;

  const _Customer({
    required this.name,
    required this.contact,
    required this.email,
  });
}

class _BillingCard extends StatelessWidget {
  final _InvoiceViewModel invoice;
  final VoidCallback onTap;
  final VoidCallback onMarkPaid;
  final VoidCallback onEdit;

  const _BillingCard({
    required this.invoice,
    required this.onTap,
    required this.onMarkPaid,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.bill.billNumber,
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A3A3A),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      invoice.customerName,
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${invoice.items.length} line items · ${invoice.customerContact}',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${invoice.bill.totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB48F85),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatDateStatic(invoice.bill.billDate),
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _StatusChip(status: invoice.bill.paymentStatus),
              SizedBox(width: 12.w),
              Text(
                invoice.customerEmail,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB48F85),
                    side: const BorderSide(color: Color(0xFFB48F85)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text('Edit', style: GoogleFonts.poppins()),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: onMarkPaid,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF34D399),
                    side: const BorderSide(color: Color(0xFF34D399)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text('Mark Paid', style: GoogleFonts.poppins()),
                ),
              ),
              SizedBox(width: 12.w),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB48F85),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text('View', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDateStatic(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} ${_monthShortStatic(date.month)} ${date.year}';
  }

  static String _monthShortStatic(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    switch (status.toLowerCase()) {
      case 'paid':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        break;
      case 'pending':
        bg = const Color(0xFFFFF7E6);
        fg = const Color(0xFFB45309);
        break;
      case 'overdue':
        bg = const Color(0xFFFFE4E6);
        fg = const Color(0xFFB91C1C);
        break;
      default:
        bg = const Color(0xFFE5E7EB);
        fg = const Color(0xFF1F2937);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _InvoiceFormSheet extends StatefulWidget {
  final _InvoiceViewModel? existingInvoice;
  final ValueChanged<_InvoiceViewModel> onSubmit;

  const _InvoiceFormSheet({required this.onSubmit, this.existingInvoice});

  @override
  State<_InvoiceFormSheet> createState() => _InvoiceFormSheetState();
}

class _InvoiceFormSheetState extends State<_InvoiceFormSheet> {
  late TextEditingController _invoiceNumberController;
  late TextEditingController _customerNameController;
  late TextEditingController _customerContactController;
  late TextEditingController _customerEmailController;
  late TextEditingController _notesController;
  DateTime _issueDate = DateTime.now();
  String _status = 'Pending';
  List<_InvoiceItem> _items = [];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingInvoice;
    _invoiceNumberController = TextEditingController(
      text:
          existing?.bill.billNumber ??
          '#INV-${DateTime.now().millisecondsSinceEpoch % 100000}',
    );
    _customerNameController = TextEditingController(
      text: existing?.customerName ?? '',
    );
    _customerContactController = TextEditingController(
      text: existing?.customerContact ?? '',
    );
    _customerEmailController = TextEditingController(
      text: existing?.customerEmail ?? '',
    );
    _notesController = TextEditingController(text: existing?.bill.notes ?? '');
    _issueDate = existing?.bill.billDate ?? DateTime.now();
    _status = existing?.bill.paymentStatus ?? 'Pending';
    _items =
        existing?.items ??
        [
          const _InvoiceItem(
            name: 'Designer Necklace',
            quantity: 1,
            unitPrice: 3500,
            totalPrice: 3500,
          ),
        ];
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _customerNameController.dispose();
    _customerContactController.dispose();
    _customerEmailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items = [
        ..._items,
        const _InvoiceItem(
          name: 'Custom Jewellery Piece',
          quantity: 1,
          unitPrice: 2500,
          totalPrice: 2500,
        ),
      ];
    });
  }

  void _removeItem(int index) {
    setState(() => _items = List.of(_items)..removeAt(index));
  }

  void _submit() {
    if (_customerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Customer name is required',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    final subtotal = _items.fold<double>(0, (prev, e) => prev + e.totalPrice);
    final tax = subtotal * 0.05;
    final discount = subtotal * 0.08;
    final total = subtotal + tax - discount;

    final bill = Bill(
      billNumber: _invoiceNumberController.text.trim(),
      customerId: 0,
      subtotal: subtotal,
      taxAmount: tax,
      discountAmount: discount,
      totalAmount: total,
      billDate: _issueDate,
      paymentStatus: _status,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    widget.onSubmit(
      _InvoiceViewModel(
        bill: bill,
        customerName: _customerNameController.text.trim(),
        customerContact: _customerContactController.text.trim(),
        customerEmail: _customerEmailController.text.trim(),
        items: _items,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60.w,
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                widget.existingInvoice == null
                    ? 'Create Invoice'
                    : 'Edit Invoice',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A3A3A),
                ),
              ),
              SizedBox(height: 18.h),
              _buildTextField(
                controller: _invoiceNumberController,
                label: 'Invoice Number',
                prefixIcon: Icons.tag_outlined,
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _customerNameController,
                label: 'Customer Name',
                prefixIcon: Icons.person_outline,
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _customerContactController,
                label: 'Customer Contact',
                prefixIcon: Icons.phone_outlined,
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _customerEmailController,
                label: 'Customer Email',
                prefixIcon: Icons.email_outlined,
              ),
              SizedBox(height: 12.h),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFFB48F85),
                ),
                title: Text(
                  'Invoice Date',
                  style: GoogleFonts.poppins(fontSize: 13.sp),
                ),
                subtitle: Text(
                  _BillingCard._formatDateStatic(_issueDate),
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _issueDate,
                    firstDate: DateTime(DateTime.now().year - 2),
                    lastDate: DateTime(DateTime.now().year + 1),
                  );
                  if (picked != null) {
                    setState(() => _issueDate = picked);
                  }
                },
              ),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(
                  labelText: 'Payment Status',
                  prefixIcon: const Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? 'Pending'),
              ),
              SizedBox(height: 18.h),
              Text(
                'Line Items',
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12.h),
              ..._items.asMap().entries.map(
                (entry) => Container(
                  margin: EdgeInsets.only(bottom: 10.h),
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F6),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value.name,
                              style: GoogleFonts.poppins(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '${entry.value.quantity} pcs · ₹${entry.value.unitPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${entry.value.totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB48F85),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      IconButton(
                        onPressed: () => _removeItem(entry.key),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              OutlinedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: Text('Add item', style: GoogleFonts.poppins()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB48F85),
                  side: const BorderSide(color: Color(0xFFB48F85)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              _buildTextField(
                controller: _notesController,
                label: 'Additional Notes',
                prefixIcon: Icons.note_alt_outlined,
                maxLines: 3,
              ),
              SizedBox(height: 22.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel', style: GoogleFonts.poppins()),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB48F85),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        widget.existingInvoice == null ? 'Create' : 'Update',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFFB48F85)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: Color(0xFFB48F85), width: 2),
        ),
      ),
    );
  }
}
