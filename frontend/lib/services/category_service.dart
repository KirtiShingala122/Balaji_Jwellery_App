import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io'
    show Platform; // safe to import; not used in web branch at runtime

import '../models/category.dart';

class CategoryService {
  late final String baseUrl;
  final Dio dio = Dio();

  CategoryService() {
    if (kIsWeb) {
      baseUrl = "http://localhost:3000/api/categories";
    } else if (Platform.isAndroid) {
      baseUrl = "http://10.0.2.2:3000/api/categories";
    } else {
      baseUrl = "http://localhost:3000/api/categories";
    }
  }

  Future<List<Category>> getAllCategories() async {
    final res = await dio.get(baseUrl);
    final data = res.data as List<dynamic>;
    return data.map((e) => Category.fromMap(e)).toList();
  }

  Future<Category?> getCategoryById(int id) async {
    final res = await dio.get("$baseUrl/$id");
    if (res.statusCode == 200) {
      return Category.fromMap(res.data);
    }
    return null;
  }

  Future<void> addCategory(Category category, Uint8List? imageBytes) async {
    final form = FormData.fromMap({
      'name': category.name,
      'description': category.description,
      if (imageBytes != null)
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: 'category_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
    });

    final res = await dio.post(baseUrl, data: form);
    if (res.statusCode != 201) {
      throw Exception('Failed to add category: ${res.statusCode}');
    }
  }

  Future<void> updateCategory(Category category, Uint8List? imageBytes) async {
    final form = FormData.fromMap({
      'name': category.name,
      'description': category.description,
      if (imageBytes != null)
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: 'category_update.jpg',
        )
      else if (category.imagePath != null)
        'imagePath': category.imagePath,
    });

    final res = await dio.put("$baseUrl/${category.id}", data: form);
    if (res.statusCode != 200) {
      throw Exception('Failed to update category: ${res.statusCode}');
    }
  }

  Future<void> deleteCategory(int id) async {
    final res = await dio.delete("$baseUrl/$id");
    if (res.statusCode != 200) {
      throw Exception('Failed to delete category: ${res.statusCode}');
    }
  }
}
