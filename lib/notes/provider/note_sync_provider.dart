import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:productivity_suite_flutter/notes/data/note_exception.dart';
import '../data/note.dart';
import '../repository/note_repository.dart';
import 'package:collection/collection.dart';

// // Provider to handle note synchronization and merging
final noteSyncProvider = Provider((ref) {
  final repository = ref.watch(noteRepositoryProvider);

  return NoteSyncService(repository);
});

// class NoteSyncService {
//   final NoteRepository _repository;
//   final _notesBox = Hive.box<Note>('notesBox');

//   NoteSyncService(this._repository);

//   Future<List<Note>> getNotesByCategory(String? categoryId) async {
//     // Get local notes
//     final localNotes =
//         _notesBox.values
//             .where(
//               (note) => categoryId == null || note.categoryId == categoryId,
//             )
//             .toList();

//     try {
//       // Get server notes
//       final serverNotes = await _repository.getNotesByCategory(
//         categoryId ?? '',
//       );

//       // Merge notes, preferring the more recently updated version
//       final mergedNotes = _mergeNotes(localNotes, serverNotes);

//       // Sort by update date
//       mergedNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

//       return mergedNotes;
//     } on UnauthorizedException {
//       rethrow;
//     } catch (e) {
//       // For other errors, return local notes
//       print('Failed to fetch server notes: $e');
//       localNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
//       return localNotes;
//     }
//   }

// Future<Note?> getNoteById(String id) async {
//   final localNote = _notesBox.values.firstWhereOrNull((note) => note.id == id);

//   try {
//     final serverNote = await _repository.getNoteById(id);

//     if (localNote != null) {
//       if (serverNote.updatedAt.isAfter(localNote.updatedAt)) {
//         await localNote.delete();

//         // ✅ Make sure it's a new instance before storing
//         final newNote = serverNote.copyWith(); 
//         await _notesBox.put(newNote.id, newNote);
//         return newNote;
//       }
//       return localNote;
//     }

//     // ✅ Avoid inserting the same instance again
//     final newNote = serverNote.copyWith(); 
//     await _notesBox.put(newNote.id, newNote);
//     return newNote;
//   } on NotFoundException {
//     return localNote;
//   } on UnauthorizedException {
//     rethrow;
//   } catch (e) {
//     print('Failed to fetch note from server: $e');
//     return localNote;
//   }
// }



//   Future<void> deleteNote(String noteId) async {
//     try {
//       // Delete from server first
//       await _repository.deleteNote(noteId);

//       // Then delete from local if exists
//       final localNotes = _notesBox.values.where((note) => note.id == noteId);
//       if (localNotes.isNotEmpty) {
//         await localNotes.first.delete();
//       }
//     } on UnauthorizedException {
//       // Re-throw auth errors
//       rethrow;
//     } catch (e) {
//       print('Error deleting note: $e');
//       throw e; // Re-throw to let UI handle error
//     }
//   }

//   List<Note> _mergeNotes(List<Note> localNotes, List<Note> serverNotes) {
//     final mergedNotes = <Note>[];
//     final processedIds = <String>{};

//     // Process local notes
//     for (final localNote in localNotes) {
//       final matchingServerNotes = serverNotes.where(
//         (note) => note.id == localNote.id,
//       );

//       if (matchingServerNotes.isEmpty) {
//         // Note exists only locally
//         mergedNotes.add(localNote);
//       } else {
//         // Note exists in both places - use the most recently updated one
//         final serverNote = matchingServerNotes.first;
//         mergedNotes.add(
//           serverNote.updatedAt.isAfter(localNote.updatedAt)
//               ? serverNote
//               : localNote,
//         );
//       }
//       processedIds.add(localNote.id);
//     }

//     // Add server notes that don't exist locally
//     for (final serverNote in serverNotes) {
//       if (!processedIds.contains(serverNote.id)) {
//         mergedNotes.add(serverNote);
//         // Store server note locally
//         _notesBox.add(serverNote);
//       }
//     }

//     return mergedNotes;
//   }

//   Future<void> updateNote(Note updatedNote) async {
//     Note? localNote;
//     try {
//       localNote = _notesBox.values.cast<Note>().firstWhere(
//         (note) =>
//             note.id == updatedNote.id &&
//             note.categoryId == updatedNote.categoryId,
//       );
//     } catch (_) {
//       localNote = null;
//     }

//     if (localNote != null) {
//       // Update the existing local note
//       localNote
//         ..title = updatedNote.title
//         ..description = updatedNote.description
//         ..colorValue = updatedNote.colorValue
//         ..isPinned = updatedNote.isPinned
//         ..updatedAt = updatedNote.updatedAt;
//       await localNote.save();
//     } else {
//       // No matching note found locally (by id and category), so add new one
//       await _notesBox.add(updatedNote);
//     }

//     // Try updating on server
//     try {
//       await _repository.updateNote(updatedNote);
//     } on UnauthorizedException {
//       rethrow;
//     } catch (e) {
//       print('Failed to update note on server: $e');
//     }
//   }
// }
class NoteSyncService {
  final NoteRepository _repository;

  NoteSyncService(this._repository);

  Future<List<Note>> getNotesByCategory(String? categoryId) async {
    try {
      final serverNotes = await _repository.getNotesByCategory(categoryId ?? '');
      //serverNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return serverNotes;
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      print('Failed to fetch server notes: $e');
      // Return empty list or throw, since no local notes now
      return [];
    }
  }

  // Fetch note from server only
  Future<Note?> getNoteById(String id) async {
    try {
      final serverNote = await _repository.getNoteById(id);
      return serverNote;
    } on NotFoundException {
      return null;
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      print('Failed to fetch note from server: $e');
      return null;
    }
  }

  // Update note on server only, no local update
  Future<void> updateNote(Note updatedNote) async {
    try {
      await _repository.updateNote(updatedNote);
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      print('Failed to update note on server: $e');
    }
  }

  // Delete note on server only
  Future<void> deleteNote(String noteId) async {
    try {
      await _repository.deleteNote(noteId);
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      print('Error deleting note: $e');
      throw e;
    }
  }
}
