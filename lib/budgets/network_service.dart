// Define the CategoryManager class for managing categories
import 'package:dio/dio.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/category_model.dart';

class ApiEndPoints {
  static final String category = '/categories';
  static final String transcation = '/transactions';
}

class ApiService {
  static final Dio _dio = Dio();
  static const String _tokenKey = 'auth_token';

  static Future<void> setUp({String? token}) async {
    String? authToken = token;

    // If no token provided, try to get from SharedPreferences
    if (authToken == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        authToken = prefs.getString(_tokenKey);
      } catch (e) {
        print("Error getting stored token: $e");
      }
    }

    if (authToken != null) {
      _dio.options.headers['Authorization'] = 'Bearer $authToken';
    }
  }

  static const String baseUrl =
      "https://productivity-suite-java.onrender.com/productivity-suite/api/v1";

  // Fetch categories from API
  static Future<Response> get(String url, [int? type]) async {
    await setUp();
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
    await setUp();
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
    await setUp();
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
    await setUp();
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