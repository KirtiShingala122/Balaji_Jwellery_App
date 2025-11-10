import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductService {
  final String baseUrl = "http://localhost:3000/api/products";
  //final String baseUrl = "http://10.0.2.2:3000/api/products";
  Future<List<Product>> getLowStockProducts() async {
    final response = await http.get(Uri.parse("$baseUrl/low-stock"));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Product.fromMap(e)).toList();
    } else {
      throw Exception("Failed to load low stock products");
    }
  }

  Future<Product?> getProductById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return Product.fromMap(jsonDecode(response.body));
    }
    return null;
  }
}
