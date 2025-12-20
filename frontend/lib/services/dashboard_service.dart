import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class DashboardService {
  late final String baseUrl;

  DashboardService() {
    if (kIsWeb) {
      baseUrl = "http://localhost:3000/api/dashboard";
    } else if (Platform.isAndroid) {
      baseUrl = "http://10.0.2.2:3000/api/dashboard";
    } else {
      baseUrl = "http://localhost:3000/api/dashboard";
    }
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
