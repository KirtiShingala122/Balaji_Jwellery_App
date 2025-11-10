import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:3000/api/auth';
  //static const String baseUrl = 'http://10.0.2.2:3000/api/auth';

  Admin? _currentAdmin;
  bool _isLoggedIn = false;
  String? _token; // Store JWT token

  Admin? get currentAdmin => _currentAdmin;
  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;

  ///  Register new admin
  Future<bool> register(Admin admin) async {
    final url = Uri.parse('$baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': admin.username,
          'email': admin.email,
          'fullName': admin.fullName,
          'password': admin.password,
        }),
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
  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _currentAdmin = Admin.fromMap(data['admin']);
        _token = data['token']; // Save JWT
        _isLoggedIn = true;

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
    print(' Logged out');
  }

  ///  Check login status (for app start)
  Future<bool> checkLoginStatus() async {
    // You can enhance this later to validate token expiry
    return _isLoggedIn;
  }

  ///  Change Password (to be implemented later)
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    print(' Change password feature not implemented yet.');
    return false;
  }
}
