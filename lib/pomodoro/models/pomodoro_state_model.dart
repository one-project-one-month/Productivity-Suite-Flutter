enum PomodoroMode { work, shortBreak, longBreak }

enum PomodoroConnectionState { disconnected, connecting, connected, error }

enum PomodoroTimerState { idle, running, paused, completed }

class PomodoroState {
  final int remainingTime;
  final PomodoroMode mode;
  final bool isRunning;
  final int longBreakDuration;
  final int shortBreakDuration;
  final int focusDuration;
  final int completedSessions;
  final int completedWorkSessions;
  final PomodoroConnectionState connectionState;
  final PomodoroTimerState timerState;
  final Map<String, dynamic>? currentResponse;
  final String? errorMessage;
  final int? currentTimerId;
  final int? currentSequenceId;
  final bool isNewPomodoro;
  final int selectedTaskTypeIndex;

  const PomodoroState({
    required this.remainingTime,
    required this.mode,
    required this.isRunning,
    required this.longBreakDuration,
    required this.shortBreakDuration,
    required this.focusDuration,
    required this.completedSessions,
    required this.completedWorkSessions,
    required this.connectionState,
    required this.timerState,
    this.currentResponse,
    this.errorMessage,
    this.currentTimerId,
    this.currentSequenceId,
    this.isNewPomodoro = false,
    this.selectedTaskTypeIndex = 0,
  });

  bool get isConnected => connectionState == PomodoroConnectionState.connected;

  PomodoroState copyWith({
    int? remainingTime,
    PomodoroMode? mode,
    bool? isRunning,
    int? longBreakDuration,
    int? shortBreakDuration,
    int? focusDuration,
    int? completedSessions,
    int? completedWorkSessions,
    PomodoroConnectionState? connectionState,
    PomodoroTimerState? timerState,
    Map<String, dynamic>? currentResponse,
    String? errorMessage,
    int? currentTimerId,
    int? currentSequenceId,
    bool? isNewPomodoro,
    int? selectedTaskTypeIndex,
  }) {
    return PomodoroState(
      remainingTime: remainingTime ?? this.remainingTime,
      mode: mode ?? this.mode,
      isRunning: isRunning ?? this.isRunning,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      focusDuration: focusDuration ?? this.focusDuration,
      completedSessions: completedSessions ?? this.completedSessions,
      completedWorkSessions:
          completedWorkSessions ?? this.completedWorkSessions,
      connectionState: connectionState ?? this.connectionState,
      timerState: timerState ?? this.timerState,
      currentResponse: currentResponse ?? this.currentResponse,
      errorMessage: errorMessage,
      currentTimerId: currentTimerId ?? this.currentTimerId,
      currentSequenceId: currentSequenceId ?? this.currentSequenceId,
      isNewPomodoro: isNewPomodoro ?? this.isNewPomodoro,
      selectedTaskTypeIndex:
          selectedTaskTypeIndex ?? this.selectedTaskTypeIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PomodoroState &&
        other.remainingTime == remainingTime &&
        other.mode == mode &&
        other.isRunning == isRunning &&
        other.longBreakDuration == longBreakDuration &&
        other.completedSessions == completedSessions &&
        other.completedWorkSessions == completedWorkSessions &&
        other.connectionState == connectionState &&
        other.timerState == timerState &&
        other.currentTimerId == currentTimerId &&
        other.currentSequenceId == currentSequenceId &&
        other.isNewPomodoro == isNewPomodoro &&
        other.selectedTaskTypeIndex == selectedTaskTypeIndex &&
        other.focusDuration == focusDuration &&
        other.shortBreakDuration == shortBreakDuration;
  }

  @override
  int get hashCode {
    return Object.hash(
      remainingTime,
      mode,
      isRunning,
      longBreakDuration,
      focusDuration,
      shortBreakDuration,
      completedSessions,
      completedWorkSessions,
      connectionState,
      timerState,
      currentTimerId,
      currentSequenceId,
      isNewPomodoro,
      selectedTaskTypeIndex,
    );
  }
}
