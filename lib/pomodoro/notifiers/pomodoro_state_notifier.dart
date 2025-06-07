import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:productivity_suite_flutter/pomodoro/models/state_class.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pomodoro_state_model.dart';
import '../utils/shared_prefs_provider.dart';
import '../wss/pomodoro_web_socket_service.dart';

class PomodoroNotifier extends Notifier<PomodoroState> {
  late PomodoroWebSocketServer _server;
  late SharedPreferences _prefs;

  Timer? _localTimer;

  StreamSubscription? _connectionSubscription;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _errorSubscription;

  @override
  PomodoroState build() {
    _prefs = ref.read(sharedPrefsProvider);
    _server = ref.read(pomodoroWebSocketServerProvider);

    final initialState = _loadInitialState(_prefs);
    _initializeStreams();
    return initialState;
  }

  static PomodoroState _loadInitialState(SharedPreferences prefs) {
    final savedLongBreak = prefs.getInt('longBreakDuration') ?? 1500;
    final savedFocus = prefs.getInt('focusDuration') ?? 2700;
    final savedShortBreak = prefs.getInt('shortBreakDuration') ?? 300;
    final completedSessions = prefs.getInt('completedSessions') ?? 0;
    final completedWorkSessions = prefs.getInt('completedWorkSessions') ?? 0;
    final savedModeIndex = prefs.getInt('lastSelectedMode') ?? 0;
    final savedMode = PomodoroMode.values[savedModeIndex];
    final selectedOptionIndex = prefs.getInt('selectedOptionIndex') ?? 0;

    return PomodoroState(
      remainingTime: _getDurationForMode(
        savedMode,
        focusDuration: savedFocus, // Use loaded value
        shortBreakDuration: savedShortBreak, // Use loaded value
        longBreakDuration: savedLongBreak,
      ),

      mode: savedMode,
      isRunning: false,
      longBreakDuration: savedLongBreak,
      shortBreakDuration: savedShortBreak,
      focusDuration: savedFocus,
      completedSessions: completedSessions,
      completedWorkSessions: completedWorkSessions,
      connectionState: PomodoroConnectionState.disconnected,
      timerState: PomodoroTimerState.idle,
      currentResponse: null,
      errorMessage: null,
      selectedTaskTypeIndex: selectedOptionIndex,
    );
  }

  /*static int _getDurationForMode(PomodoroMode mode, {int? longBreak}) {
    switch (mode) {
      case PomodoroMode.work:
        return 10; // 25 mins
      case PomodoroMode.shortBreak:
        return 3; // 5 mins
      case PomodoroMode.longBreak:
        return longBreak ?? 1500;
    }
  }*/
  static int _getDurationForMode(
    PomodoroMode mode, {
    required int focusDuration,
    required int shortBreakDuration,
    required int longBreakDuration,
  }) {
    switch (mode) {
      case PomodoroMode.work:
        return focusDuration;
      case PomodoroMode.shortBreak:
        return shortBreakDuration;
      case PomodoroMode.longBreak:
        return longBreakDuration ?? 1500;
    }
  }

  void _initializeStreams() {
    _connectionSubscription = _server.connectionStream.listen((connected) {
      state = state.copyWith(
        connectionState:
            connected
                ? PomodoroConnectionState.connected
                : PomodoroConnectionState.disconnected,
        errorMessage: null,
      );
    });

    _messageSubscription = _server.messageStream.listen((response) {
      _handleIncomingMessage(response);
    });

    _errorSubscription = _server.errorStream.listen((error) {
      state = state.copyWith(
        connectionState: PomodoroConnectionState.error,
        errorMessage: error,
      );
    });
  }

  // In PomodoroNotifier

