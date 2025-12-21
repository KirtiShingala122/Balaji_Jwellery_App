import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class DashboardService {
  late final String baseUrl;

  DashboardService() {
    baseUrl = Api.api('/api/dashboard');
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(Uri.parse('$baseUrl/summary'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Failed to load dashboard stats (${response.statusCode})',
      );
    }
  }
}
