//setting_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

// DARK MODE
const Color darkBg = Color.fromARGB(255, 22, 22, 22);
const Color darkSurface = Color.fromARGB(255, 46, 44, 44);

// LIGHT MODE
const Color lightBg = Colors.white;
const Color lightSurface = Color(0xFFF4F4F4);

// COMMON
const Color nudeBrown = Color(0xFF8B6F47);

// Removed context-dependent consts from top-level.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool _notifications = true;
  bool _savingProfile = false;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final admin = auth.currentAdmin;

    _nameCtrl.text =
        admin?.fullName ?? prefs.getString('settings_name') ?? 'User';
    _usernameCtrl.text =
        admin?.username ?? prefs.getString('settings_username') ?? 'username';
    _emailCtrl.text = admin?.email ?? prefs.getString('settings_email') ?? '';
    _phoneCtrl.text =
        admin?.phoneNumber ?? prefs.getString('settings_phone') ?? '';
    _addressCtrl.text =
        admin?.address ?? prefs.getString('settings_address') ?? '';
    _notifications = prefs.getBool('settings_notifications') ?? true;
    if (mounted) setState(() {});
  }

  Future<void> _persistProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_name', _nameCtrl.text.trim());
    await prefs.setString('settings_username', _usernameCtrl.text.trim());
    await prefs.setString('settings_email', _emailCtrl.text.trim());
    await prefs.setString('settings_phone', _phoneCtrl.text.trim());
    await prefs.setString('settings_address', _addressCtrl.text.trim());
    await prefs.setBool('settings_notifications', _notifications);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // ONLY COLOR-RELATED CHANGES MADE
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color surface = isDark
        ? const Color.fromARGB(255, 22, 22, 22)
        : lightBg;
    final Color cardColor = isDark
        ? const Color.fromARGB(255, 42, 43, 44)
        : lightSurface;
    final Color textPrimary = isDark ? Colors.white : Colors.grey[800]!;

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardColor,
        iconTheme: IconThemeData(color: textPrimary),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Account', textPrimary),
              _accountCard(cardColor, textPrimary, isDark),
              SizedBox(height: 16.h),
              _sectionTitle('Preferences', textPrimary),
              _preferencesCard(cardColor, textPrimary),
              SizedBox(height: 16.h),
              _sectionTitle('Security', textPrimary),
              _securityCard(cardColor, textPrimary),
              SizedBox(height: 16.h),
              _sectionTitle('About', textPrimary),
              _aboutCard(cardColor, textPrimary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _accountCard(Color cardColor, Color primary, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: Theme.of(context).brightness == Brightness.light
                ? 12
                : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28.w,
            backgroundColor: isDark ? Colors.transparent : Colors.white,
            child: Icon(Icons.person, color: primary, size: 28.w),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameCtrl.text.isEmpty ? 'User' : _nameCtrl.text,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _usernameCtrl.text.isEmpty ? 'username' : _usernameCtrl.text,
                  style: GoogleFonts.inter(color: isDark ? primary : primary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _openEditProfile,
            icon: Icon(
              Icons.edit,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _preferencesCard(Color cardColor, Color primary) {
    final theme = Provider.of<ThemeProvider>(context);
    final themeLabel = theme.themeMode == ThemeMode.dark ? 'Dark' : 'Light';
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey.shade600.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: Theme.of(context).brightness == Brightness.light
                ? 12
                : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _tile(
            icon: Icons.color_lens_outlined,
            title: 'Appearance',
            subtitle: 'Theme: $themeLabel',
            onTap: _openThemePicker,
            primary: primary,
          ),
          _tile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage push and email notifications',
            trailing: Switch(
              value: _notifications,
              onChanged: (val) async {
                setState(() => _notifications = val);
                await _persistProfile();
              },
            ),
            primary: primary,
          ),
        ],
      ),
    );
  }

  Widget _securityCard(Color cardColor, Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey.shade600.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _tile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your login password',
            onTap: _openChangePassword,
            primary: primary,
          ),
        ],
      ),
    );
  }

  Widget _aboutCard(Color cardColor, Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey.shade600.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _tile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0',
            onTap: () {},
            primary: primary,
          ),
          _tile(
            icon: Icons.description_outlined,
            title: 'Terms & Services',
            subtitle: 'View the latest terms',
            onTap: _openTerms,
            primary: primary,
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    required Color primary,
  }) {
    return ListTile(
      leading: Icon(icon, color: primary),
      title: Text(
        title,
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primary),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: GoogleFonts.inter(color: primary.withOpacity(0.7)),
            )
          : null,
      trailing: trailing ?? Icon(Icons.chevron_right, color: primary),
      onTap: onTap,
    );
  }

  Future<void> _openEditProfile() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12.h,
            left: 16.w,
            right: 16.w,
            top: 18.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetGrabber(),
              SizedBox(height: 12.h),
              _textField('Full name', _nameCtrl),
              SizedBox(height: 10.h),
              _textField('Username', _usernameCtrl),
              SizedBox(height: 10.h),
              _textField(
                'Email',
                _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 10.h),
              _textField(
                'Phone number',
                _phoneCtrl,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 10.h),
              _textField('Address', _addressCtrl, maxLines: 2),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _savingProfile
                    ? null
                    : () async {
                        if (!mounted) return;
                        setState(() => _savingProfile = true);

                        final auth = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );

                        final updated = await auth.updateProfile(
                          fullName: _nameCtrl.text.trim(),
                          username: _usernameCtrl.text.trim(),
                          email: _emailCtrl.text.trim().isEmpty
                              ? null
                              : _emailCtrl.text.trim(),
                          phoneNumber: _phoneCtrl.text.trim().isEmpty
                              ? null
                              : _phoneCtrl.text.trim(),
                          address: _addressCtrl.text.trim().isEmpty
                              ? null
                              : _addressCtrl.text.trim(),
                        );

                        if (!mounted) return;
                        setState(() => _savingProfile = false);

                        if (updated != null) {
                          await _persistProfile();
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile updated')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                auth.errorMessage ?? 'Unable to update profile',
                              ),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48.h),
                  backgroundColor: Theme.of(
                    context,
                  ).elevatedButtonTheme.style?.backgroundColor?.resolve({}),
                ),
                child: _savingProfile
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openChangePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12.h,
            left: 16.w,
            right: 16.w,
            top: 18.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetGrabber(),
              SizedBox(height: 12.h),
              _textField('Current password', currentCtrl, obscure: true),
              SizedBox(height: 10.h),
              _textField('New password', newCtrl, obscure: true),
              SizedBox(height: 10.h),
              _textField('Confirm new password', confirmCtrl, obscure: true),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () async {
                  if (newCtrl.text.trim() != confirmCtrl.text.trim()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passwords do not match')),
                    );
                    return;
                  }

                  final auth = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  final ok = await auth.changePassword(
                    currentCtrl.text.trim(),
                    newCtrl.text.trim(),
                  );

                  if (mounted) Navigator.pop(ctx);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Password updated'
                              : auth.errorMessage ??
                                    'Unable to update password',
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48.h),
                  backgroundColor: Theme.of(
                    context,
                  ).elevatedButtonTheme.style?.backgroundColor?.resolve({}),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _sheetGrabber() {
    return Container(
      width: 44.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
    );
  }

  Future<void> _openTerms() async {
    const termsText =
        'By using this application, you agree to abide by the platform policies, maintain accurate account information, and comply with applicable laws. Data is processed in accordance with our privacy practices. Continued use constitutes acceptance of updates to these terms.';

    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetGrabber(),
              SizedBox(height: 12.h),
              Text(
                'Terms & Services',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                termsText,
                style: GoogleFonts.inter(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              SizedBox(height: 14.h),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openThemePicker() async {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetGrabber(),
              SizedBox(height: 12.h),
              _themeOption('Light', ThemeMode.light, theme.themeMode, theme),
              _themeOption('Dark', ThemeMode.dark, theme.themeMode, theme),
            ],
          ),
        );
      },
    );
  }

  Widget _themeOption(
    String label,
    ThemeMode value,
    ThemeMode current,
    ThemeProvider provider,
  ) {
    return ListTile(
      leading: Icon(
        value == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
      ),
      title: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      trailing: Radio<ThemeMode>(
        value: value,
        groupValue: current,
        onChanged: (mode) async {
          if (mode == null) return;
          await provider.setThemeMode(mode);
          if (mounted) Navigator.pop(context);
        },
      ),
      onTap: () async {
        await provider.setThemeMode(value);
        if (mounted) Navigator.pop(context);
      },
    );
  }
}
