import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/admin.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F6),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              children: [
                _buildSectionTitle('Account'),
                _buildProfileCard(authProvider.currentAdmin),
                SizedBox(height: 24.h),
                _buildSectionTitle('Preferences'),
                _buildSettingsCard(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.palette_outlined,
                      title: 'Appearance',
                      subtitle: 'Customize theme, colors, and fonts',
                      onTap: () {
                        // TODO: Implement theme customization
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage push and email notifications',
                      onTap: () {
                        // TODO: Implement notification settings
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.language_outlined,
                      title: 'Language',
                      subtitle: 'English (United States)',
                      onTap: () {
                        // TODO: Implement language selection
                      },
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                _buildSectionTitle('Security'),
                _buildSettingsCard(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      subtitle: 'Update your login password',
                      onTap: () {
                        // TODO: Implement change password flow
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.phonelink_lock_outlined,
                      title: 'Two-Factor Authentication',
                      subtitle: 'Add an extra layer of security',
                      onTap: () {
                        // TODO: Implement 2FA setup
                      },
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                _buildSectionTitle('About'),
                _buildSettingsCard(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.info_outline,
                      title: 'App Version',
                      subtitle: '1.0.0',
                    ),
                    _buildSettingsTile(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      onTap: () {},
                    ),
                    _buildSettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
          const Icon(Icons.settings_outlined, color: Colors.white, size: 32),
          SizedBox(width: 16.w),
          Text(
            'Settings',
            style: GoogleFonts.poppins(
              fontSize: 22.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildProfileCard(Admin? admin) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      shadowColor: const Color(0xFFB48F85).withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30.r,
              backgroundColor: const Color(0xFFF1E6E3),
              child: Icon(
                Icons.person_outline,
                size: 30.r,
                color: const Color(0xFFB48F85),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    admin?.fullName ?? 'Admin User',
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    admin?.username ?? 'admin',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFFB48F85)),
              onPressed: () {
                // TODO: Implement edit profile action
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      shadowColor: const Color(0xFFB48F85).withOpacity(0.1),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFB48F85)),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 12.sp,
              ),
            )
          : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: Colors.grey)
          : null,
      onTap: onTap,
    );
  }
}
