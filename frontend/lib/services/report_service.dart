import 'dart:convert';
import 'package:http/http.dart' as http;

class ReportService {
  final String baseUrl = "http://localhost:3000/api/reports";
  //final String baseUrl = "http://10.0.2.2:3000/api/reports";

  Future<List<Map<String, dynamic>>> getMonthlySales() async {
    final response = await http.get(Uri.parse("$baseUrl/monthly-sales"));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception("Failed to fetch monthly sales");
    }
  }

  Future<List<Map<String, dynamic>>> getTopProducts() async {
    final response = await http.get(Uri.parse("$baseUrl/top-products"));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception("Failed to fetch top products");
    }
  }

  Future<List<Map<String, dynamic>>> getCategoryBreakdown() async {
    final response = await http.get(Uri.parse("$baseUrl/category-breakdown"));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception("Failed to fetch category breakdown");
    }
  }

  Future<Map<String, dynamic>> getSummary() async {
    final response = await http.get(Uri.parse("$baseUrl/summary"));
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to fetch summary");
    }
  }
}
