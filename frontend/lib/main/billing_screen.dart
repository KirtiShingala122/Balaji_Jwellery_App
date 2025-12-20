import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/customer.dart';
import '../models/product.dart';
import '../services/bill_service.dart';
import '../services/customer_service.dart';
import '../services/product_service.dart';
import '../services/pdf_sevice.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final BillService _billService = BillService();
  final CustomerService _customerService = CustomerService();
  final ProductService _productService = ProductService();
  final PDFService _pdfService = PDFService();

  bool _loading = false;
  String? _error;

  List<BillRecord> _bills = [];
  List<Customer> _customers = [];

  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _billService.getBills(),
        _customerService.getAllCustomers(),
      ]);
      _bills = results[0] as List<BillRecord>;
      _customers = results[1] as List<Customer>;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ================= CREATE BILL =================
  void _openCreateBillSheet() {
    Customer? selectedCustomer;
    Product? selectedProduct;
    DateTime billDate = DateTime.now();
    String paymentStatus = 'pending';
    List<Customer> remoteSuggestions = [];
    bool searchingCustomers = false;

    // Customer controllers
    final customerSearchCtrl = TextEditingController();
    final customerPhoneCtrl = TextEditingController();
    final customerEmailCtrl = TextEditingController();
    final customerAddressCtrl = TextEditingController();

    // Product + totals controllers
    final productCodeCtrl = TextEditingController();
    final gstCtrl = TextEditingController(text: '0');
    final discountCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();

    int quantity = 1;
    final List<_BillLine> lines = [];

    double subtotal() => lines.fold(0.0, (sum, l) => sum + l.totalPrice);

    double gstAmount() =>
        subtotal() * ((double.tryParse(gstCtrl.text.trim()) ?? 0) / 100);

    double discountAmount() => double.tryParse(discountCtrl.text.trim()) ?? 0;

    double total() => subtotal() + gstAmount() - discountAmount();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            final displayBillNumber =
                'BILL-${(_bills.length + 1).toString().padLeft(4, '0')}';

            final query = customerSearchCtrl.text.trim();

            Future<void> fetchCustomerSuggestions(String q) async {
              if (q.isEmpty) {
                setSheet(() => remoteSuggestions = []);
                return;
              }
              setSheet(() => searchingCustomers = true);
              try {
                final results = await _customerService.searchCustomers(q);
                setSheet(() {
                  remoteSuggestions = results.take(8).toList();
                });
              } finally {
                setSheet(() => searchingCustomers = false);
              }
            }

            final localMatches = _customers
                .where(
                  (c) =>
                      c.name.toLowerCase().contains(query.toLowerCase()) ||
                      c.phoneNumber.toLowerCase().contains(query),
                )
                .take(8)
                .toList();

            final customerSuggestions = query.isEmpty
                ? localMatches
                : (remoteSuggestions.isNotEmpty
                      ? remoteSuggestions
                      : localMatches);

            Future<void> fetchProduct(String code) async {
              final trimmed = code.trim();
              if (trimmed.isEmpty) return;
              try {
                final p = await _productService.getProductByCode(trimmed);
                if (p == null) {
                  setSheet(() => selectedProduct = null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product not found')),
                  );
                  return;
                }
                setSheet(() {
                  selectedProduct = p;
                  quantity = 1;
                });
              } catch (err) {
                setSheet(() => selectedProduct = null);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error fetching product: $err')),
                );
              }
            }

            void addItem() {
              if (selectedProduct == null) return;

              if (quantity > selectedProduct!.stockQuantity) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Out of stock. Only ${selectedProduct!.stockQuantity} available',
                    ),
                  ),
                );
                return;
              }

              lines.add(
                _BillLine(product: selectedProduct!, quantity: quantity),
              );

              selectedProduct = null;
              productCodeCtrl.clear();
              quantity = 1;
              setSheet(() {});
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16.w,
                right: 16.w,
                top: 16.h,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48.w,
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Create Invoice',
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.grey[800]
                            : const Color(0xFF4A3B2A),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Bill number (display only)
                    _infoRow('Invoice Number', displayBillNumber),
                    SizedBox(height: 12.h),

                    // Customer search + autofill
                    TextField(
                      controller: customerSearchCtrl,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.grey[800]
                            : Colors.white,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Customer Name',
                        labelStyle: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? Colors.grey[600]
                              : Colors.white70,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? Colors.grey[600]
                              : Colors.white70,
                        ),
                      ),
                      onChanged: (v) {
                        setSheet(() {});
                        fetchCustomerSuggestions(v);
                      },
                    ),
                    if (customerSuggestions.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: customerSuggestions.map((c) {
                            return ListTile(
                              title: Text(
                                c.name,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.grey[800]
                                      : Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                c.phoneNumber,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.grey[600]
                                      : Colors.white70,
                                ),
                              ),
                              onTap: () {
                                selectedCustomer = c;
                                customerSearchCtrl.text = c.name;
                                customerPhoneCtrl.text = c.phoneNumber;
                                customerEmailCtrl.text = c.email;
                                customerAddressCtrl.text = c.address;
                                FocusScope.of(context).unfocus();
                                setSheet(() {});
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    if (searchingCustomers)
                      Padding(
                        padding: EdgeInsets.only(top: 6.h),
                        child: const LinearProgressIndicator(minHeight: 2),
                      ),
                    SizedBox(height: 8.h),
                    _readonlyField('Customer Contact', customerPhoneCtrl),
                    _readonlyField('Customer Email', customerEmailCtrl),
                    _readonlyField(
                      'Customer Address',
                      customerAddressCtrl,
                      maxLines: 2,
                    ),

                    SizedBox(height: 12.h),

                    // Date + payment status
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: billDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setSheet(() => billDate = picked);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Colors.white
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.grey.shade300
                                      : Colors.white12,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.light
                                        ? Colors.grey[800]
                                        : Colors.white,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    '${billDate.day} ${_monthName(billDate.month)} ${billDate.year}',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.grey[800]
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: paymentStatus,
                            decoration: const InputDecoration(
                              labelText: 'Payment Status',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'pending',
                                child: Text('Pending'),
                              ),
                              DropdownMenuItem(
                                value: 'paid',
                                child: Text('Paid'),
                              ),
                              DropdownMenuItem(
                                value: 'unpaid',
                                child: Text('Unpaid'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) setSheet(() => paymentStatus = v);
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),
                    Text(
                      'Line Items',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A3B2A),
                      ),
                    ),
                    SizedBox(height: 8.h),

                    // Product search
                    TextField(
                      controller: productCodeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Product Unique Code',
                        prefixIcon: Icon(Icons.qr_code_2),
                      ),
                      onSubmitted: fetchProduct,
                      onChanged: (_) => setSheet(() => selectedProduct = null),
                    ),
                    if (selectedProduct != null) ...[
                      SizedBox(height: 8.h),
                      _infoRow('Product', selectedProduct!.name),
                      _infoRow('Description', selectedProduct!.description),
                      _infoRow(
                        'Category',
                        selectedProduct!.categoryName ?? 'N/A',
                      ),
                      _infoRow('Price', '₹${selectedProduct!.price}'),
                      _infoRow(
                        'Available',
                        '${selectedProduct!.stockQuantity}',
                      ),
                    ],
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                ? Colors.grey[600]
                                : Colors.white70,
                          ),
                          onPressed: quantity > 1
                              ? () => setSheet(() => quantity--)
                              : null,
                        ),
                        Text(
                          quantity.toString(),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                ? Colors.grey[800]
                                : Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add_circle_outline,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                ? Colors.grey[600]
                                : Colors.white70,
                          ),
                          onPressed:
                              selectedProduct != null &&
                                  quantity < selectedProduct!.stockQuantity
                              ? () => setSheet(() => quantity++)
                              : null,
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: addItem,
                          label: Text(
                            'Add item',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B6F47),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (selectedProduct != null &&
                        quantity > selectedProduct!.stockQuantity)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Text(
                          'Only ${selectedProduct!.stockQuantity} available',
                          style: GoogleFonts.inter(color: Colors.red),
                        ),
                      ),

                    SizedBox(height: 10.h),
                    ...lines.map(
                      (l) => Container(
                        margin: EdgeInsets.symmetric(vertical: 4.h),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? Colors.white
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                ? Colors.grey.shade200
                                : Colors.grey.shade700,
                          ),
                          boxShadow:
                              Theme.of(context).brightness == Brightness.light
                              ? [
                                  BoxShadow(
                                    color: Colors.grey.shade600.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.product.name,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (l.product.categoryName != null)
                                    Text(
                                      l.product.categoryName!,
                                      style: GoogleFonts.inter(
                                        color: Colors.grey,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  Text(
                                    '${l.quantity} x ₹${l.product.price.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${l.totalPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 12.h),
                    TextField(
                      controller: gstCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'GST %'),
                      onChanged: (_) => setSheet(() {}),
                    ),
                    TextField(
                      controller: discountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Discount (₹)',
                      ),
                      onChanged: (_) => setSheet(() {}),
                    ),
                    SizedBox(height: 6.h),
                    _infoRow('Subtotal', '₹${subtotal().toStringAsFixed(2)}'),
                    _infoRow('GST', '₹${gstAmount().toStringAsFixed(2)}'),
                    _infoRow(
                      'Total after discount',
                      '₹${total().toStringAsFixed(2)}',
                    ),

                    SizedBox(height: 12.h),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes',
                      ),
                      maxLines: 3,
                    ),

                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B6F47),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            onPressed: () async {
                              if (selectedCustomer == null || lines.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Select a customer and add items',
                                    ),
                                  ),
                                );
                                return;
                              }

                              try {
                                await _billService.addBill(
                                  customerId: selectedCustomer!.id!,
                                  taxAmount: gstAmount(),
                                  discountAmount: discountAmount(),
                                  paymentStatus: paymentStatus,
                                  notes: notesCtrl.text.trim().isEmpty
                                      ? null
                                      : notesCtrl.text.trim(),
                                  items: lines
                                      .map(
                                        (l) => {
                                          'productId': l.product.id,
                                          'quantity': l.quantity,
                                          'unitPrice': l.product.price,
                                          'totalPrice': l.totalPrice,
                                        },
                                      )
                                      .toList(),
                                );

                                if (mounted) {
                                  Navigator.pop(context);
                                  await _loadAll();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invoice created'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Create'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _bills.where((b) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return b.bill.billNumber.toLowerCase().contains(q) ||
          b.customerName.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8B6F47),
        onPressed: _openCreateBillSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : Column(
                children: [
                  _header(),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No invoices yet. Tap + to create.',
                              style: GoogleFonts.inter(color: Colors.grey[700]),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.only(
                              top: 10.h,
                              bottom:
                                  MediaQuery.of(context).padding.bottom + 20.h,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) {
                              final bill = filtered[i].bill;
                              final displayIndex = i + 1;
                              return Card(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 6.h,
                                ),
                                color: Theme.of(context).cardColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                child: ListTile(
                                  title: Text(
                                    'INV-$displayIndex (${bill.billNumber})',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.grey[800]
                                          : Colors.white,
                                    ),
                                  ),
                                  subtitle: Text(
                                    filtered[i].customerName,
                                    style: GoogleFonts.inter(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.grey[600]
                                          : Colors.white70,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${bill.totalAmount.toStringAsFixed(2)}',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.light
                                                  ? Colors.grey[800]
                                                  : Colors.white,
                                            ),
                                          ),
                                          Text(
                                            bill.paymentStatus.toUpperCase(),
                                            style: GoogleFonts.inter(
                                              color:
                                                  bill.paymentStatus == 'paid'
                                                  ? Colors.greenAccent
                                                  : Colors.orangeAccent,
                                              fontSize: 12.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(width: 8.w),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.light
                                              ? Colors.grey[800]
                                              : Colors.white,
                                        ),
                                        onPressed: () =>
                                            _confirmDelete(bill.id!),
                                      ),
                                    ],
                                  ),
                                  onTap: () => _openBillDetail(bill.id!),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Invoices',
                style: GoogleFonts.roboto(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[800]
                      : Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.picture_as_pdf,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[800]
                      : Colors.white,
                ),
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            height: 48.h,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF8B6F47)
                    : Colors.white24,
              ),
              boxShadow: Theme.of(context).brightness == Brightness.light
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.8),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: TextField(
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[800]
                    : Colors.white,
              ),
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[600]
                      : Colors.white70,
                ),
                hintText: 'Search by invoice number or customer name...',
                hintStyle: TextStyle(
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

  Future<void> _openBillDetail(int billId) async {
    BillDetail? detail;
    try {
      detail = await _billService.getBillWithItems(billId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching bill: $e')));
      }
      return;
    }
    if (detail == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bill not found')));
      }
      return;
    }

    final bill = detail.bill;
    final items = detail.items;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  bill.billNumber,
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(bill.paymentStatus.toUpperCase()),
                  backgroundColor: bill.paymentStatus == 'paid'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  labelStyle: GoogleFonts.inter(
                    color: bill.paymentStatus == 'paid'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            ...items.map(
              (i) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Product ${i.productId}'),
                subtitle: Text(
                  'Qty ${i.quantity} • ₹${i.unitPrice.toStringAsFixed(2)}',
                ),
                trailing: Text('₹${i.totalPrice.toStringAsFixed(2)}'),
              ),
            ),
            const Divider(),
            _infoRow('Subtotal', '₹${bill.subtotal.toStringAsFixed(2)}'),
            _infoRow('Tax', '₹${bill.taxAmount.toStringAsFixed(2)}'),
            _infoRow('Discount', '₹${bill.discountAmount.toStringAsFixed(2)}'),
            _infoRow('Total', '₹${bill.totalAmount.toStringAsFixed(2)}'),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final savedPath = await _pdfService.saveBillPDF(
                        bill,
                        items,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              savedPath == 'downloaded'
                                  ? 'PDF downloaded'
                                  : 'Saved to: $savedPath',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B6F47),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _pdfService.shareBill(bill, items);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(int billId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text(
          'Are you sure you want to delete this invoice? This will restore product stock.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _billService.deleteBill(billId);
      if (mounted) {
        await _loadAll();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invoice deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _readonlyField(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        labelStyle: TextStyle(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.grey[600]
              : Colors.white70,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
      style: TextStyle(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.grey[800]
            : Colors.white,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          SizedBox(
            width: 140.w,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[600]
                    : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[800]
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
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
    return months[m - 1];
  }
}

class _BillLine {
  final Product product;
  final int quantity;

  _BillLine({required this.product, required this.quantity});

  double get totalPrice => quantity * product.price;
}
