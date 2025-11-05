import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final DatabaseService _databaseService = DatabaseService();
  Admin? _currentAdmin;
  bool _isLoggedIn = false;

  Admin? get currentAdmin => _currentAdmin;
  bool get isLoggedIn => _isLoggedIn;

  Future<bool> login(String username, String password) async {
    try {
      final admin = await _databaseService.getAdminByUsername(username);

      if (admin != null && admin.password == password) {
        _currentAdmin = admin;
        _isLoggedIn = true;

        // Update last login
        await _databaseService.updateAdminLastLogin(admin.id!);

        // Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setInt('adminId', admin.id!);

        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> register(Admin admin) async {
    try {
      // Check if username already exists
      final existingAdmin = await _databaseService.getAdminByUsername(
        admin.username,
      );
      if (existingAdmin != null) {
        print('Username already exists: ${admin.username}');
        return false; // Username already exists
      }

      // Insert new admin
      final adminId = await _databaseService.insertAdmin(admin);
      if (adminId > 0) {
        _currentAdmin = admin.copyWith(id: adminId);
        _isLoggedIn = true;

        // Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setInt('adminId', adminId);

        return true;
      }
      return false;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _currentAdmin = null;
    _isLoggedIn = false;

    // Clear login state
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('adminId');
  }

  Future<bool> checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final adminId = prefs.getInt('adminId');

      if (isLoggedIn && adminId != null) {
        // Verify admin still exists
        final admin = await _databaseService.getAdminByUsername(
          _currentAdmin?.username ?? '',
        );
        if (admin != null) {
          _currentAdmin = admin;
          _isLoggedIn = true;
          return true;
        }
      }

      await logout();
      return false;
    } catch (e) {
      print('Check login status error: $e');
      await logout();
      return false;
    }
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_currentAdmin == null) return false;

    if (_currentAdmin!.password != currentPassword) {
      return false; // Current password is incorrect
    }

    try {
      final updatedAdmin = _currentAdmin!.copyWith(password: newPassword);
      final result = await _databaseService.updateAdmin(updatedAdmin);

      if (result > 0) {
        _currentAdmin = updatedAdmin;
        return true;
      }
      return false;
    } catch (e) {
      print('Change password error: $e');
      return false;
    }
  }
}