  void _handleIncomingMessage(Map<String, dynamic> response) {
    if (response['success'] == 1 && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      final remainingTimeValue = data['remainingTime'];

      // Handle "Time is already running" error
      if (remainingTimeValue == "Time is already running") {
        state = state.copyWith(
          errorMessage: 'A timer is already running. Please stop it first.',
          timerState: PomodoroTimerState.idle, // Don't change to running
          isRunning: false, // Don't set as running
        );
        return;
      }
      // --- Normal response handling ---
      final timerStateFromResponse = _mapTimerStateFromResponse(
        data,
      ); // Get state based on WS data
      final remainingSeconds = _parseTimeString(remainingTimeValue);

      if (remainingSeconds != null && remainingSeconds <= 0) {
        // Timer has completed according to the server
        state = state.copyWith(
          currentResponse: response,
          timerState: PomodoroTimerState.completed, // Mark as completed
          remainingTime: 0, // Explicitly set to 0
          currentTimerId: data['timerId'],
          currentSequenceId: data['sequenceId'],
          isRunning: false,
          errorMessage: null,
        );
        _handleTimerComplete(isWebSocketEvent: true);
        _saveToPrefs();
        return; // IMPORTANT: Return here after handling completion
      }

      // If timer is not completed, update state as usual
      state = state.copyWith(
        currentResponse: response,
        timerState: timerStateFromResponse,
        remainingTime:
            remainingSeconds ?? state.remainingTime, // Use parsed if available
        currentTimerId: data['timerId'],
        currentSequenceId: data['sequenceId'],
        isRunning: timerStateFromResponse == PomodoroTimerState.running,
        errorMessage: null,
      );

      _saveToPrefs();

      if (timerStateFromResponse == PomodoroTimerState.running) {
        _localTimer?.cancel(); // Cancel local timer if WS timer is running
      }
    } else {
      state = state.copyWith(
        errorMessage: 'Server error: ${response['message'] ?? 'Unknown error'}',
      );
    }
  }

  // Add this method to parse time strings like "24:59"
  int? _parseTimeString(dynamic timeString) {
    if (timeString == null) return null;

    try {
      if (timeString is String) {
        if (timeString.contains(':')) {
          final parts = timeString.split(':');
          if (parts.length == 2) {
            final minutes = int.parse(parts[0]);
            final seconds = int.parse(parts[1]);
            return (minutes * 60) + seconds;
          }
        } else if (timeString == "Currently, no time is running.") {
          return null; // or 0, depending on your logic
        }
      }
      if (timeString is int) return timeString;
    } catch (_) {}

    return null;
  }

  Future<void> setSelectedTaskType(int selectedOptionValue) async {
    if (selectedOptionValue != -1) {
      state = state.copyWith(selectedTaskTypeIndex: selectedOptionValue);
      _saveToPrefs();
    } else {
      print(
        'Error: Selected option "$selectedOptionValue" not found in options list.',
      );
    }
  }

  void _saveToPrefs() {
    _prefs.setInt('focusDuration', state.focusDuration);
    _prefs.setInt('shortBreakDuration', state.shortBreakDuration);
    _prefs.setInt('longBreakDuration', state.longBreakDuration);
    _prefs.setInt('completedSessions', state.completedSessions);
    _prefs.setInt('completedWorkSessions', state.completedWorkSessions);
    _prefs.setInt('lastSelectedMode', state.mode.index);
    _prefs.setInt('selectedOptionIndex', state.selectedTaskTypeIndex);
  }

  // Update your timer state mapping
  PomodoroTimerState _mapTimerStateFromResponse(Map<String, dynamic> data) {
    final type = data['type'];
    final remainingTime = data['remainingTime'];

    // Check if timer is idle/stopped
    if (remainingTime == "Currently, no time is running." || type == 0) {
      return PomodoroTimerState.idle;
    }

    // Parse remaining time to check if completed
    final timeInSeconds = _parseTimeString(remainingTime);
    if (timeInSeconds != null && timeInSeconds <= 0) {
      return PomodoroTimerState.completed;
    }

    switch (type) {
      case 1:
        return PomodoroTimerState.running;
      case 2:
        return PomodoroTimerState.paused;
      case 0:
      default:
        return PomodoroTimerState.idle;
    }
  }

  Duration? _parseDurationFromSeconds(dynamic seconds) {
    if (seconds == null) return null;
    try {
      if (seconds is int) return Duration(seconds: seconds);
      if (seconds is String) return Duration(seconds: int.parse(seconds));
    } catch (_) {}
    return null;
  }

