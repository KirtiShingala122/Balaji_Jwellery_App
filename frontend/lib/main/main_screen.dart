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

  // Responsive breakpoint
  static const double _desktopBreakpoint = 800;

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
    final bool isMobile =
        MediaQuery.of(context).size.width < _desktopBreakpoint;

    if (isMobile) {
      return _buildMobileLayout();
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
  // ⬇⬇⬇ DESKTOP DESIGN (kept original, not redesigned)
  // ---------------------------------------------------------------------------
  Widget _buildDesktopLayout() {
    return const Center(
      child: Text(
        "Desktop layout coming soon...",
        style: TextStyle(fontSize: 22),
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
