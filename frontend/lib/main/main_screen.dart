import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'dashboard_screen.dart';
import 'categories_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  // Responsive breakpoint
  static const double _desktopBreakpoint = 800;

  final List<MainScreenItem> _screens = [
    MainScreenItem(
      title: 'Dashboard',
      icon: Icons.dashboard,
      screen: const DashboardScreen(),
    ),
    MainScreenItem(
      title: 'Categories',
      icon: Icons.category,
      screen: const CategoriesScreen(),
    ),
    MainScreenItem(
      title: 'Billing',
      icon: Icons.receipt,
      screen: const BillingScreen(),
    ),
    MainScreenItem(
      title: 'Customers',
      icon: Icons.people,
      screen: const CustomersScreen(),
    ),
    MainScreenItem(
      title: 'Reports',
      icon: Icons.analytics,
      screen: const ReportsScreen(),
    ),
    MainScreenItem(
      title: 'Settings',
      icon: Icons.settings,
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
    final bool isMobile = MediaQuery.of(context).size.width < _desktopBreakpoint;

    if (isMobile) {
      return _buildMobileLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  // ============== MOBILE LAYOUT ==============
  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: _buildMobileAppBar(),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens.map((item) => item.screen).toList(),
      ),
      bottomNavigationBar: _buildMobileBottomNav(),
    );
  }

  // Mobile AppBar (Logo + User Icon)
  AppBar _buildMobileAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1E3A8A),
      elevation: 2,
      leading: Padding(
        padding: EdgeInsets.all(8.w),
        child: Row(
          children: [
            Icon(Icons.diamond, size: 28.w, color: Colors.white),
            SizedBox(width: 4.w),
            Text(
              'Balaji',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      leadingWidth: 110.w,
      actions: [
        // User icon in top right - tap to go to Settings
        Consumer<AuthProvider>(
          builder: (context, auth, child) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = 5; // Settings index
                });
                _pageController.animateToPage(
                  5,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Center(
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    radius: 18.r,
                    child: Icon(
                      Icons.person,
                      size: 20.w,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Mobile Bottom Navigation Bar
  Widget _buildMobileBottomNav() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF1E3A8A),
      type: BottomNavigationBarType.fixed,
      currentIndex: _getBottomNavIndex(),
      onTap: (index) {
        // Map bottom nav index back to page index
        // Order: Categories(0), Customers(1), Dashboard/Home(2), Billing(3), Settings(4)
        final pageIndices = [1, 3, 0, 2, 5];
        final pageIndex = pageIndices[index];

        setState(() {
          _currentIndex = pageIndex;
        });
        _pageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.category),
          label: 'Categories',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.people),
          label: 'Customers',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.receipt),
          label: 'Billing',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      showSelectedLabels: true,
      showUnselectedLabels: false,
    );
  }

  // Helper to get bottom nav index from current page index
  int _getBottomNavIndex() {
    // Maps page indices to bottom nav indices
    // Page order: Dashboard(0), Categories(1), Billing(2), Customers(3), Reports(4), Settings(5)
    // Bottom nav order: Categories(0), Customers(1), Dashboard(2), Billing(3), Settings(4)
    const pageToBottomNavMap = {
      0: 2, // Dashboard -> Home (center)
      1: 0, // Categories -> Categories
      2: 3, // Billing -> Billing
      3: 1, // Customers -> Customers
      4: -1, // Reports (not in bottom nav)
      5: 4, // Settings -> Settings
    };
    return pageToBottomNavMap[_currentIndex] ?? 2;
  }

  // ============== DESKTOP LAYOUT ==============
  Widget _buildDesktopLayout() {
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
      width: 280.w,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                Icon(Icons.diamond, size: 40.w, color: Colors.white),
                SizedBox(height: 12.h),
                Text(
                  'Balaji Imitation',
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Admin Panel',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              itemCount: _screens.length,
              itemBuilder: (context, index) {
                final item = _screens[index];
                final isSelected = _currentIndex == index;

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
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
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20.w,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              item.title,
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white70,
                              ),
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
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
              ),
            ),
            child: Column(
              children: [
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 20.r,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20.w,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authProvider.currentAdmin?.fullName ?? 'Admin',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                authProvider.currentAdmin?.username ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.sp,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: Icon(Icons.logout, size: 16.w),
                    label: Text(
                      'Logout',
                      style: GoogleFonts.poppins(fontSize: 12.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
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

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Billing Screen - Coming Soon'));
  }
}

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Customers Screen - Coming Soon'));
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Reports Screen - Coming Soon'));
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Settings Screen - Coming Soon'));
  }
}
