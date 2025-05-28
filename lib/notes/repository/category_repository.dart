// category_repository.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:productivity_suite_flutter/auth/auth_provider.dart';

import 'package:productivity_suite_flutter/notes/data/note.dart';
import 'package:productivity_suite_flutter/notes/data/note_exception.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    baseUrl:
        'https://productivity-suite-java.onrender.com/productivity-suite/api/v1',
    ref: ref,
  );
});

class CategoryRepository {
  final String baseUrl;
  final http.Client _client;
  final Ref _ref;

  CategoryRepository({
    required this.baseUrl,
    required Ref ref,
    http.Client? client,
  }) : _client = client ?? http.Client(),
       _ref = ref;

  Map<String, String> get _headers {
    final token =
        _ref.read(authProvider).token;
    if (token == null)
      throw UnauthorizedException('Authentication token not found');
    return {
      'Content-Type': 'application/json',
      ''
              'Authorization':
          'Bearer $token',
    };
  }

  Future<List<Category>> getAllCategories() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/categories'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final data = decoded['data'] as List;

      return data.map((json) => _categoryFromJson(json)).toList();
    }

    throw _handleError(response);
  }

  Future<Category> createCategory(Category category) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/categories'),
      headers: _headers,
      body: json.encode(_categoryToJson(category)),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonBody = json.decode(response.body);
      final isSuccess = jsonBody['success'] == 1 && jsonBody['data'] == true;
      if (isSuccess) {
        return category;
      }
    }
    throw _handleError(response);
  }

  Future<Category> updateCategory(Category category) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/categories/${category.id}'),
      headers: _headers,
      body: json.encode(_categoryToJson(category)),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      final isSuccess = jsonBody['success'] == 1 && jsonBody['data'] == true;
      if (isSuccess) {
        return category;
      }
    }
    throw _handleError(response);
  }

  Future<void> deleteCategory(String id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw _handleError(response);
    }
  }

  Category _categoryFromJson(Map<String, dynamic> json) {
    String desc = json['description'].toString();

    
    desc = desc.startsWith('#') ? desc.substring(1) : desc;

    return Category(
      id: json['id'].toString(),
      name: json['name'].toString(),
      colorValue: int.tryParse(desc) ?? 0xFF2196F3,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
    );
  }

  Map<String, dynamic> _categoryToJson(Category category) {
    return {
      'name': category.name,
      'description': '#${category.colorValue}',
      'type': 4,
    };
  }

  Never _handleError(http.Response response) {
    switch (response.statusCode) {
      case 400:
        throw ValidationException('Invalid request', response.body);
      case 401:
        throw UnauthorizedException(response.body);
      case 404:
        throw NotFoundException(response.body);
      case 500:
        throw ServerException('Internal server error');
      default:
        throw NoteException('Request failed: ${response.statusCode}');
    }
  }
}
