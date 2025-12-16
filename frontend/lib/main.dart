import 'package:balaji_imitation_admin/main/main_screen.dart';
import 'package:balaji_imitation_admin/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermission();

  runApp(const BalajiImitationApp());
}

class BalajiImitationApp extends StatelessWidget {
  const BalajiImitationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Automatically adjust the design size based on device width
        Size baseSize;

        if (constraints.maxWidth <= 600) {
          baseSize = const Size(390, 844); //  phones
        } else if (constraints.maxWidth <= 1100) {
          baseSize = const Size(800, 1280); // tablets
        } else {
          baseSize = const Size(1920, 1080); //  desktops/laptops
        }

        return ScreenUtilInit(
          designSize: baseSize,
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => AuthProvider()),
                ChangeNotifierProvider(create: (_) => DashboardProvider()),
                ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ],
              child: Consumer<ThemeProvider>(
                builder: (context, theme, _) {
                  // Define colors based on theme
                  final isDark = theme.themeMode == ThemeMode.dark;
                  final scaffoldColor = isDark
                      ? const Color.fromARGB(255, 22, 22, 22)
                      : Colors.white;
                  final cardColor = scaffoldColor; // Same for simplicity
                  final textColor = isDark
                      ? Colors.white
                      : Colors.grey.shade800;
                  final secondaryTextColor = isDark
                      ? Colors.white70
                      : Colors.grey.shade600;
                  final baseLightText = GoogleFonts.poppinsTextTheme();
                  final lightTheme = ThemeData(
                    brightness: Brightness.light,
                    scaffoldBackgroundColor: scaffoldColor,
                    canvasColor: cardColor,
                    cardColor: cardColor,
                    textTheme: baseLightText.apply(
                      bodyColor: textColor,
                      displayColor: textColor,
                    ),
                    appBarTheme: AppBarTheme(
                      backgroundColor: cardColor,
                      foregroundColor: textColor,
                      elevation: 0,
                      centerTitle: true,
                      titleTextStyle: GoogleFonts.poppins(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    elevatedButtonTheme: ElevatedButtonThemeData(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B6F47),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: secondaryTextColor.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: secondaryTextColor.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: Color(0xFF8B6F47),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      labelStyle: TextStyle(color: textColor),
                      floatingLabelStyle: TextStyle(color: textColor),
                      hintStyle: TextStyle(color: secondaryTextColor),
                      prefixIconColor: secondaryTextColor,
                      suffixIconColor: secondaryTextColor,
                    ),
                    iconTheme: IconThemeData(color: textColor),
                    dividerColor: secondaryTextColor.withValues(alpha: 0.2),
                  );

                  final darkTheme = ThemeData(
                    brightness: Brightness.dark,
                    scaffoldBackgroundColor: scaffoldColor,
                    canvasColor: cardColor,
                    cardColor: cardColor,
                    textTheme: GoogleFonts.poppinsTextTheme(
                      ThemeData.dark().textTheme.apply(
                        bodyColor: textColor,
                        displayColor: textColor,
                      ),
                    ),
                    appBarTheme: AppBarTheme(
                      backgroundColor: cardColor,
                      foregroundColor: textColor,
                      elevation: 0,
                      centerTitle: true,
                      titleTextStyle: GoogleFonts.poppins(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    elevatedButtonTheme: ElevatedButtonThemeData(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B6F47),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: secondaryTextColor.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: secondaryTextColor.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: Color(0xFF8B6F47),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      labelStyle: TextStyle(color: textColor),
                      floatingLabelStyle: TextStyle(color: textColor),
                      hintStyle: TextStyle(color: secondaryTextColor),
                      prefixIconColor: secondaryTextColor,
                      suffixIconColor: secondaryTextColor,
                    ),
                    iconTheme: IconThemeData(color: textColor),
                    dividerColor: secondaryTextColor.withValues(alpha: 0.2),
                  );

                  return MaterialApp(
                    title: 'Balaji Imitation Admin',
                    debugShowCheckedModeBanner: false,
                    theme: lightTheme,
                    darkTheme: darkTheme,
                    themeMode: theme.themeMode,
                    home: const AuthWrapper(),
                    routes: {
                      '/login': (context) => const LoginScreen(),
                      '/main': (context) => const MainScreen(),
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = await authProvider.checkLoginStatus();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              isLoggedIn ? const MainScreen() : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