  // --- Mode Management ---
  void changeMode(PomodoroMode newMode) {
    if (state.isRunning) return; // Don't change mode while running

    final newDuration = _getDurationForMode(
      newMode,
      focusDuration: state.focusDuration,
      shortBreakDuration: state.shortBreakDuration,
      longBreakDuration: state.longBreakDuration,
    );

    state = state.copyWith(
      mode: newMode,
      remainingTime: newDuration,
      timerState: PomodoroTimerState.idle,
    );

    _saveToPrefs();
  }

  void setLongBreakDuration(int minutes) {
    final duration = minutes * 60;
    state = state.copyWith(longBreakDuration: duration);
    if (state.mode == PomodoroMode.longBreak && !state.isRunning) {
      state = state.copyWith(remainingTime: duration);
    }
    _saveToPrefs();
  }

  void setShortBreakDuration(int minutes) {
    final duration = minutes * 60;
    state = state.copyWith(shortBreakDuration: duration);
    if (state.mode == PomodoroMode.shortBreak && !state.isRunning) {
      state = state.copyWith(remainingTime: duration);
    }
    _saveToPrefs();
  }

  void setFocusDuration(int minutes) {
    final duration = minutes * 60;
    state = state.copyWith(focusDuration: duration);
    if (state.mode == PomodoroMode.work && !state.isRunning) {
      state = state.copyWith(remainingTime: duration);
    }
    _saveToPrefs();
  }

