//main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'dashboard_screen.dart';
import 'categories_screen.dart';
import 'customers_screen.dart';
import 'billing_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  // Responsive breakpoints
  static const double _tabletBreakpoint = 768;
  static const double _desktopBreakpoint = 1024;

  final List<MainScreenItem> _screens = [
    MainScreenItem(
      title: 'Dashboard',
      icon: Icons.home_outlined,
      screen: const DashboardScreen(),
    ),
    MainScreenItem(
      title: 'Categories',
      icon: Icons.category_outlined,
      screen: const CategoriesScreen(),
    ),
    MainScreenItem(
      title: 'Customers',
      icon: Icons.people_outline,
      screen: const CustomersScreen(),
    ),
    MainScreenItem(
      title: 'Billing',
      icon: Icons.receipt_outlined,
      screen: const BillingScreen(),
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
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < _tabletBreakpoint) {
      return _buildMobileLayout();
    } else if (screenWidth < _desktopBreakpoint) {
      return _buildTabletLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  // ---------------------------------------------------------------------------
  // ⬇⬇⬇ MOBILE DESIGN — Luxury Balaji UI (matching Categories Screen)
  // ---------------------------------------------------------------------------
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildLuxuryAppBar(),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens.map((item) => item.screen).toList(),
      ),
      bottomNavigationBar: _buildLuxuryBottomNav(),
    );
  }

  //  Top Navigation (Redesigned to match Category UI)
  AppBar _buildLuxuryAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: false,
      title: Text(
        'Balaji',
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 28.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: const Color(0xFF8B6F47),
        ),
      ),
      actions: [
        Consumer<AuthProvider>(
          builder: (context, auth, child) {
            return Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                child: Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 22.w,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 🌟 Bottom Navigation (Matches high-end category UI)
  Widget _buildLuxuryBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white.withOpacity(0.1)
                : Theme.of(context).dividerColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _screens.length,
              (index) => _luxuryNavItem(
                icon: _screens[index].icon,
                label: _screens[index].title,
                isSelected: _currentIndex == index,
                onTap: () {
                  setState(() => _currentIndex = index);
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 📌 Individual Bottom Nav Item
  Widget _luxuryNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.1),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24.sp,
              color: isSelected
                  ? const Color(0xFF8B6F47)
                  : (Theme.of(context).brightness == Brightness.light
                        ? Colors.grey[800]!.withValues(alpha: 0.6)
                        : Theme.of(
                            context,
                          ).iconTheme.color?.withValues(alpha: 0.6)),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF8B6F47)
                    : (Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[800]!.withValues(alpha: 0.6)
                          : Theme.of(context).textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ⬇⬇⬇ TABLET LAYOUT - Side Navigation with larger content
  // ---------------------------------------------------------------------------
  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // Side Navigation
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey.shade300.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Text(
                        'Balaji',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: const Color(0xFF8B6F47),
                        ),
                      ),
                      const Spacer(),
                      _buildUserAvatar(),
                    ],
                  ),
                ),
                const Divider(),
                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    itemCount: _screens.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      return _buildSideNavItem(
                        icon: _screens[index].icon,
                        label: _screens[index].title,
                        isSelected: _currentIndex == index,
                        onTap: () => setState(() => _currentIndex = index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(child: _screens[_currentIndex].screen),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ⬇⬇⬇ DESKTOP LAYOUT - Full dashboard with navigation
  // ---------------------------------------------------------------------------
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // Expanded Side Navigation
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey.shade300.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Enhanced Header
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF8B6F47,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.diamond_outlined,
                              color: Color(0xFF8B6F47),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Balaji',
                                  style: TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    color: const Color(0xFF8B6F47),
                                  ),
                                ),
                                Text(
                                  'Jewelry Management',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.light
                                        ? Colors.grey[600]
                                        : Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // _buildUserAvatar(), // Settings icon removed from desktop sidebar
                    ],
                  ),
                ),
                const Divider(),
                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    itemCount: _screens.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      return _buildDesktopNavItem(
                        icon: _screens[index].icon,
                        label: _screens[index].title,
                        isSelected: _currentIndex == index,
                        onTap: () => setState(() => _currentIndex = index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.grey.shade200.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        _screens[_currentIndex].title,
                        style: GoogleFonts.roboto(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? Colors.grey[800]
                              : Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Consumer<AuthProvider>(
                        builder: (context, auth, child) {
                          return IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              );
                            },
                            tooltip: 'Settings',
                            icon: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Colors.grey[100]
                                    : Colors.grey[800],
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.light
                                        ? Colors.grey.shade300.withValues(
                                            alpha: 0.5,
                                          )
                                        : Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.settings_outlined,
                                size: 24,
                                color: Theme.of(context).iconTheme.color,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(child: _screens[_currentIndex].screen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widgets for Navigation
  Widget _buildUserAvatar() {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[100]
                  : Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.settings_outlined,
              size: 20,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSideNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF8B6F47).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? const Color(0xFF8B6F47)
              : (Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[600]
                    : Colors.white70),
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? const Color(0xFF8B6F47)
                : (Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[700]
                      : Colors.white),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDesktopNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF8B6F47).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: const Color(0xFF8B6F47).withValues(alpha: 0.3))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF8B6F47).withValues(alpha: 0.2)
                : (Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[100]
                      : Colors.grey[800]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? const Color(0xFF8B6F47)
                : (Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[600]
                      : Colors.white70),
          ),
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF8B6F47)
                : (Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[700]
                      : Colors.white),
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// SCREEN HOLDER MODEL
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
