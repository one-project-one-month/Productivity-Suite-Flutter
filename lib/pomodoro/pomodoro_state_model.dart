enum PomodoroMode { work, shortBreak, longBreak }

class PomodoroState {
  final int remainingSeconds;
  final PomodoroMode mode;
  final bool isRunning;
  final int longBreakDuration;
  final int completedSessions;

  PomodoroState({
    required this.remainingSeconds,
    required this.mode,
    required this.isRunning,
    required this.longBreakDuration,
    required this.completedSessions,
  });

  PomodoroState copyWith({
    int? remainingSeconds,
    PomodoroMode? mode,
    bool? isRunning,
    int? longBreakDuration,
    int? completedSessions,
  }) {
    return PomodoroState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      mode: mode ?? this.mode,
      isRunning: isRunning ?? this.isRunning,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      completedSessions: completedSessions ?? this.completedSessions,
    );
  }
}
