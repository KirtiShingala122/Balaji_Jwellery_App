import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../widgets/custom_text_field.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final CustomerService _service = CustomerService();
  List<Customer> _customers = [];
  bool _loading = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getAllCustomers();
      if (mounted) setState(() => _customers = data);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Customer> get _filtered {
    if (_query.isEmpty) return _customers;
    return _customers.where((c) {
      final q = _query.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.address.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q);
    }).toList();
  }

  void _showCustomerSheet({Customer? customer}) {
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final emailCtrl = TextEditingController(text: customer?.email ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phoneNumber ?? '');
    final addressCtrl = TextEditingController(text: customer?.address ?? '');
    final formKey = GlobalKey<FormState>();
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
          builder: (context, setStateModal) => SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.82,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 60.w,
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      customer == null ? 'Add Customer' : 'Edit Customer',
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.grey[800]
                            : Colors.white,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              CustomTextField(
                                controller: nameCtrl,
                                labelText: 'Name',
                                prefixIcon: Icons.person,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Enter name'
                                    : null,
                              ),
                              SizedBox(height: 12.h),
                              CustomTextField(
                                controller: emailCtrl,
                                labelText: 'Email',
                                prefixIcon: Icons.email,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Enter email'
                                    : null,
                              ),
                              SizedBox(height: 12.h),
                              CustomTextField(
                                controller: phoneCtrl,
                                labelText: 'Phone',
                                prefixIcon: Icons.phone,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Enter phone'
                                    : null,
                              ),
                              SizedBox(height: 12.h),
                              CustomTextField(
                                controller: addressCtrl,
                                labelText: 'Address',
                                prefixIcon: Icons.home,
                                maxLines: 3,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Enter address'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: saving
                                ? null
                                : () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(vertical: 13.h),
                            ),
                            child: Text('Cancel', style: GoogleFonts.inter()),
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
                                    final now = DateTime.now();
                                    try {
                                      if (customer == null) {
                                        await _service.addCustomer(
                                          Customer(
                                            name: nameCtrl.text.trim(),
                                            email: emailCtrl.text.trim(),
                                            phoneNumber: phoneCtrl.text.trim(),
                                            address: addressCtrl.text.trim(),
                                            createdAt: now,
                                            updatedAt: now,
                                          ),
                                        );
                                      } else {
                                        await _service.updateCustomer(
                                          customer.copyWith(
                                            name: nameCtrl.text.trim(),
                                            email: emailCtrl.text.trim(),
                                            phoneNumber: phoneCtrl.text.trim(),
                                            address: addressCtrl.text.trim(),
                                            updatedAt: now,
                                          ),
                                        );
                                      }
                                      if (mounted) {
                                        Navigator.pop(context);
                                        await _load();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              customer == null
                                                  ? 'Customer added'
                                                  : 'Customer updated',
                                            ),
                                            backgroundColor: Theme.of(
                                              context,
                                            ).cardColor,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setStateModal(() => saving = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B6F47),
                              padding: EdgeInsets.symmetric(vertical: 13.h),
                              foregroundColor: Colors.white,
                            ),
                            child: saving
                                ? SizedBox(
                                    height: 18.h,
                                    width: 18.h,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    customer == null ? 'Add' : 'Update',
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
          ),
        );
      },
    );
  }

  void _confirmDelete(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Delete ${customer.name}?',
          style: GoogleFonts.inter(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey[800]
                : Colors.white,
          ),
        ),
        content: Text(
          'This cannot be undone.',
          style: GoogleFonts.inter(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey[600]
                : Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _service.deleteCustomer(customer.id!);
                if (mounted) {
                  Navigator.pop(ctx);
                  await _load();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Customer deleted')),
                  );
                }
              } catch (e) {
                Navigator.pop(ctx);
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDetails(Customer customer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(18.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[800]
                          : Colors.white,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                ? Colors.grey[800]
                                : Colors.white,
                          ),
                        ),
                        Text(
                          customer.email,
                          style: GoogleFonts.inter(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                ? Colors.grey[600]
                                : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[800]
                          : Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showCustomerSheet(customer: customer);
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[800]
                          : Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDelete(customer);
                    },
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _detailRow(Icons.phone, customer.phoneNumber),
              SizedBox(height: 8.h),
              _detailRow(Icons.home, customer.address),
              SizedBox(height: 8.h),
              _detailRow(Icons.email, customer.email),
              SizedBox(height: 16.h),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCustomerSheet(customer: customer);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.grey[800]
              : Colors.white,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[700]
                  : Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCustomerSheet(),
        backgroundColor: const Color(0xFF8B6F47),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: GoogleFonts.inter(color: Colors.red),
                      ),
                    )
                  : items.isEmpty
                  ? Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64.sp,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            _query.isEmpty
                                ? 'No customers yet. Tap + to add your first customer.'
                                : 'No customers match your search.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(
                        top: 12.h,
                        bottom: MediaQuery.of(context).padding.bottom + 24.h,
                      ),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) => _buildCustomerTile(items[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerTile(Customer c) {
    return InkWell(
      onTap: () => _showDetails(c),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey.shade600.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: Theme.of(context).brightness == Brightness.light
                  ? 10
                  : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22.r,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: Icon(
                Icons.person,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[800]
                    : Colors.white,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[800]
                          : Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    c.address,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[600]
                          : Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[600]
                    : Colors.white70,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Theme.of(context).cardColor,
                  builder: (ctx) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.visibility),
                          title: const Text('View details'),
                          onTap: () {
                            Navigator.pop(ctx);
                            _showDetails(c);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Edit'),
                          onTap: () {
                            Navigator.pop(ctx);
                            _showCustomerSheet(customer: c);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: const Text('Delete'),
                          onTap: () {
                            Navigator.pop(ctx);
                            _confirmDelete(c);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Customers',
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
                ),
                child: Icon(
                  Icons.people_alt_outlined,
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
                    : Colors.white24,
                width: 1.2,
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
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[800]
                    : Colors.white,
              ),
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[800]
                      : Colors.white70,
                ),
                hintText: 'Search customers...',
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
