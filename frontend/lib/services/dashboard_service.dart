import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardService {
  final String baseUrl = "http://localhost:3000/api/dashboard";
 // final String baseUrl = "http://10.0.2.2:3000/api/dashboard";
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dashboard stats');
    }
  }
}
