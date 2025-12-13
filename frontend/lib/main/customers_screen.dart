import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/customer.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  String _sortOption = 'name_asc';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _customers = _generateMockCustomers();
      _filteredCustomers = List.from(_customers);
      _sortCustomers();
      _isLoading = false;
    });
  }

  void _filterCustomers(String query) {
    setState(() {
      _filteredCustomers = _customers.where((customer) {
        final customerName = customer.name.toLowerCase();
        final customerEmail = customer.email.toLowerCase();
        final searchLower = query.toLowerCase();
        return customerName.contains(searchLower) ||
            customerEmail.contains(searchLower);
      }).toList();
      _sortCustomers();
    });
  }

  void _sortCustomers() {
    setState(() {
      switch (_sortOption) {
        case 'name_asc':
          _filteredCustomers.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'name_desc':
          _filteredCustomers.sort((a, b) => b.name.compareTo(a.name));
          break;
        case 'date_new':
          _filteredCustomers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'date_old':
          _filteredCustomers.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F6),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterAndSort(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFB48F85)),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (_filteredCustomers.isEmpty) {
                        return _buildEmptyState();
                      }
                      if (constraints.maxWidth > 950) {
                        return _buildDesktopView();
                      } else if (constraints.maxWidth > 600) {
                        return _buildTabletView();
                      } else {
                        return _buildMobileView();
                      }
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomerForm(),
        backgroundColor: const Color(0xFFB48F85),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Customer',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
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
          const Icon(Icons.people_alt_outlined, color: Colors.white, size: 32),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Management',
                style: GoogleFonts.poppins(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                'View, add, and manage your customer profiles',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSort() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _filterCustomers,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFB48F85)),
                filled: true,
                fillColor: const Color(0xFFFAF7F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F6),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortOption,
                icon: const Icon(Icons.sort, color: Color(0xFFB48F85)),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _sortOption = newValue;
                      _sortCustomers();
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: 'name_asc',
                    child: Text('Name (A-Z)'),
                  ),
                  DropdownMenuItem(
                    value: 'name_desc',
                    child: Text('Name (Z-A)'),
                  ),
                  DropdownMenuItem(value: 'date_new', child: Text('Newest')),
                  DropdownMenuItem(value: 'date_old', child: Text('Oldest')),
                ],
              ),
            ),
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
          Icon(Icons.group_off_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'No Customers Found',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try adjusting your search or add a new customer.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopView() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      children: [
        _buildDesktopHeader(),
        const Divider(height: 1),
        ..._filteredCustomers.map(
          (customer) => _buildDesktopCustomerRow(customer),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      child: Row(
        children: [
          Expanded(flex: 3, child: _headerText('Customer')),
          Expanded(flex: 3, child: _headerText('Contact')),
          Expanded(flex: 2, child: _headerText('Address')),
          Expanded(flex: 2, child: _headerText('Joined On')),
          const SizedBox(width: 100),
        ],
      ),
    );
  }

  Text _headerText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildDesktopCustomerRow(Customer customer) {
    return InkWell(
      onTap: () => _showCustomerDetails(customer),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1E6E3))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFF1E6E3),
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0] : '?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFB48F85),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    customer.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.email),
                  Text(
                    customer.phoneNumber,
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(customer.address, overflow: TextOverflow.ellipsis),
            ),
            Expanded(flex: 2, child: Text(_formatDate(customer.createdAt))),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFFB48F85),
                  ),
                  onPressed: () => _showCustomerForm(customer: customer),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _confirmDelete(customer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletView() {
    return GridView.builder(
      padding: EdgeInsets.all(24.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.4,
        crossAxisSpacing: 20.w,
        mainAxisSpacing: 20.h,
      ),
      itemCount: _filteredCustomers.length,
      itemBuilder: (context, index) {
        return _buildCustomerCard(_filteredCustomers[index]);
      },
    );
  }

  Widget _buildMobileView() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _filteredCustomers.length,
      itemBuilder: (context, index) {
        return _buildCustomerCard(_filteredCustomers[index]);
      },
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      shadowColor: const Color(0xFFB48F85).withOpacity(0.1),
      child: InkWell(
        onTap: () => _showCustomerDetails(customer),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFF1E6E3),
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0] : '?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFB48F85),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Joined: ${_formatDate(customer.createdAt)}',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _infoRow(Icons.email_outlined, customer.email),
              SizedBox(height: 8.h),
              _infoRow(Icons.phone_outlined, customer.phoneNumber),
              SizedBox(height: 8.h),
              _infoRow(Icons.location_on_outlined, customer.address),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showCustomerForm(customer: customer),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB48F85),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(customer),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(text, style: GoogleFonts.poppins(fontSize: 13.sp)),
        ),
      ],
    );
  }

  void _showCustomerDetails(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          customer.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(Icons.email, customer.email),
            SizedBox(height: 12.h),
            _infoRow(Icons.phone, customer.phoneNumber),
            SizedBox(height: 12.h),
            _infoRow(Icons.location_city, customer.address),
            SizedBox(height: 12.h),
            _infoRow(
              Icons.calendar_today,
              'Joined on ${_formatDate(customer.createdAt)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCustomerForm({Customer? customer}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: customer?.name);
    final emailController = TextEditingController(text: customer?.email);
    final phoneController = TextEditingController(text: customer?.phoneNumber);
    final addressController = TextEditingController(text: customer?.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          customer == null ? 'Add Customer' : 'Edit Customer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                      value!.trim().isEmpty ? 'Please enter a name' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value!.trim().isEmpty) return 'Please enter an email';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                      return 'Enter a valid email';
                    return null;
                  },
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  validator: (value) => value!.trim().isEmpty
                      ? 'Please enter a phone number'
                      : null,
                ),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  validator: (value) =>
                      value!.trim().isEmpty ? 'Please enter an address' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newCustomer = Customer(
                  id: customer?.id ?? Random().nextInt(10000),
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                  address: addressController.text.trim(),
                  createdAt: customer?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                setState(() {
                  if (customer == null) {
                    _customers.insert(0, newCustomer);
                  } else {
                    final index = _customers.indexWhere(
                      (c) => c.id == customer.id,
                    );
                    if (index != -1) {
                      _customers[index] = newCustomer;
                    }
                  }
                  _filterCustomers(_searchController.text);
                });
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB48F85),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete ${customer.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _customers.removeWhere((c) => c.id == customer.id);
                _filterCustomers(_searchController.text);
              });
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  List<Customer> _generateMockCustomers() {
    final random = Random();
    final names = [
      'Aarav Sharma',
      'Vivaan Singh',
      'Aditya Kumar',
      'Vihaan Gupta',
      'Arjun Patel',
      'Sai Reddy',
      'Reyansh Joshi',
      'Krishna Verma',
      'Ishaan Ali',
      'Ayaan Khan',
      'Ananya Reddy',
      'Diya Gupta',
      'Saanvi Patel',
      'Aadhya Singh',
      'Myra Sharma',
    ];
    final cities = [
      'Mumbai',
      'Delhi',
      'Bangalore',
      'Hyderabad',
      'Chennai',
      'Pune',
      'Jaipur',
    ];

    return List.generate(15, (index) {
      final name = names[index % names.length];
      return Customer(
        id: index,
        name: name,
        email:
            '${name.split(" ").first.toLowerCase()}.${random.nextInt(99)}@example.com',
        phoneNumber:
            '+91 9876543${random.nextInt(100).toString().padLeft(2, '0')}',
        address:
            '${random.nextInt(999)} Main St, ${cities[random.nextInt(cities.length)]}',
        createdAt: DateTime.now().subtract(
          Duration(days: random.nextInt(365 * 2)),
        ),
        updatedAt: DateTime.now().subtract(Duration(days: random.nextInt(30))),
      );
    });
  }
}
