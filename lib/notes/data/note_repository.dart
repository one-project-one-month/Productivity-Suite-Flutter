import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:productivity_suite_flutter/notes/data/compress_data.dart';
import '../../auth/auth_provider.dart';
import 'note.dart';
import 'note_exception.dart';
import 'sync/sync_result.dart';

// Provider
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(
    baseUrl:
        'https://productivity-suite-java.onrender.com/productivity-suite/api/v1',
    ref: ref,
  );
});

class NoteDTO {
  final String id;
  final String title;
  final String description;
  final String type;
  final String? attachmentPath;
  final int? colorValue;
  final bool isPinned;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteDTO({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.attachmentPath,
    this.colorValue,
    required this.isPinned,
    this.categoryId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteDTO.fromJson(Map<String, dynamic> json) => NoteDTO(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    type: json['type'],
    attachmentPath: json['attachmentPath'],
    colorValue: json['colorValue'],
    isPinned: json['isPinned'],
    categoryId: json['categoryId'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  Map<String, dynamic> toMinimalJson() => {'title': title, 'body': description};

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type,
    'attachmentPath': attachmentPath,
    'colorValue': colorValue,
    'isPinned': isPinned,
    'categoryId': categoryId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  // Convert from domain Note to DTO
  factory NoteDTO.fromNote(Note note) => NoteDTO(
    id: note.id,
    title: note.title,
    description: note.description,
    type: note.type.toString().split('.').last,
    attachmentPath: note.attachmentPath,
    colorValue: note.colorValue,
    isPinned: note.isPinned,
    categoryId: note.categoryId,
    createdAt: note.createdAt,
    updatedAt: note.updatedAt,
  );

  // Convert to domain Note
  Note toNote() => Note(
    id: id,
    title: title,
    description: description,
    type: NoteType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => NoteType.text,
    ),
    attachmentPath: attachmentPath,
    colorValue: colorValue,
    isPinned: isPinned,
    categoryId: categoryId,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

// Repository
class NoteRepository {
  final String baseUrl;
  final http.Client _client;
  final Ref _ref;

  NoteRepository({required this.baseUrl, required Ref ref, http.Client? client})
    : _client = client ?? http.Client(),
      _ref = ref;

  Map<String, String> get _headers {
    final token = _ref.read(authProvider).token;
    if (token == null) {
      throw UnauthorizedException('Authentication token not found');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<T> _handleRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on SocketException catch (e) {
      throw NetworkException('No internet connection: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw ServerException('Invalid response format: ${e.message}');
    } on UnauthorizedException {
      rethrow; // Already a NoteException subclass
    } catch (e) {
      throw NoteException('Unexpected error occurred: $e');
    }
  }

  Future<dynamic> _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        try {
          return Future.value(json.decode(response.body));
        } catch (e) {
          throw ServerException('Invalid response format');
        }
      case 400:
        throw ValidationException('Invalid request', response.body);
      case 401:
        throw UnauthorizedException(response.body);
      case 404:
        throw NotFoundException(response.body);
      case 500:
        throw ServerException('Internal server error');
      default:
        throw NoteException(
          'Request failed',
          statusCode: response.statusCode,
          details: response.body,
        );
    }
  }

  Future<List<Note>> getAllNotes() async {
    return _handleRequest(() async {
      final response = await _client.get(
        Uri.parse('$baseUrl/notes'),
        headers: _headers,
      );
      final data = await _handleResponse(response) as List;
      return data.map((json) => NoteDTO.fromJson(json).toNote()).toList();
    });
  }

  Future<List<Note>> getNotesByCategory(String categoryId) async {
    return _handleRequest(() async {
      final response = await _client.get(
        //TODO: need to modify
        Uri.parse('$baseUrl/notes/category/$categoryId'),
        headers: _headers,
      );
      final data = await _handleResponse(response) as List;
      return data.map((json) => NoteDTO.fromJson(json).toNote()).toList();
    });
  }

  Future<Note> createNote(Note note) async {
    return _handleRequest(() async {
      final response = await _client.post(
        Uri.parse('$baseUrl/notes'),
        headers: _headers,
        body: json.encode(NoteDTO.fromNote(note).toJson()),
      );
      final data = await _handleResponse(response);
      return NoteDTO.fromJson(data).toNote();
    });
  }

  Future<Note> updateNote(Note note) async {
    return _handleRequest(() async {
      final response = await _client.put(
        Uri.parse('$baseUrl/notes/${note.id}'),
        headers: _headers,
        body: json.encode(NoteDTO.fromNote(note).toJson()),
      );
      final data = await _handleResponse(response);
      return NoteDTO.fromJson(data).toNote();
    });
  }

  Future<void> deleteNote(String id) async {
    return _handleRequest(() async {
      final response = await _client.delete(
        Uri.parse('$baseUrl/notes/$id'),
        headers: _headers,
      );
      await _handleResponse(response);
    });
  }

  Future<Note> getNoteById(String id) async {
    return _handleRequest(() async {
      final response = await _client.get(
        Uri.parse('$baseUrl/notes/$id'),
        headers: _headers,
      );
      final data = await _handleResponse(response);
      return NoteDTO.fromJson(data).toNote();
    });
  }

  Future<List<Note>> searchNotes(String query) async {
    return _handleRequest(() async {
      final response = await _client.get(
        Uri.parse('$baseUrl/notes/search?q=$query'),
        headers: _headers,
      );
      final data = await _handleResponse(response) as List;
      return data.map((json) => NoteDTO.fromJson(json).toNote()).toList();
    });
  }

  Future<SyncResult> bulkUploadNotes(
    List<Note> notes,
    String categoryId,
  ) async {
    return _handleRequest(() async {
      final token = _ref.read(authProvider).token;
      List<String> syncedIds = [];
      for (final note in notes) {
        final decompressedTitle = CompressString.decompressString(note.title);
        var decompressedBody = CompressString.decompressString(
          note.description,
        );
        if (decompressedBody.trim().isEmpty) {
          decompressedBody = ' ';
        }
        final response = await _client.post(
          Uri.parse(
            "https://productivity-suite-java.onrender.com/productivity-suite/api/v1/notes",
          ),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'title': decompressedTitle,
            'body': decompressedBody,
          }),
        );
        final data = await _handleResponse(response);
        if (data is List) {
          for (final item in data) {
            if (item is Map && item['id'] != null) {
              syncedIds.add(item['id'].toString());
            }
          }
        } else if (data is Map && data['id'] != null) {
          syncedIds.add(data['id'].toString());
        }
      }
      return SyncResult(success: true, syncedNoteIds: syncedIds);
    });
  }
}
