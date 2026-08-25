import 'package:flutter/foundation.dart';
import '../models/admin.dart';
import '../services/auth_service.dart';
import '../services/firebase_auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseAuthService _fbService = FirebaseAuthService();

  Admin? _currentAdmin;
  bool _isLoading = false;
  String? _errorMessage;

  Admin? get currentAdmin => _currentAdmin;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isFirebaseSignedIn => _fbService.isSignedIn;

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // 1️ Firebase login (source of truth)
      await _fbService.loginWithEmailPassword(email, password);
      final idToken = await _fbService.getIdToken();

      if (idToken == null) {
        _setError('Firebase authentication failed');
        return false;
      }

      // 2️ Backend verification (profile fetch)
      final success = await _authService.login(
        '', // username not needed for Firebase login
        '', // password not sent to backend
        firebaseIdToken: idToken,
      );

      if (!success) {
        _setError('Server verification failed');
        return false;
      }

      // Mark app as logged in
      _currentAdmin = _authService.currentAdmin;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(Admin admin) async {
    _setLoading(true);
    _clearError();

    try {
      // Create Firebase account first to obtain a verified ID token.
      await _fbService.registerWithEmailPassword(admin.email, admin.password);

      final idToken = await _fbService.getIdToken();
      if (idToken == null) {
        _setError('Unable to retrieve Firebase session. Please try again.');
        return false;
      }

      final success = await _authService.register(
        admin,
        firebaseIdToken: idToken,
      );

      if (success) {
        _currentAdmin = _authService.currentAdmin ?? admin;
        notifyListeners();
        return true;
      }

      _setError('Registration failed. Username or email may already exist.');
      return false;
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    // Logout from both backend service and Firebase (if signed in)
    try {
      await _fbService.logout();
    } catch (_) {}
    await _authService.logout();
    _currentAdmin = null;
    _clearError();
    notifyListeners();
    _setLoading(false);
  }

  Future<bool> checkLoginStatus() async {
    _setLoading(true);
    try {
      //  Firebase decides session
      if (!_fbService.isSignedIn) {
        _currentAdmin = null;
        return false;
      }

      final idToken = await _fbService.getIdToken();
      if (idToken == null) return false;

      // Ask backend for profile
      final success = await _authService.login(
        '',
        '',
        firebaseIdToken: idToken,
      );

      if (success) {
        _currentAdmin = _authService.currentAdmin;
        notifyListeners();
        return true;
      }

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    // Password changes are managed by Firebase only
    _setError('Password is managed by Firebase. Use "Forgot Password".');
    return false;
  }

  Future<Admin?> updateProfile({
    required String fullName,
    required String username,
    String? email,
    String? phoneNumber,
    String? address,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final updated = await _authService.updateProfile(
        fullName: fullName,
        username: username,
        email: email,
        phoneNumber: phoneNumber,
        address: address,
      );
      if (updated != null) {
        _currentAdmin = updated;
        notifyListeners();
        return updated;
      }
      _setError('Failed to update profile');
      return null;
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
      return null;
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
