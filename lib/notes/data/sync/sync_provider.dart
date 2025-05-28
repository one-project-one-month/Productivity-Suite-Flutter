import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../note.dart';
import '../note_repository.dart';
import 'sync_result.dart';
import 'sync_status.dart';
import '../../widgets/error_dialog.dart';

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

          // Get notes by category
          final repository = ref.read(noteRepositoryProvider);
          final notesBox = await Hive.openBox<Note>('notesBox');
          final notes =
              notesBox.values.where((n) => n.categoryId == categoryId).toList();

          // Upload to server
          final result = await repository.bulkUploadNotes(notes, categoryId);

          if (result.success) {
            // Delete synced notes from local storage
            await Future.wait(notes.map((note) => note.delete()));
            ref.read(syncStatusProvider.notifier).state = SyncStatus.synced;
          }

          return result;
        } catch (e) {
          ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
          ref.read(syncErrorProvider.notifier).state = e.toString();
          if (context.mounted) {
            showErrorDialog(context, e.toString());
  
          }
          return SyncResult(success: false, error: e.toString());
        }
      };
    });
