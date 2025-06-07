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
  bool _isInitializingConnection = false;

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
        print('[POMODORO] Server says timer already running, forcing stop...');

        // Force stop the server timer and reset local state
        _server.timerStop();

        state = state.copyWith(
          errorMessage: 'Timer conflict detected. Stopping server timer...',
          timerState: PomodoroTimerState.idle,
          isRunning: false,
          currentTimerId: null,
          currentSequenceId: null,
        );

        // After a delay, allow user to start fresh
        Future.delayed(Duration(seconds: 2), () {
          state = state.copyWith(errorMessage: null);
        });
        return;
      }

      // Handle type 0 (idle/stopped) responses
      if (data['type'] == 0) {
        print('[POMODORO] Server confirms timer stopped');
        state = state.copyWith(
          timerState: PomodoroTimerState.idle,
          isRunning: false,
          currentTimerId: null,
          currentSequenceId: null,
          errorMessage: null,
        );
        StateClass.pState = 0;
        return;
      }

      // --- Normal response handling ---
      final timerStateFromResponse = _mapTimerStateFromResponse(data);
      final remainingSeconds = _parseTimeString(remainingTimeValue);

      // Handle timer completion
      if (remainingSeconds != null && remainingSeconds <= 0) {
        print('[POMODORO] Timer completed');
        state = state.copyWith(
          currentResponse: response,
          timerState: PomodoroTimerState.completed,
          remainingTime: 0,
          currentTimerId: data['timerId'],
          currentSequenceId: data['sequenceId'],
          isRunning: false,
          errorMessage: null,
        );
        _handleTimerComplete(isWebSocketEvent: true);
        _saveToPrefs();
        StateClass.pState = 0;
        return;
      }

      // Normal timer update
      print('[POMODORO] Timer update - Type: ${data['type']}, Time: $remainingTimeValue');

      state = state.copyWith(
        currentResponse: response,
        timerState: timerStateFromResponse,
        remainingTime: remainingSeconds ?? state.remainingTime,
        currentTimerId: data['timerId'],
        currentSequenceId: data['sequenceId'],
        isRunning: timerStateFromResponse == PomodoroTimerState.running,
        errorMessage: null,
      );

      // Update StateClass for UI
      switch (timerStateFromResponse) {
        case PomodoroTimerState.running:
          StateClass.pState = 1;
          break;
        case PomodoroTimerState.paused:
          StateClass.pState = 2;
          break;
        case PomodoroTimerState.idle:
        case PomodoroTimerState.completed:
          StateClass.pState = 0;
          break;
      }

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
  Future<void> forceServerSync() async {
    if (!state.isConnected) {
      await connect();
      return;
    }

    try {
      // Send a stop command to clear any server-side running timers
      await _server.forceStopTimer();

      // Reset local state to idle
      state = state.copyWith(
        timerState: PomodoroTimerState.idle,
        isRunning: false,
        currentTimerId: null,
        currentSequenceId: null,
        errorMessage: null,
      );
      StateClass.pState = 0;

      print('[POMODORO] Forced sync with server completed');
    } catch (e) {
      print('[POMODORO] Force sync failed: $e');
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

  Future<void> connect() async {
    // Prevent multiple simultaneous connection attempts
    if (_isInitializingConnection) {
      print('[POMODORO] Connection already in progress, skipping...');
      return;
    }

    if (state.connectionState == PomodoroConnectionState.connecting ||
        state.connectionState == PomodoroConnectionState.connected) {
      print('[POMODORO] Already connecting/connected, skipping...');
      return;
    }

    _isInitializingConnection = true;

    state = state.copyWith(
      connectionState: PomodoroConnectionState.connecting,
      errorMessage: null,
    );

    try {
      // Disconnect first if there's any existing connection
      _server.disconnect();
      await Future.delayed(Duration(milliseconds: 300));

      _server.connect();
      print('[POMODORO] Connection initiated');
    } catch (e) {
      state = state.copyWith(
        connectionState: PomodoroConnectionState.error,
        errorMessage: 'Failed to connect: $e',
      );
    } finally {
      _isInitializingConnection = false;
    }
  }
// Add this method to handle connection cleanup on logout
  Future<void> disconnectAndCleanup() async {
    _isInitializingConnection = false;
    _server.disconnect();

    state = state.copyWith(
      connectionState: PomodoroConnectionState.disconnected,
      timerState: PomodoroTimerState.idle,
      isRunning: false,
      currentTimerId: null,
      currentSequenceId: null,
      currentResponse: null,
      errorMessage: null,
    );
    StateClass.pState = 0;
  }

// Update the existing startNewPomodoro method to use the safe start:
  Future<void> startNewPomodoro({
    int? duration,
    String? description,
    int timerType = 1,
  }) async {
    final actualDuration = duration ?? _getDurationForMode(
      state.mode,
      focusDuration: state.focusDuration,
      shortBreakDuration: state.shortBreakDuration,
      longBreakDuration: state.longBreakDuration,
    );

    if (!state.isConnected) {
      await connect();
      await Future.delayed(const Duration(seconds: 2)); // Give more time for connection
    }

    if (!state.isConnected) {
      // Fallback to local timer
      startLocalTimer();
      StateClass.pState = 1;
      return;
    }

    try {
      // Use the safe start method
      await _server.startPomodoroSafe(
        duration: actualDuration,
        remainingTime: actualDuration,
        timerType: timerType,
        description: description ?? "Work session",
      );
      print('New pomodoro started safely');

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
  /// Start new short break session
  Future<void> startNewShortBreak({
    int? duration,
    String? description,
  }) async {
    final actualDuration = duration ?? state.shortBreakDuration;

    if (!state.isConnected) {
      await connect();
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!state.isConnected) {
      // Fallback to local timer
      changeMode(PomodoroMode.shortBreak);
      startLocalTimer();
      StateClass.pState = 1;
      return;
    }

    try {
      _server.startShortBreak(
        duration: actualDuration,
        remainingTime: actualDuration,
        description: description ?? "Short break session",
        sequenceId: state.currentSequenceId,
      );
      print('Short break started');

      StateClass.pState = 1;
      state = state.copyWith(
        mode: PomodoroMode.shortBreak,
        timerState: PomodoroTimerState.running,
        isRunning: true,
        remainingTime: actualDuration,
        isNewPomodoro: true,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to start short break: $e');
      // Fallback to local timer
      changeMode(PomodoroMode.shortBreak);
      startLocalTimer();
    }
  }

  /// Start new long break session
  Future<void> startNewLongBreak({
    int? duration,
    String? description,
  }) async {
    final actualDuration = duration ?? state.longBreakDuration;

    if (!state.isConnected) {
      await connect();
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!state.isConnected) {
      // Fallback to local timer
      changeMode(PomodoroMode.longBreak);
      startLocalTimer();
      StateClass.pState = 1;
      return;
    }

    try {
      _server.startLongBreak(
        duration: actualDuration,
        remainingTime: actualDuration,
        description: description ?? "Long break session",
        sequenceId: state.currentSequenceId,
      );
      print('Long break started');

      StateClass.pState = 1;
      state = state.copyWith(
        mode: PomodoroMode.longBreak,
        timerState: PomodoroTimerState.running,
        isRunning: true,
        remainingTime: actualDuration,
        isNewPomodoro: true,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to start long break: $e');
      // Fallback to local timer
      changeMode(PomodoroMode.longBreak);
      startLocalTimer();
    }
  }

  /// Resume short break timer
  Future<void> resumeShortBreak({
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
      _server.resumeShortBreak(
        remainingTime: remainingTime,
        timerId: timerId,
        sequenceId: sequenceId,
      );

      StateClass.pState = 1;

      state = state.copyWith(
        mode: PomodoroMode.shortBreak,
        timerState: PomodoroTimerState.running,
        isRunning: true,
        remainingTime: remainingTime,
        currentTimerId: timerId,
        currentSequenceId: sequenceId,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to resume short break: $e');
      // Fallback to local resume
      await resumeLocalTimer();
    }
  }

  /// Resume long break timer
  Future<void> resumeLongBreak({
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
      _server.resumeLongBreak(
        remainingTime: remainingTime,
        timerId: timerId,
        sequenceId: sequenceId,
      );

      StateClass.pState = 1;

      state = state.copyWith(
        mode: PomodoroMode.longBreak,
        timerState: PomodoroTimerState.running,
        isRunning: true,
        remainingTime: remainingTime,
        currentTimerId: timerId,
        currentSequenceId: sequenceId,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to resume long break: $e');
      // Fallback to local resume
      await resumeLocalTimer();
    }
  }

  /// Stop short break timer
  Future<void> stopShortBreak() async {
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
      _server.stopShortBreak();
      StateClass.pState = 2;
      state = state.copyWith(
        mode: PomodoroMode.shortBreak,
        timerState: PomodoroTimerState.paused,
        isRunning: false,
        currentResponse: null,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to stop short break: $e',
        timerState: PomodoroTimerState.paused,
        isRunning: false,
      );
    }
  }

  /// Stop long break timer
  Future<void> stopLongBreak() async {
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
      _server.stopLongBreak();
      StateClass.pState = 2;
      state = state.copyWith(
        mode: PomodoroMode.longBreak,
        timerState: PomodoroTimerState.paused,
        isRunning: false,
        currentResponse: null,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to stop long break: $e',
        timerState: PomodoroTimerState.paused,
        isRunning: false,
      );
    }
  }

  /// Reconnect WebSocket with new auth token after login
  Future<void> reconnectAfterLogin() async {
    print('Reconnecting Pomodoro WebSocket after login...');

    // Disconnect first if connected
    if (state.connectionState == PomodoroConnectionState.connected) {
      _server.disconnect();
    }

    // Wait a bit for cleanup
    await Future.delayed(Duration(milliseconds: 500));

    // Reconnect with new token
    await _server.reconnectWithNewToken();

    state = state.copyWith(
      connectionState: PomodoroConnectionState.connecting,
      errorMessage: null,
    );
  }

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
  /// Smart start method that determines what type of session to start based on current mode
  Future<void> startCurrentModeSession({
    String? description,
  }) async {
    switch (state.mode) {
      case PomodoroMode.work:
        await startNewPomodoro(description: description);
        break;
      case PomodoroMode.shortBreak:
        await startNewShortBreak(description: description);
        break;
      case PomodoroMode.longBreak:
        await startNewLongBreak(description: description);
        break;
    }
  }

  /// Smart resume method that determines what type of session to resume based on current mode
  Future<void> resumeCurrentModeSession() async {
    if (state.currentTimerId == null || state.currentSequenceId == null) {
      state = state.copyWith(errorMessage: 'Cannot resume: Missing timer or sequence ID');
      return;
    }

    switch (state.mode) {
      case PomodoroMode.work:
        await resumeTimer(
          remainingTime: state.remainingTime,
          timerId: state.currentTimerId!,
          sequenceId: state.currentSequenceId!,
        );
        break;
      case PomodoroMode.shortBreak:
        await resumeShortBreak(
          remainingTime: state.remainingTime,
          timerId: state.currentTimerId!,
          sequenceId: state.currentSequenceId!,
        );
        break;
      case PomodoroMode.longBreak:
        await resumeLongBreak(
          remainingTime: state.remainingTime,
          timerId: state.currentTimerId!,
          sequenceId: state.currentSequenceId!,
        );
        break;
    }
  }

  /// Smart stop method that determines what type of session to stop based on current mode
  Future<void> stopCurrentModeSession() async {
    switch (state.mode) {
      case PomodoroMode.work:
        await stopTimer();
        break;
      case PomodoroMode.shortBreak:
        await stopShortBreak();
        break;
      case PomodoroMode.longBreak:
        await stopLongBreak();
        break;
    }
  }

  /// Get the timer type for WebSocket based on current mode
  int get currentTimerType {
    switch (state.mode) {
      case PomodoroMode.work:
        return 1; // Work session
      case PomodoroMode.shortBreak:
        return 2; // Short break
      case PomodoroMode.longBreak:
        return 3; // Long break
    }
  }

  /// Check if current session can auto-transition to next mode
  bool get canAutoTransition {
    return state.timerState == PomodoroTimerState.completed;
  }

  /// Auto-transition to next logical mode after session completion
  Future<void> autoTransitionToNextMode() async {
    if (!canAutoTransition) return;

    const maxWorkSessions = 4;

    if (state.mode == PomodoroMode.work) {
      final newWorkCount = state.completedWorkSessions + 1;

      if (newWorkCount >= maxWorkSessions) {
        // After 4 work sessions, start long break
        changeMode(PomodoroMode.longBreak);
        await startNewLongBreak(description: "Long break after 4 work sessions");
      } else {
        // Start short break
        changeMode(PomodoroMode.shortBreak);
        await startNewShortBreak(description: "Short break after work session");
      }
    } else {
      // After any break, go back to work
      changeMode(PomodoroMode.work);
      await startNewPomodoro(description: "Work session after break");
    }
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
