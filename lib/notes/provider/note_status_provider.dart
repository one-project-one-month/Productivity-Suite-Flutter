import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sync_status.dart';

final syncStatusProvider = StateProvider<SyncStatus>(
  (ref) => SyncStatus.notSynced,
);
final syncErrorProvider = StateProvider<String?>((ref) => null);

final syncNotesProvider =
    Provider<Future<SyncResult> Function(String, BuildContext)>((ref) {
      return (categoryId, context) async {
        final notifier = ref.read(syncStatusProvider.notifier);
        final errorNotifier = ref.read(syncErrorProvider.notifier);

        try {
          notifier.state = SyncStatus.syncing;
          errorNotifier.state = null;

          
          await Future.delayed(const Duration(seconds: 2)); // Simulated delay

          final result = SyncResult(
            success: true,
            syncedNoteIds: [], // Add synced note IDs here
            error: null,
          );

          notifier.state = SyncStatus.synced;
          return result;
        } catch (e) {
          notifier.state = SyncStatus.error;
          errorNotifier.state = e.toString();
          return SyncResult(
            success: false,
            syncedNoteIds: [],
            error: e.toString(),
          );
        }
      };
    });
