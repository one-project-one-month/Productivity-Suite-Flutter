import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:productivity_suite_flutter/auth/auth_provider.dart';

import 'package:productivity_suite_flutter/notes/data/compress_data.dart';
import 'package:productivity_suite_flutter/notes/models/note_model.dart';

import '../data/note.dart';
import '../data/note_exception.dart';
import '../data/sync/sync_result.dart';

// Provider
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(
    baseUrl:
        'https://productivity-suite-java.onrender.com/productivity-suite/api/v1',
    ref: ref,
  );
});

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

  // Future<List<Note>> getAllNotes() async {
  //   return _handleRequest(() async {
  //     final response = await _client.get(
  //       Uri.parse('$baseUrl/notes'),
  //       headers: _headers,
  //     );
  //     final data = await _handleResponse(response) as List;
  //     return data.map((json) => NoteDTO.fromJson(json).toNote()).toList();
  //   });
  // }

  //*TO GET NOTE BY CATEGORY
  Future<List<Note>> getNotesByCategory(String categoryId) async {
    return _handleRequest(() async {
      final response = await _client.get(
        Uri.parse('$baseUrl/notes/by-category?categoryId=$categoryId'),
        headers: _headers,
      );

      final data = await _handleResponse(response);
      final notesData = data['data'];

      if (notesData != null && notesData['notes'] is List) {
        final catId = notesData['categoryId'].toString();

        final notesJson = notesData['notes'] as List;

        return notesJson
            .map((json) => NoteDTO.fromJson(json, categoryId: catId).toNote())
            .toList();
      } else {
        return [];
      }
    });
  }

  //!UPGrade NOTE
  Future<Note> updateNote(Note note) async {
    return _handleRequest(() async {
      final decompressedTitle = CompressString.decompressString(note.title);
      var decompressedBody = CompressString.decompressString(note.description);
      if (decompressedBody.trim().isEmpty) {
        decompressedBody = '-';
      }

      // Convert colorValue to hex string with #
      final hexColor =
          note.colorValue != null
              ? '#${note.colorValue!.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'
              : '#FFFFFF';

      final response = await _client.put(
        Uri.parse('$baseUrl/notes/${note.id}'),
        headers: _headers,
        body: json.encode({
          'id': int.parse(note.id),
          'title': decompressedTitle,
          'body': decompressedBody,
          'color': hexColor,
          'categoryId': int.parse(note.categoryId!),
          'pinned': note.isPinned,
          'createdAt': note.createdAt.millisecondsSinceEpoch,
          'updatedAt': note.updatedAt.millisecondsSinceEpoch,
        }),
      );

      final data = await _handleResponse(response);
      return NoteDTO.fromJson(data).toNote();
    });
  }

  //? NEED TO CHECK AGAIN
  Future<void> deleteNote(String id) async {
    return _handleRequest(() async {
      final response = await _client.delete(
        Uri.parse('$baseUrl/notes/$id'),
        headers: _headers,
      );
      await _handleResponse(response);
    });
  }

  //TODO: MODIFY FROM LOCAL
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

  //Upload cloud server
  Future<SyncResult> bulkUploadNotes(
    List<Note> notes,
    String categoryId,
  ) async {
    return _handleRequest(() async {
      // Prepare the note list
      final noteList =
          notes.map((note) {
            final decompressedTitle = CompressString.decompressString(
              note.title,
            );
            var decompressedBody = CompressString.decompressString(
              note.description,
            );
            if (decompressedBody.trim().isEmpty) {
              decompressedBody = ' ';
            }

            return {
              'title': decompressedTitle,
              'body': decompressedBody,
              'categoryId': int.tryParse(categoryId) ?? 0,
              'color':
                  '#${note.color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
            };
          }).toList();

      final response = await _client.post(
        Uri.parse('$baseUrl/notes/flutter'),
        headers: _headers,
        body: json.encode(noteList),
      );
      print(response.body);

      final data = await _handleResponse(response);

      // Extract synced note IDs
      List<String> syncedIds = [];
      if (data is List) {
        for (final item in data) {
          if (item is Map && item['id'] != null) {
            syncedIds.add(item['id'].toString());
          }
        }
      } else if (data is Map && data['id'] != null) {
        syncedIds.add(data['id'].toString());
      }

      return SyncResult(success: true, syncedNoteIds: syncedIds);
    });
  }
}
