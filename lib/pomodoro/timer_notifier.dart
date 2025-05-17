import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pomodoro_state_model.dart';
import 'shared_prefs_provider.dart';

class PomodoroNotifier extends Notifier<PomodoroState> {
  Timer? _timer;
  late final SharedPreferences prefs;

  @override
  PomodoroState build() {
    prefs = ref.read(sharedPrefsProvider);

    final savedLongBreak = prefs.getInt('longBreakDuration') ?? 1500;
    final completedSessions = prefs.getInt('completedSessions') ?? 0;
    final savedModeIndex = prefs.getInt('lastSelectedMode') ?? 0;
    final savedMode = PomodoroMode.values[savedModeIndex];

    return PomodoroState(
      remainingSeconds: _getDurationForMode(
        savedMode,
        longBreak: savedLongBreak,
      ),
      mode: savedMode,
      isRunning: false,
      longBreakDuration: savedLongBreak,
      completedSessions: completedSessions,
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
        if (state.mode == PomodoroMode.work) {
          _incrementSession();
        }
        _switchMode();
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

  void _incrementSession() {
    final newCount = state.completedSessions + 1;
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
  }

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
        return 1500;
      case PomodoroMode.shortBreak:
        return 900;
      case PomodoroMode.longBreak:
        return longBreak ?? state.longBreakDuration;
    }
  }
}
