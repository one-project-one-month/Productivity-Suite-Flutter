// Define the CategoryManager class for managing categories
import 'package:dio/dio.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';

import 'models/category_model.dart';

class ApiEndPoints {
  static final String category = '/categories';
  static final String transcation = '/transactions';
}

class ApiService {
  static final Dio _dio = Dio();
  static final String _token =
      "eyJhbGciOiJIUzI1NiJ9.eyJpZCI6MjEsImVtYWlsIjoibW1ra0BnbWFpbC5jb20iLCJzdWIiOiJtbWtrQGdtYWlsLmNvbSIsImlzcyI6IjFQMU0iLCJpYXQiOjE3NDkxODQyMzAsImV4cCI6MTc0OTE5NTAzMH0._GQYZwPMOzjIaSvgmKFho46-SlDx2JP5KdXgvdcwrus";
  static setUp({String? token}) {
    _dio.options.headers['Authorization'] = 'Bearer $_token';
  }

  static const String baseUrl =
      "https://productivity-suite-java.onrender.com/productivity-suite/api/v1";

  // Fetch categories from API
  static Future<Response> get(String url, [int? type]) async {
    setUp();
    try {
      return await _dio.get(baseUrl + url, queryParameters: {'type': type});
    } catch (e) {
      print("Error fetching categories: $e");
      throw Exception("Failed to fetch categories");
    }
  }

  // Add a new category via API
  static Future<CategoryModel?> post(
    Map<String, dynamic> data,
    String url,
  ) async {
    setUp();
    try {
      final response = await _dio.post(baseUrl + url, data: data);
      return CategoryModel.fromJson(response.data);
    } catch (e) {
      print("Error adding $url: $e");
      return null;
    }
  }

  // Edit a category via API
  static Future<bool> edit(
    String id,
    Map<String, dynamic> data,
    String url,
  ) async {
    setUp();
    try {
      final endPoints = "$baseUrl$url/$id";
      await _dio.put(endPoints, data: data);
      return true;
    } catch (e) {
      print("Error editing category: $e");
      return false;
    }
  }

  // Delete a category via API
  static Future<bool> delete(int id, String url) async {
    setUp();
    try {
      final endPoints = "$baseUrl$url/$id";
      await _dio.delete(endPoints);
      return true;
    } catch (e) {
      print("Error deleting category: $e");
      return false;
    }
  }
}
