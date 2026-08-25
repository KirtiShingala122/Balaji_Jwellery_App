import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin.dart';
import '../config/api_config.dart';
// Optional: uses Firebase ID token if present in SharedPreferences

class AuthService {
  static final String baseUrl = Api.api('/api/auth');
  //static const String baseUrl = 'http://10.0.2.2:3000/api/auth';

  Admin? _currentAdmin;
  bool _isLoggedIn = false;
  String? _token; // Store JWT token

  // Shared Preferences keys
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyAdminData = 'adminData';
  static const String _keyToken = 'token';

  Admin? get currentAdmin => _currentAdmin;
  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;

  static const String _fbTokenKey = 'firebase_id_token';

  Future<Map<String, String>> _defaultHeaders({String? firebaseIdToken}) async {
    final prefs = await SharedPreferences.getInstance();
    final storedFbToken = prefs.getString(_fbTokenKey);
    final effectiveFbToken = firebaseIdToken ?? storedFbToken;

    String? authValue;
    if (effectiveFbToken != null && effectiveFbToken.isNotEmpty) {
      // Prefer Firebase ID token when available
      authValue = 'Bearer $effectiveFbToken';
    } else if (_token != null) {
      authValue = 'Bearer $_token';
    }

    final headers = {'Content-Type': 'application/json'};
    if (authValue != null) headers['Authorization'] = authValue;
    return headers;
  }

  ///  Register new admin
  Future<bool> register(Admin admin, {String? firebaseIdToken}) async {
    final url = Uri.parse('$baseUrl/register');
    try {
      final headers = await _defaultHeaders(firebaseIdToken: firebaseIdToken);
      Map<String, dynamic> payload;
      if (firebaseIdToken != null) {
        payload = {
          'username': admin.username,
          'email': admin.email,
          'fullName': admin.fullName,
          'phoneNumber': admin.phoneNumber,
          'address': admin.address,
          // firebaseUid is not required in body, backend will extract from token, but send for debug
        };
      } else {
        payload = {
          'username': admin.username,
          'password': admin.password,
          'email': admin.email,
          'fullName': admin.fullName,
          'phoneNumber': admin.phoneNumber,
          'address': admin.address,
        };
      }
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );
      if (response.statusCode == 201) {
        print(' Registration successful');
        return true;
      } else {
        print(' Register failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print(' Register error: $e');
      return false;
    }
  }

  /// Login existing admin
  Future<bool> login(
    String username,
    String password, {
    String? firebaseIdToken,
  }) async {
    final url = Uri.parse('$baseUrl/login');
    try {
      final headers = await _defaultHeaders(firebaseIdToken: firebaseIdToken);
      final response = await http.post(
        url,
        headers: headers,
        body: firebaseIdToken != null
            ? jsonEncode({})
            : jsonEncode({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['admin'] != null) {
          _currentAdmin = Admin.fromMap(data['admin']);
        }

        // Firebase-backed login will not return a legacy token; keep for
        // backward compatibility if provided.
        _token = data['token'];
        _isLoggedIn = true;
        await _saveLoginData();

        print(' Login successful for ${_currentAdmin?.username}');
        return true;
      } else {
        print(' Login failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print(' Login error: $e');
      return false;
    }
  }

  ///  Logout
  Future<void> logout() async {
    _isLoggedIn = false;
    _currentAdmin = null;
    _token = null;

    // Clear SharedPreferences
    await _clearLoginData();

    print(' Logged out');
  }

  ///  Check login status (for app start)
  Future<bool> checkLoginStatus() async {
    // Load from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

    if (isLoggedIn) {
      final adminDataString = prefs.getString(_keyAdminData);
      final token = prefs.getString(_keyToken);

      if (adminDataString != null) {
        _currentAdmin = Admin.fromMap(jsonDecode(adminDataString));
        _token = token;
        _isLoggedIn = true;
        print(' Restored login session for ${_currentAdmin?.username}');
        return true;
      }
    }

    return false;
  }

  /// Save login data to SharedPreferences
  Future<void> _saveLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    if (_currentAdmin != null) {
      await prefs.setString(_keyAdminData, jsonEncode(_currentAdmin!.toMap()));
    }
    if (_token != null) {
      await prefs.setString(_keyToken, _token!);
    }
  }

  /// Clear login data from SharedPreferences
  Future<void> _clearLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyAdminData);
    await prefs.remove(_keyToken);
  }

  ///  Change Password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final url = Uri.parse('$baseUrl/change-password');
    try {
      final headers = await _defaultHeaders();
      final res = await http.put(
        url,
        headers: headers,
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (res.statusCode == 200) {
        return true;
      } else {
        print(' Change password failed: ${res.body}');
        return false;
      }
    } catch (e) {
      print(' Change password error: $e');
      return false;
    }
  }

  /// Update profile (name/username/email/phone/address)
  Future<Admin?> updateProfile({
    required String fullName,
    required String username,
    String? email,
    String? phoneNumber,
    String? address,
  }) async {
    final url = Uri.parse('$baseUrl/profile');
    try {
      final headers = await _defaultHeaders();
      final res = await http.put(
        url,
        headers: headers,
        body: jsonEncode({
          'fullName': fullName,
          'username': username,
          'email': email,
          'phoneNumber': phoneNumber,
          'address': address,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _currentAdmin = Admin.fromMap({
          ...?_currentAdmin?.toMap(),
          ...data['admin'],
          'password': _currentAdmin?.password ?? '',
        });
        await _saveLoginData();
        return _currentAdmin;
      }

      print(' Update profile failed: ${res.body}');
      return null;
    } catch (e) {
      print(' Update profile error: $e');
      return null;
    }
  }
}
