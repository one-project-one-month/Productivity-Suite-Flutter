import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:productivity_suite_flutter/notes/data/note_exception.dart';
import '../note.dart';
import '../note_repository.dart';

// Provider to handle note synchronization and merging
final noteSyncProvider = Provider((ref) {
  final repository = ref.watch(noteRepositoryProvider);

  return NoteSyncService(repository);
});

class NoteSyncService {
  final NoteRepository _repository;
  final _notesBox = Hive.box<Note>('notesBox');

  NoteSyncService(this._repository);

  Future<List<Note>> getNotesByCategory(String? categoryId) async {
    // Get local notes
    final localNotes =
        _notesBox.values
            .where(
              (note) => categoryId == null || note.categoryId == categoryId,
            )
            .toList();

    try {
      // Get server notes
      final serverNotes =
          categoryId == null
              ? await _repository.getAllNotes()
              : await _repository.getNotesByCategory(categoryId);

      // Merge notes, preferring the more recently updated version
      final mergedNotes = _mergeNotes(localNotes, serverNotes);

      // Sort by update date
      mergedNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return mergedNotes;
    } on UnauthorizedException {
      // Re-throw auth errors to let the UI handle them appropriately
      rethrow;
    } catch (e) {
      // For other errors, return local notes
      print('Failed to fetch server notes: $e');
      localNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return localNotes;
    }
  }

  Future<Note?> getNoteById(String id) async {
    // Try local first
    final localNotes = _notesBox.values.where((note) => note.id == id);
    final localNote = localNotes.isNotEmpty ? localNotes.first : null;

    try {
      // Get from server
      try {
        final serverNote = await _repository.getNoteById(id);

        // If we have it locally, check which is more recent
        if (localNote != null) {
          if (serverNote.updatedAt.isAfter(localNote.updatedAt)) {
            await localNote.delete(); // Remove older version
            await _notesBox.add(serverNote);
            return serverNote;
          }
          return localNote;
        }

        // If not in local, store and return server version
        await _notesBox.add(serverNote);
        return serverNote;
      } on NotFoundException {
        // Note doesn't exist on server, return local if available
        return localNote;
      } on UnauthorizedException {
        // Re-throw auth errors to let the UI handle them
        rethrow;
      }
    } catch (e) {
      print('Failed to fetch note from server: $e');
      return localNote;
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      // Delete from server first
      await _repository.deleteNote(noteId);

      // Then delete from local if exists
      final localNotes = _notesBox.values.where((note) => note.id == noteId);
      if (localNotes.isNotEmpty) {
        await localNotes.first.delete();
      }
    } on UnauthorizedException {
      // Re-throw auth errors
      rethrow;
    } catch (e) {
      print('Error deleting note: $e');
      throw e; // Re-throw to let UI handle error
    }
  }

  List<Note> _mergeNotes(List<Note> localNotes, List<Note> serverNotes) {
    final mergedNotes = <Note>[];
    final processedIds = <String>{};

    // Process local notes
    for (final localNote in localNotes) {
      final matchingServerNotes = serverNotes.where(
        (note) => note.id == localNote.id,
      );

      if (matchingServerNotes.isEmpty) {
        // Note exists only locally
        mergedNotes.add(localNote);
      } else {
        // Note exists in both places - use the most recently updated one
        final serverNote = matchingServerNotes.first;
        mergedNotes.add(
          serverNote.updatedAt.isAfter(localNote.updatedAt)
              ? serverNote
              : localNote,
        );
      }
      processedIds.add(localNote.id);
    }

    // Add server notes that don't exist locally
    for (final serverNote in serverNotes) {
      if (!processedIds.contains(serverNote.id)) {
        mergedNotes.add(serverNote);
        // Store server note locally
        _notesBox.add(serverNote);
      }
    }

    return mergedNotes;
  }
}
