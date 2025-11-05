import 'package:flutter/foundation.dart';
import '../models/admin.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  Admin? _currentAdmin;
  bool _isLoading = false;
  String? _errorMessage;

  Admin? get currentAdmin => _currentAdmin;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _authService.isLoggedIn;

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.login(username, password);
      if (success) {
        _currentAdmin = _authService.currentAdmin;
        notifyListeners();
        return true;
      } else {
        _setError('Invalid username or password');
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(Admin admin) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.register(admin);
      if (success) {
        _currentAdmin = _authService.currentAdmin;
        notifyListeners();
        return true;
      } else {
        _setError('Registration failed. Username or email may already exist.');
        return false;
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    await _authService.logout();
    _currentAdmin = null;
    _clearError();
    notifyListeners();
    _setLoading(false);
  }

  Future<bool> checkLoginStatus() async {
    _setLoading(true);
    try {
      final isLoggedIn = await _authService.checkLoginStatus();
      if (isLoggedIn) {
        _currentAdmin = _authService.currentAdmin;
      } else {
        _currentAdmin = null;
      }
      notifyListeners();
      return isLoggedIn;
    } catch (e) {
      _setError('Failed to check login status: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.changePassword(currentPassword, newPassword);
      if (success) {
        _currentAdmin = _authService.currentAdmin;
        notifyListeners();
        return true;
      } else {
        _setError('Failed to change password. Current password may be incorrect.');
        return false;
      }
    } catch (e) {
      _setError('Failed to change password: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
