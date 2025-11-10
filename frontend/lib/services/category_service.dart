import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';

class CategoryService {
  final String baseUrl = "http://localhost:3000/api/categories"; // backend URL
  //final String baseUrl = "http://10.0.2.2:3000/api/Categories";
  Future<List<Category>> getAllCategories() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Category.fromMap(e)).toList();
    } else {
      throw Exception("Failed to load categories");
    }
  }

  Future<Category?> getCategoryById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Category.fromMap(data);
    } else if (response.statusCode == 404) {
      return null; // category not found
    } else {
      throw Exception("Failed to fetch category details");
    }
  }

  Future<void> addCategory(Category category) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(category.toMap()),
    );
    if (response.statusCode != 201) {
      throw Exception("Failed to add category");
    }
  }

  Future<void> updateCategory(Category category) async {
    final response = await http.put(
      Uri.parse("$baseUrl/${category.id}"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(category.toMap()),
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to update category");
    }
  }

  Future<void> deleteCategory(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (response.statusCode != 200) {
      throw Exception("Failed to delete category");
    }
  }
}
