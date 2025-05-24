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
