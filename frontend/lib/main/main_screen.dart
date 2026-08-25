import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'dashboard_screen.dart';
import 'categories_screen.dart';
import 'products_screen.dart';
import 'reports_screen.dart';
import 'chat_screen.dart';
import 'billing_screen.dart';
import 'customers_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<MainScreenItem> _screens = [
    MainScreenItem(
      title: 'Dashboard',
      icon: Icons.dashboard_rounded,
      screen: const DashboardScreen(),
    ),
    MainScreenItem(
      title: 'Categories',
      icon: Icons.category_rounded,
      screen: const CategoriesScreen(),
    ),
    MainScreenItem(
      title: 'Products',
      icon: Icons.inventory_2_rounded,
      screen: const AllProductsScreen(),
    ),
    MainScreenItem(
      title: 'Billing',
      icon: Icons.receipt_long_rounded,
      screen: const BillingScreen(),
    ),
    MainScreenItem(
      title: 'Customers',
      icon: Icons.people_rounded,
      screen: const CustomersScreen(),
    ),
    MainScreenItem(
      title: 'Reports',
      icon: Icons.analytics_rounded,
      screen: const ReportsScreen(),
    ),
    MainScreenItem(
      title: 'AI Assistant',
      icon: Icons.smart_toy_rounded,
      screen: const ChatScreen(),
    ),
    MainScreenItem(
      title: 'Settings',
      icon: Icons.settings_rounded,
      screen: const SettingsScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadInitialData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );
    await dashboardProvider.loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: _screens.map((item) => item.screen).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240.w,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(3, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 32.h, 20.w, 20.h),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.diamond_rounded,
                      size: 32.w, color: Colors.white),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Balaji Imitation',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Admin Panel',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),

          Divider(color: Colors.white.withOpacity(0.15), height: 1),
          SizedBox(height: 8.h),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              itemCount: _screens.length,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              itemBuilder: (context, index) {
                final item = _screens[index];
                final isSelected = _currentIndex == index;
                final isAI = item.title == 'AI Assistant';

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 2.h),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _currentIndex = index;
                        });
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      borderRadius: BorderRadius.circular(10.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 11.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10.r),
                          border: isAI && !isSelected
                              ? Border.all(
                                  color:
                                      const Color(0xFF60A5FA).withOpacity(0.4),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 18.w,
                              color: isSelected
                                  ? Colors.white
                                  : isAI
                                      ? const Color(0xFF93C5FD)
                                      : Colors.white60,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                item.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white
                                      : isAI
                                          ? const Color(0xFF93C5FD)
                                          : Colors.white70,
                                ),
                              ),
                            ),
                            if (isAI)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6)
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text('AI',
                                    style: GoogleFonts.poppins(
                                        fontSize: 8.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // User Info and Logout
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              border: Border(
                top: BorderSide(
                    color: Colors.white.withOpacity(0.15), width: 1),
              ),
            ),
            child: Column(
              children: [
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 18.r,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 18.w,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authProvider.currentAdmin?.fullName ?? 'Admin',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                authProvider.currentAdmin?.username ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 9.sp,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 10.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: Icon(Icons.logout_rounded, size: 14.w),
                    label: Text(
                      'Logout',
                      style: GoogleFonts.poppins(fontSize: 12.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}

class MainScreenItem {
  final String title;
  final IconData icon;
  final Widget screen;

  MainScreenItem({
    required this.title,
    required this.icon,
    required this.screen,
  });
}

// ─── All Products Screen (sidebar entry — guides user to categories) ─────────
class AllProductsScreen extends StatelessWidget {
  const AllProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Color(0xFFE2E8F0),
                    blurRadius: 4,
                    offset: Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2_rounded,
                    color: const Color(0xFF1E3A8A), size: 26.w),
                SizedBox(width: 12.w),
                Text(
                  'Products',
                  style: GoogleFonts.poppins(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_rounded,
                      size: 64.w,
                      color: const Color(0xFF3B82F6).withOpacity(0.5)),
                  SizedBox(height: 16.h),
                  Text(
                    'Select a Category to View Products',
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Go to Categories → tap a category → manage its products',
                    style: GoogleFonts.poppins(
                        fontSize: 13.sp, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