  // --- Local Timer Management ---
  void startLocalTimer() {
    if (state.isRunning) return;

    state = state.copyWith(
      isRunning: true,
      timerState: PomodoroTimerState.running,
    );

    _localTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingTime > 0) {
        state = state.copyWith(remainingTime: state.remainingTime - 1);
      } else {
        _localTimer?.cancel();
        state = state.copyWith(
          isRunning: false,
          timerState: PomodoroTimerState.completed,
        );
        _handleTimerComplete();
      }
    });
  }

  void pauseLocalTimer() {
    _localTimer?.cancel();
    state = state.copyWith(
      isRunning: false,
      timerState: PomodoroTimerState.paused,
    );
  }

  void resetLocalTimer() {
    _localTimer?.cancel();

    final defaultDuration = _getDurationForMode(
      state.mode,
      focusDuration: state.focusDuration,
      shortBreakDuration: state.shortBreakDuration,
      longBreakDuration: state.longBreakDuration,
    );

    state = state.copyWith(
      remainingTime: defaultDuration,
      isRunning: false,
      timerState: PomodoroTimerState.idle,
    );
  }

  void _handleTimerComplete({bool isWebSocketEvent = false}) {
    const maxWorkSessions = 4;

    PomodoroMode nextMode;
    int nextDuration;
    int newCompletedWorkSessions = state.completedWorkSessions;
    int newCompletedSessions = state.completedSessions;

    if (state.mode == PomodoroMode.work) {
      newCompletedWorkSessions++;
      if (newCompletedWorkSessions >= maxWorkSessions) {
        nextMode = PomodoroMode.longBreak;
        nextDuration = state.longBreakDuration;
        newCompletedWorkSessions = 0;
        newCompletedSessions++;
      } else {
        nextMode = PomodoroMode.shortBreak;
        nextDuration = state.shortBreakDuration;
      }
    } else {
      nextMode = PomodoroMode.work;
      nextDuration = state.focusDuration;
    }

    state = state.copyWith(
      mode: nextMode,
      remainingTime: nextDuration,
      completedWorkSessions: newCompletedWorkSessions,
      completedSessions: newCompletedSessions,
      isRunning: false,
      timerState: PomodoroTimerState.idle,
    );

    _saveToPrefs();
  }

  // --- WebSocket Control Methods ---
  Future<void> connect() async {
    if (state.connectionState == PomodoroConnectionState.connecting) return;

    state = state.copyWith(
      connectionState: PomodoroConnectionState.connecting,
      errorMessage: null,
    );

    try {
      _server.connect();
    } catch (e) {
      state = state.copyWith(
        connectionState: PomodoroConnectionState.error,
        errorMessage: 'Failed to connect: $e',
      );
    }
  }

  Future<void> startNewPomodoro({
    int? duration,
    String? description,
    int timerType = 1,
  }) async {
    final actualDuration =
        duration ??
        _getDurationForMode(
          state.mode,
          focusDuration: state.focusDuration,
          shortBreakDuration: state.shortBreakDuration,
          longBreakDuration: state.longBreakDuration,
        );
    if (!state.isConnected) {
      await connect();
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!state.isConnected) {
      // Fallback to local timer
      startLocalTimer();
      StateClass.pState = 1;
      return;
    }

    try {
      _server.startPomodoro(
        duration: actualDuration,
        remainingTime: actualDuration,
        timerType: timerType,
        description: description ?? "Work session",
      );
      print('new pomodoro started');

      StateClass.pState = 1;
      state = state.copyWith(
        timerState: PomodoroTimerState.running,
        isRunning: true,
        isNewPomodoro: true,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to start pomodoro: $e');
      // Fallback to local timer
      startLocalTimer();
    }
  }

  Future<void> startExistingPomodoro({
    required int duration,
    required int remainingTime,
    required int timerType,
    required int sequenceId,
  }) async {
    if (!state.isConnected) {
      state = state.copyWith(
        errorMessage: 'Cannot start pomodoro: Not connected to server',
      );
      return;
    }

    // Check if already running locally
    if (state.isRunning) {
      state = state.copyWith(
        errorMessage: 'A timer is already running locally',
      );
      return;
    }

    try {
      // Send the request but don't immediately update state
      // Wait for server response in _handleIncomingMessage
      _server.startExistingPomodoro(
        duration: duration,
        remainingTime: remainingTime,
        timerType: timerType,
        sequenceId: sequenceId,
      );

      // Optional: Set a temporary "starting" state
      state = state.copyWith(errorMessage: null, isNewPomodoro: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to start existing pomodoro: $e',
      );
    }
  }

  /*  Future<void> resumeTimer({
    required int remainingTime,
    required int timerId,
    required int sequenceId,
  }) async {
    if (!state.isConnected) {
      state = state.copyWith(
        errorMessage: 'Cannot resume timer: Not connected to server',
      );
      return;
    }

    try {
      _server.timerResume(
        remainingTime: remainingTime,
        timerId: timerId,
        sequenceId: sequenceId,
      );

      state = state.copyWith(
        timerState: PomodoroTimerState.running,
        isRunning: true,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to resume timer: $e');
    }
  }*/

  Future<void> resetTimer({required int timerId}) async {
    if (!state.isConnected) {
      // Reset local timer
      resetLocalTimer();
      StateClass.pState = 0;
      return;
    }

    try {
      _server.timerReset(timerId: timerId);
      StateClass.pState = 0;
      final defaultDuration = _getDurationForMode(
        state.mode,
        focusDuration: state.focusDuration,
        shortBreakDuration: state.shortBreakDuration,
        longBreakDuration: state.longBreakDuration,
      );

      state = state.copyWith(
        timerState: PomodoroTimerState.idle,
        remainingTime: defaultDuration,
        isRunning: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to reset timer: $e');
      // Fallback to local reset
      resetLocalTimer();
    }
  }

  Future<void> stopTimer() async {
    _localTimer?.cancel();

    if (!state.isConnected) {
      pauseLocalTimer();
      StateClass.pState = 2;
      state = state.copyWith(
        timerState: PomodoroTimerState.paused,
        isRunning: false,
        errorMessage: 'Cannot stop timer: Not connected to server',
      );
      return;
    }

    try {
      _server.timerStop();
      StateClass.pState = 2;
      state = state.copyWith(
        timerState: PomodoroTimerState.paused,
        isRunning: false,
        currentResponse: null,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to stop timer: $e',
        timerState: PomodoroTimerState.paused,
        isRunning: false,
      );
    }
  }

  // NEW: Missing method that was being called in the UI
  /*Future<void> stopExistingTimer() async {
    _localTimer?.cancel();

    if (!state.isConnected) {
      // If not connected, just stop local timer
      state = state.copyWith(
        timerState: PomodoroTimerState.idle,
        isRunning: false,
        currentTimerId: null,
        currentSequenceId: null,
        errorMessage: null,
      );
      return;
    }

    try {
      // If we have an existing timer ID, use it for more specific stopping
      if (state.currentTimerId != null) {
        _server.timerStop();
      } else {
        // General stop command
        _server.timerStop();
      }

      state = state.copyWith(
        timerState: PomodoroTimerState.idle,
        isRunning: false,
        currentTimerId: null,
        currentSequenceId: null,
        currentResponse: null,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to stop existing timer: $e',
        timerState: PomodoroTimerState.idle,
        isRunning: false,
      );
    }
  }*/

  Future<void> resumeLocalTimer() async {
    if (state.timerState != PomodoroTimerState.paused) return;
    if (state.remainingTime <= 0) return;

    state = state.copyWith(
      isRunning: true,
      timerState: PomodoroTimerState.running,
    );

    _localTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingTime > 0) {
        state = state.copyWith(remainingTime: state.remainingTime - 1);
      } else {
        _localTimer?.cancel();
        state = state.copyWith(
          isRunning: false,
          timerState: PomodoroTimerState.completed,
        );
        _handleTimerComplete();
      }
    });
  }

  // Update the existing resumeTimer method to be more robust
  Future<void> resumeTimer({
    required int remainingTime,
    required int timerId,
    required int sequenceId,
  }) async {
    if (!state.isConnected) {
      // If not connected, resume locally
      await resumeLocalTimer();
      StateClass.pState = 1;
      return;
    }

    try {
      _server.timerResume(
        remainingTime: remainingTime,
        timerId: timerId,
        sequenceId: sequenceId,
      );

      StateClass.pState = 1;

      state = state.copyWith(
        timerState: PomodoroTimerState.running,
        isRunning: true,
        remainingTime: remainingTime,
        currentTimerId: timerId,
        currentSequenceId: sequenceId,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to resume timer: $e');
      // Fallback to local resume
      await resumeLocalTimer();
    }
  }

  // Add a method to check if we can resume
  bool get canResume =>
      state.timerState == PomodoroTimerState.paused && state.remainingTime > 0;

  // Method to handle the "already running" scenario
  Future<void> handleTimerAlreadyRunning() async {
    await stopTimer();
    // Wait a bit for the stop to process
    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(
      errorMessage:
          'A timer is already running on the server. Stop it first to start a new one.',
    );
  }

  void disconnect() {
    _server.disconnect();
    state = state.copyWith(
      connectionState: PomodoroConnectionState.disconnected,
      timerState: PomodoroTimerState.idle,
      isRunning: false,
      currentResponse: null,
      errorMessage: null,
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _messageSubscription?.cancel();
    _errorSubscription?.cancel();
    _localTimer?.cancel();
    _server.dispose();
  }
}

// --- Providers ---
final pomodoroWebSocketServerProvider = Provider<PomodoroWebSocketServer>((
  ref,
) {
  final server = PomodoroWebSocketServer();
  ref.onDispose(() => server.dispose());
  return server;
});

final pomodoroNotifierProvider =
    NotifierProvider<PomodoroNotifier, PomodoroState>(() {
      return PomodoroNotifier();
    });

// Convenience providers
final pomodoroRemainingTimeProvider = Provider<int>((ref) {
  final state = ref.watch(pomodoroNotifierProvider);
  return state.remainingTime;
});

final pomodoroModeProvider = Provider<PomodoroMode>((ref) {
  final state = ref.watch(pomodoroNotifierProvider);
  return state.mode;
});

final pomodoroConnectionStateProvider = Provider<PomodoroConnectionState>((
  ref,
) {
  final state = ref.watch(pomodoroNotifierProvider);
  return state.connectionState;
});

final pomodoroTimerStateProvider = Provider<PomodoroTimerState>((ref) {
  final state = ref.watch(pomodoroNotifierProvider);
  return state.timerState;
});

// Extension to add convenience methods to the state
extension PomodoroStateExtensions on PomodoroState {
  bool get isConnected => connectionState == PomodoroConnectionState.connected;

  bool get canStart => !isRunning && timerState != PomodoroTimerState.running;

  bool get canPause => isRunning && timerState == PomodoroTimerState.running;

  bool get canReset =>
      timerState != PomodoroTimerState.idle ||
      remainingTime != _getDefaultDuration();

  int _getDefaultDuration() {
    switch (mode) {
      case PomodoroMode.work:
        return 1500;
      case PomodoroMode.shortBreak:
        return 300;
      case PomodoroMode.longBreak:
        return longBreakDuration;
    }
  }
}
