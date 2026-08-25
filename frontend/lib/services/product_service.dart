import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductService {
  final String baseUrl = "http://localhost:3000/api/products";
  //final String baseUrl = "http://10.0.2.2:3000/api/products";

  // Get all products (with category name)
  Future<List<Product>> getAllProducts() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Product.fromMap(e)).toList();
    } else {
      throw Exception("Failed to load products");
    }
  }

  // Get low-stock products
  Future<List<Product>> getLowStockProducts() async {
    final response = await http.get(Uri.parse("$baseUrl/low-stock"));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Product.fromMap(e)).toList();
    } else {
      throw Exception("Failed to load low stock products");
    }
  }

  // Get product by ID
  Future<Product?> getProductById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return Product.fromMap(jsonDecode(response.body));
    }
    return null;
  }

  // Add new product
  Future<bool> addProduct({
    required String uniqueCode,
    required String name,
    required String description,
    required int categoryId,
    required double price,
    required int stockQuantity,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'uniqueCode': uniqueCode,
        'name': name,
        'description': description,
        'categoryId': categoryId,
        'price': price,
        'stockQuantity': stockQuantity,
      }),
    );
    return response.statusCode == 201;
  }

  // Update existing product
  Future<bool> updateProduct({
    required int id,
    required String name,
    required String description,
    required int categoryId,
    required double price,
    required int stockQuantity,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'description': description,
        'categoryId': categoryId,
        'price': price,
        'stockQuantity': stockQuantity,
      }),
    );
    return response.statusCode == 200;
  }

  // Delete product
  Future<bool> deleteProduct(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    return response.statusCode == 200;
  }
}
