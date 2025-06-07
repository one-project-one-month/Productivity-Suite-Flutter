
// sync_state.dart
import 'package:flutter/foundation.dart';

@immutable
class SyncState {
  final SyncStatus status;
  final String? error;

  const SyncState({
    this.status = SyncStatus.notSynced,
    this.error,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? error,
  }) {
    return SyncState(
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncState &&
        other.status == status &&
        other.error == error;
  }

  @override
  int get hashCode => status.hashCode ^ error.hashCode;

  @override
  String toString() => 'SyncState(status: $status, error: $error)';

  // For persistence/diagnostics
  Map<String, dynamic> toJson() => {
        'status': status.index,
        'error': error,
      };

  factory SyncState.fromJson(Map<String, dynamic> json) => SyncState(
        status: SyncStatus.values[json['status'] as int],
        error: json['error'] as String?,
      );
}

enum SyncStatus {
  notSynced,
  syncing,
  synced,
  error,
}