import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/sales_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFE2E8F0),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  'Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const Spacer(),
                Consumer<DashboardProvider>(
                  builder: (context, provider, child) {
                    return IconButton(
                      onPressed: provider.refreshData,
                      icon: provider.isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.refresh,
                              size: 24.w,
                              color: const Color(0xFF3B82F6),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards
                  Consumer<DashboardProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (provider.errorMessage != null) {
                        return Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48.w,
                                color: Colors.red,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                provider.errorMessage!,
                                style: GoogleFonts.poppins(
                                  fontSize: 16.sp,
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16.h),
                              ElevatedButton(
                                onPressed: provider.refreshData,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          // Top Row
                          Row(
                            children: [
                              Expanded(
                                child: DashboardCard(
                                  title: 'Total Categories',
                                  value: provider.totalCategories.toString(),
                                  icon: Icons.category,
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: DashboardCard(
                                  title: 'Total Products',
                                  value: provider.totalProducts.toString(),
                                  icon: Icons.inventory,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 16.h),

                          // Bottom Row
                          Row(
                            children: [
                              Expanded(
                                child: DashboardCard(
                                  title: 'Total Customers',
                                  value: provider.totalCustomers.toString(),
                                  icon: Icons.people,
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: DashboardCard(
                                  title: 'Total Sales',
                                  value:
                                      '₹${provider.totalSales.toStringAsFixed(2)}',
                                  icon: Icons.attach_money,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 32.h),

                  // Charts Section
                  Text(
                    'Sales Overview',
                    style: GoogleFonts.poppins(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Sales Chart
                  Container(
                    height: 300.h,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const SalesChart(),
                  ),

                  SizedBox(height: 32.h),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.poppins(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          title: 'Add Product',
                          icon: Icons.add_box,
                          color: const Color(0xFF10B981),
                          onTap: () {
                            // Navigate to add product
                          },
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _buildQuickActionButton(
                          title: 'Create Bill',
                          icon: Icons.receipt,
                          color: const Color(0xFF3B82F6),
                          onTap: () {
                            // Navigate to create bill
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          title: 'Add Customer',
                          icon: Icons.person_add,
                          color: const Color(0xFFF59E0B),
                          onTap: () {
                            // Navigate to add customer
                          },
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _buildQuickActionButton(
                          title: 'View Reports',
                          icon: Icons.analytics,
                          color: const Color(0xFF8B5CF6),
                          onTap: () {
                            // Navigate to reports
                          },
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
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32.w, color: color),
              SizedBox(height: 8.h),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
