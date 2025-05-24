import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:productivity_suite_flutter/notes/data/note.dart';
import 'package:productivity_suite_flutter/notes/data/note_repository.dart';
import 'package:productivity_suite_flutter/notes/widgets/error_dialog.dart';

enum SyncStatus { notSynced, syncing, synced, error }

class SyncResult {
  final bool success;
  final List<String> syncedNoteIds;
  final String? error;

  SyncResult({
    required this.success,
    this.syncedNoteIds = const [],
    this.error,
  });
}

// Providers to manage sync state
final syncStatusProvider = StateProvider<SyncStatus>(
  (ref) => SyncStatus.notSynced,
);

final syncErrorProvider = StateProvider<String?>((ref) => null);

// Provider for sync functionality
final syncNotesProvider =
    Provider<Future<SyncResult> Function(String, BuildContext)>((ref) {
      return (categoryId, context) async {
        try {
          // Update sync status
          ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
          ref.read(syncErrorProvider.notifier).state = null;

          // Get the repository instance
          final repository = ref.read(noteRepositoryProvider);

          // Get notes from Hive for the category
          final notesBox = await Hive.openBox<Note>('notesBox');
          final notes =
              notesBox.values.where((n) => n.categoryId == categoryId).toList();

          // Upload to server
          await repository.bulkUploadNotes(notes, categoryId);

          // Delete synced notes from local storage
          await Future.wait(notes.map((note) => note.delete()));

          // Update sync status
          ref.read(syncStatusProvider.notifier).state = SyncStatus.synced;

          return SyncResult(
            success: true,
            syncedNoteIds: notes.map((n) => n.id).toList(),
          );
        } catch (e) {
          ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
          ref.read(syncErrorProvider.notifier).state = e.toString();
          if (context.mounted) {
            showErrorDialog(context, e.toString());
          }
          return SyncResult(
            success: false,
            syncedNoteIds: [],
            error: e.toString(),
          );
        }
      };
    });
