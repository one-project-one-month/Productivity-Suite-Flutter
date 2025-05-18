enum PomodoroMode { work, shortBreak, longBreak }

class PomodoroState {
  final int remainingSeconds;
  final PomodoroMode mode;
  final bool isRunning;
  final int longBreakDuration;
  final int completedSessions; // Total long Pomodoro sessions
  final int completedWorkSessions; // Tracks 1 to 4 before long break

  PomodoroState({
    required this.remainingSeconds,
    required this.mode,
    required this.isRunning,
    required this.longBreakDuration,
    required this.completedSessions,
    required this.completedWorkSessions,
  });

  PomodoroState copyWith({
    int? remainingSeconds,
    PomodoroMode? mode,
    bool? isRunning,
    int? longBreakDuration,
    int? completedSessions,
    int? completedWorkSessions,
  }) {
    return PomodoroState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      mode: mode ?? this.mode,
      isRunning: isRunning ?? this.isRunning,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      completedSessions: completedSessions ?? this.completedSessions,
      completedWorkSessions:
          completedWorkSessions ?? this.completedWorkSessions,
    );
  }
}
