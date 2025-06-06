import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../note.dart';
import '../../repository/note_repository.dart';
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



// Sync state notifier per category
// sync_provider.dart

// final syncStateProvider = StateNotifierProvider.family<SyncNotifier, SyncState, String>(
//   (ref, categoryId) => SyncNotifier(ref, categoryId),
// );

// class SyncNotifier extends StateNotifier<SyncState> {
//   final Ref ref;
//   final String categoryId;

//   SyncNotifier(this.ref, this.categoryId) : super(const SyncState());

//   Future<void> syncNotes() async {
//     if (state.status == SyncStatus.syncing) return;
    
//     state = state.copyWith(status: SyncStatus.syncing, error: null);
    
//     try {
//       // Sync implementation
//       state = state.copyWith(status: SyncStatus.synced);
//     } catch (e) {
//       state = state.copyWith(
//         status: SyncStatus.error,
//         error: e.toString(),
//       );
//     }
//   }
// }