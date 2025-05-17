import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'timer_notifier.dart';
import 'pomodoro_state_model.dart';

class Pomodoro extends StatelessWidget {
  const Pomodoro({super.key});

  @override
  Widget build(BuildContext context) {
    return PomodoroHomePage();
  }
}

final pomodoroProvider = NotifierProvider<PomodoroNotifier, PomodoroState>(
  () => PomodoroNotifier(),
);

class PomodoroHomePage extends ConsumerStatefulWidget {
  const PomodoroHomePage({super.key});

  @override
  ConsumerState<PomodoroHomePage> createState() => _PomodoroHomePageState();
}

class _PomodoroHomePageState extends ConsumerState<PomodoroHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mode = ref.read(pomodoroProvider).mode;
      _tabController.index = mode.index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pomodoro = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    ref.listen<PomodoroState>(pomodoroProvider, (prev, next) {
      if (prev?.mode != next.mode) {
        _tabController.animateTo(next.mode.index);
      }
    });

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Pomodoro Timer'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Consumer(
            builder: (context, ref, _) {
              return TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Work'),
                  Tab(text: 'Short Break'),
                  Tab(text: 'Long Break'),
                ],
                onTap: (index) {
                  final selectedMode = PomodoroMode.values[index];
                  if (pomodoro.mode != selectedMode) {
                    notifier.changeMode(selectedMode);
                  }
                },
              );
            },
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                pomodoro.mode.toString().split('.').last.toUpperCase(),
                key: ValueKey(pomodoro.mode),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTimerDisplay(pomodoro),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon:
                      pomodoro.isRunning
                          ? Icon(Icons.pause)
                          : Icon(Icons.play_arrow),
                  onPressed:
                      pomodoro.isRunning ? notifier.pause : notifier.start,
                  label: Text(pomodoro.isRunning ? 'Pause' : 'Start'),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  icon: Icon(Icons.refresh),
                  onPressed: notifier.reset,
                  label: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Completed Sessions: ${pomodoro.completedSessions}'),
            const SizedBox(height: 40),
            Text(
              'Set Long Break Duration (minutes): ${pomodoro.longBreakDuration ~/ 60} min',
            ),
            Slider(
              value: pomodoro.longBreakDuration / 60,
              min: 5,
              max: 60,
              divisions: 11,
              label: '${pomodoro.longBreakDuration ~/ 60} min',
              onChanged: (value) {
                notifier.setLongBreakDuration(value.toInt());
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildTimerDisplay(PomodoroState state) {
  final minutes = (state.remainingSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (state.remainingSeconds % 60).toString().padLeft(2, '0');

  return Stack(
    alignment: Alignment.center,
    children: [
      SizedBox(
        width: 220,
        height: 220,
        child: CircularProgressIndicator(
          value: _calculateProgress(state),
          backgroundColor: Colors.grey.shade300,
          strokeWidth: 12,
          valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(state)),
        ),
      ),
      Text(
        '$minutes:$seconds',
        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

/*double _calculateProgress(PomodoroState state) {
  final totalSeconds = state.remainingSeconds;

  int totalDuration;
  switch (state.mode) {
    case PomodoroMode.work:
      totalDuration = 1500;
      break;
    case PomodoroMode.shortBreak:
      totalDuration = 900;
      break;
    case PomodoroMode.longBreak:
      totalDuration = state.longBreakDuration;
      break;
  }

  return 1 - (totalSeconds / totalDuration);
}*/
double _calculateProgress(PomodoroState state) {
  final total = switch (state.mode) {
    PomodoroMode.work => 1500,
    PomodoroMode.shortBreak => 900,
    PomodoroMode.longBreak => state.longBreakDuration,
  };

  return 1 - (state.remainingSeconds / total);
}

Color _getProgressColor(PomodoroState state) {
  final progress = _calculateProgress(state);

  // Interpolate from red (0%) -> orange (50%) -> green (100%)
  if (progress < 0.5) {
    // Red to orange
    return Color.lerp(Colors.red, Colors.orange, progress * 2)!;
  } else {
    // Orange to green
    return Color.lerp(Colors.orange, Colors.green, (progress - 0.5) * 2)!;
  }
}
