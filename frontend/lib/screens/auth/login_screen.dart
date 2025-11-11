import 'package:balaji_imitation_admin/main/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final isTablet = constraints.maxWidth < 1000;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFF60A5FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isMobile
                        ? constraints.maxWidth * 0.9
                        : isTablet
                            ? 500.w
                            : 600.w,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo and title
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 20.h : 30.h,
                          horizontal: 20.w,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20.r,
                              offset: Offset(0, 10.h),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.diamond,
                                size: isMobile ? 60.w : 80.w,
                                color: const Color(0xFF1E3A8A)),
                            SizedBox(height: 12.h),
                            Text(
                              'Balaji Imitation',
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 24.sp : 28.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E3A8A),
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              'Admin Management System',
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 13.sp : 15.sp,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isMobile ? 30.h : 50.h),

                      // Login form card
                      Container(
                        padding: EdgeInsets.all(isMobile ? 20.w : 28.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20.r,
                              offset: Offset(0, 10.h),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Login',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 22.sp : 26.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E3A8A),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 25.h),

                              // Username
                              CustomTextField(
                                controller: _usernameController,
                                labelText: 'Username',
                                prefixIcon: Icons.person,
                                validator: (value) =>
                                    value!.isEmpty ? 'Please enter username' : null,
                              ),
                              SizedBox(height: 16.h),

                              // Password
                              CustomTextField(
                                controller: _passwordController,
                                labelText: 'Password',
                                prefixIcon: Icons.lock,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    size: 22.w,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (value) =>
                                    value!.isEmpty ? 'Please enter password' : null,
                              ),
                              SizedBox(height: 24.h),

                              // Login Button
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, _) {
                                  return CustomButton(
                                    text: 'Login',
                                    onPressed: authProvider.isLoading
                                        ? null
                                        : _handleLogin,
                                    isLoading: authProvider.isLoading,
                                  );
                                },
                              ),
                              SizedBox(height: 16.h),

                              // Error Message
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, _) {
                                  if (authProvider.errorMessage == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Container(
                                    margin: EdgeInsets.symmetric(vertical: 8.h),
                                    padding: EdgeInsets.all(10.w),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(color: Colors.red[200]!),
                                    ),
                                    child: Text(
                                      authProvider.errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.sp,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 18.h),

                              // Register link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const RegisterScreen()),
                                    ),
                                    child: Text(
                                      'Register',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF3B82F6),
                                      ),
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }
}
