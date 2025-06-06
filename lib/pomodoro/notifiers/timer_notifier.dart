import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pomodoro_state_model.dart';
import '../utils/shared_prefs_provider.dart';

/*class PomodoroNotifier extends Notifier<PomodoroStateModel> {
  Timer? _timer;
  late final SharedPreferences prefs;

  @override
  PomodoroStateModel build() {
    prefs = ref.read(sharedPrefsProvider);

    final savedLongBreak = prefs.getInt('longBreakDuration') ?? 1500;
    final completedSessions = prefs.getInt('completedSessions') ?? 0;
    final savedModeIndex = prefs.getInt('lastSelectedMode') ?? 0;
    final completedWorkSessions = prefs.getInt('completedWorkSessions') ?? 0;
    final savedMode = PomodoroMode.values[savedModeIndex];

    return PomodoroStateModel(
      remainingSeconds: _getDurationForMode(
        savedMode,
        longBreak: savedLongBreak,
      ),
      mode: savedMode,
      isRunning: false,
      longBreakDuration: savedLongBreak,
      completedSessions: completedSessions,
      completedWorkSessions: completedWorkSessions,
    );
  }

  void start() {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _timer?.cancel();
        state = state.copyWith(isRunning: false);
        _handleTimerComplete();
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    final defaultDuration = _getDurationForMode(state.mode);
    state = state.copyWith(remainingSeconds: defaultDuration, isRunning: false);
  }

  void _handleTimerComplete() {
    const maxWorkSessions = 4;

    if (state.mode == PomodoroMode.work) {
      final newWorkCount = state.completedWorkSessions + 1;

      if (newWorkCount < maxWorkSessions) {
        // Short break
        prefs.setInt('completedWorkSessions', newWorkCount);
        state = state.copyWith(
          mode: PomodoroMode.shortBreak,
          remainingSeconds: 5,
          completedWorkSessions: newWorkCount,
          isRunning: false,
        );
      } else {
        // Completed 4 work sessions → now long break
        //final newCompletedSessions = state.completedSessions + 1;
        final newCompletedSessions = (state.completedSessions + 1) % 5;

        prefs.setInt('completedWorkSessions', 0);
        prefs.setInt('completedSessions', newCompletedSessions);
        state = state.copyWith(
          mode: PomodoroMode.longBreak,
          remainingSeconds: state.longBreakDuration,
          completedWorkSessions: 0,
          completedSessions: newCompletedSessions,
          isRunning: false,
        );
      }
    } else {
      // After any break → go to work
      state = state.copyWith(
        mode: PomodoroMode.work,
        remainingSeconds: 10,
        isRunning: false,
      );
    }
  }

  */ /*void _incrementSession() {
    const int maxSessions = 4;
    int newCount;
    if (state.completedSessions >= maxSessions) {
      newCount = 0;
    } else {
      newCount = state.completedSessions + 1;
    }
    prefs.setInt('completedSessions', newCount);
    state = state.copyWith(completedSessions: newCount);
  }

  void _switchMode() {
    if (state.mode == PomodoroMode.work) {
      changeMode(PomodoroMode.shortBreak);
    } else if (state.mode == PomodoroMode.shortBreak) {
      changeMode(PomodoroMode.longBreak);
    } else {
      changeMode(PomodoroMode.work);
    }
  }*/ /*

  void changeMode(PomodoroMode mode) {
    final seconds = _getDurationForMode(mode);
    final wasRunning = state.isRunning;

    _timer?.cancel();
    prefs.setInt('lastSelectedMode', mode.index); // Save current mode
    state = state.copyWith(mode: mode, remainingSeconds: seconds);

    if (wasRunning) start();
  }

  void setLongBreakDuration(int minutes) {
    final duration = minutes * 60;
    prefs.setInt('longBreakDuration', duration);
    state = state.copyWith(longBreakDuration: duration);
  }

  int _getDurationForMode(PomodoroMode mode, {int? longBreak}) {
    switch (mode) {
      case PomodoroMode.work:
        return 5; // 25 minutes(1500)
      case PomodoroMode.shortBreak:
        return 3; // 5 minutes(300)
      case PomodoroMode.longBreak:
        return longBreak ?? state.longBreakDuration;
    }
  }
}*/
