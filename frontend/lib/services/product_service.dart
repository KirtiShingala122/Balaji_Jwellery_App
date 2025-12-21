//product_service.dart
import 'dart:convert';
import 'dart:typed_data'; // For web uploads
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:io' show File, Platform; // Safe import for mobile
import '../config/api_config.dart';
import '../models/product.dart';

class ProductService {
  late final String baseUrl;

  ProductService() {
    baseUrl = Api.api('/api/products');
  }

  ///  Get all products
  Future<List<Product>> getAllProducts() async {
    try {
      final res = await http.get(Uri.parse(baseUrl));

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => Product.fromMap(e)).toList();
      } else {
        throw Exception("Failed to load products (${res.statusCode})");
      }
    } catch (e) {
      throw Exception("Error fetching products: $e");
    }
  }

  ///  Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/low-stock"));

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => Product.fromMap(e)).toList();
      } else {
        throw Exception("Failed to load low stock products");
      }
    } catch (e) {
      throw Exception("Error fetching low stock products: $e");
    }
  }

  /// Get product by ID
  Future<Product?> getProductById(int id) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/$id"));
      if (res.statusCode == 200) {
        return Product.fromMap(jsonDecode(res.body));
      } else if (res.statusCode == 404) {
        return null;
      } else {
        throw Exception("Failed to get product (status ${res.statusCode})");
      }
    } catch (e) {
      throw Exception("Error fetching product: $e");
    }
  }

  /// Add product (mobile + web)
  Future<void> addProduct(
    Product product, {
    File? imageFile,
    Uint8List? webImage,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));

      //  Send only backend-required fields
      request.fields.addAll({
        'uniqueCode': product.uniqueCode,
        'name': product.name,
        'description': product.description,
        'categoryId': product.categoryId.toString(),
        'price': product.price.toString(),
        'stockQuantity': product.stockQuantity.toString(),
      });

      //  Add image if provided
      if (!kIsWeb && imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      } else if (kIsWeb && webImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            webImage,
            filename: 'upload.jpg',
          ),
        );
      }

      var response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode != 201) {
        throw Exception(
          "Failed to add product (${response.statusCode}): $respStr",
        );
      }
    } catch (e) {
      throw Exception("Error adding product: $e");
    }
  }

  /// Update product (mobile + web)
  Future<void> updateProduct(
    Product product, {
    File? imageFile,
    Uint8List? webImage,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse("$baseUrl/${product.id}"),
      );

      // ✅ Send only backend-required fields
      request.fields.addAll({
        'uniqueCode': product.uniqueCode,
        'name': product.name,
        'description': product.description,
        'categoryId': product.categoryId.toString(),
        'price': product.price.toString(),
        'stockQuantity': product.stockQuantity.toString(),
      });

      // ✅ Add image if available
      if (!kIsWeb && imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      } else if (kIsWeb && webImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            webImage,
            filename: 'update.jpg',
          ),
        );
      }

      var response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to update product (${response.statusCode}): $respStr",
        );
      }
    } catch (e) {
      throw Exception("Error updating product: $e");
    }
  }

  ///  Delete product
  Future<void> deleteProduct(int id) async {
    try {
      final res = await http.delete(Uri.parse("$baseUrl/$id"));
      if (res.statusCode != 200) {
        String msg;
        try {
          final body = jsonDecode(res.body);
          msg = body['error'] ?? body['message'] ?? res.body;
        } catch (_) {
          msg = res.body.isNotEmpty ? res.body : 'Status ${res.statusCode}';
        }
        throw Exception('API_ERROR:${res.statusCode}:$msg');
      }
    } catch (e) {
      // Preserve API error format if already present
      final s = e.toString();
      if (s.contains('API_ERROR:')) {
        throw Exception(s.replaceFirst('Exception: ', ''));
      }
      throw Exception("Error deleting product: $e");
    }
  }

  /// Get product by unique code
  Future<Product?> getProductByCode(String code) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/code/$code"));

      if (res.statusCode == 200) {
        return Product.fromMap(jsonDecode(res.body));
      } else if (res.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch product (${res.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching product by code: $e');
    }
  }
}
