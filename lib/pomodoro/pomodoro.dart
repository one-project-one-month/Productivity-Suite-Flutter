import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notifiers/timer_notifier.dart';
import 'models/pomodoro_state_model.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Pomodoro Timer'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Consumer(
            builder: (context, ref, _) {
              return TabBar(
                indicatorColor: const Color(0xff0045f3),
                labelColor: const Color(0xff0045f3),
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Focus'),
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
            _buildTimerDisplay(pomodoro),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 32,
                  icon:
                      pomodoro.isRunning
                          ? Icon(Icons.pause)
                          : Icon(Icons.play_arrow),
                  color: const Color(0xff0045f3),
                  onPressed:
                      pomodoro.isRunning ? notifier.pause : notifier.start,
                  //label: Text(pomodoro.isRunning ? 'Pause' : 'Start'),
                ),
                const SizedBox(width: 20),
                IconButton(
                  iconSize: 32,
                  icon: Icon(Icons.refresh),
                  color: const Color(0xff0045f3),
                  onPressed: notifier.reset,
                  //label: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Completed Sessions: ${pomodoro.completedSessions}'),
            Text('Small(Work) Sessions: ${pomodoro.completedWorkSessions}'),
            const SizedBox(height: 40),
            /*Text(
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
            ),*/
            _ModeWidgets(),
          ],
        ),
      ),
    );
  }
}

class _ModeWidgets extends ConsumerWidget {
  const _ModeWidgets();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomodoroState = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Focus Session',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(children: [Text('25 min'), Icon(Icons.arrow_right)]),
          ],
        ),
        SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Short Break',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(children: [Text('5 min'), Icon(Icons.arrow_right)]),
          ],
        ),
        SizedBox(height: 8.0),
        InkWell(
          onTap: () async {
            final selectedMinutes = await showDialog<int>(
              context: context,
              builder:
                  (_) => CustomTimePickerDialog(
                    initialMinutes: pomodoroState.longBreakDuration ~/ 60,
                  ),
            );

            if (selectedMinutes != null) {
              notifier.setLongBreakDuration(selectedMinutes);
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Long Break',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text('${pomodoroState.longBreakDuration ~/ 60} min'),
                  Icon(Icons.arrow_right),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Long Break After',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(children: [Text('5 secs'), Icon(Icons.arrow_right)]),
          ],
        ),
      ],
    );
  }
}

class CustomTimePickerDialog extends StatelessWidget {
  final int initialMinutes;

  const CustomTimePickerDialog({super.key, required this.initialMinutes});

  @override
  Widget build(BuildContext context) {
    int selectedMinutes = initialMinutes;

    return AlertDialog(
      title: Text('Select Time'),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: () {
                  if (selectedMinutes > 1) {
                    setState(() {
                      selectedMinutes--;
                    });
                  }
                },
              ),
              Text('$selectedMinutes min', style: TextStyle(fontSize: 24)),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    selectedMinutes++;
                  });
                },
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Cancel
          child: Text('Cancel', style: TextStyle(color: Color(0xff0045f3))),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Color(0xff0045f3)),
          onPressed: () => Navigator.pop(context, selectedMinutes),
          child: Text('OK'),
        ),
      ],
    );
  }
}

Widget _buildTimerDisplay(PomodoroState state) {
  final minutes = (state.remainingSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (state.remainingSeconds % 60).toString().padLeft(2, '0');
  final Color activeSessionColor = const Color(0xff0045f3);
  final Color inactiveSessionColor = Colors.grey.shade300;
  final int totalIndicators = 4;

  return Stack(
    alignment: Alignment.center,
    children: [
      Center(
        child: SizedBox(
          width: 280,
          height: 280,
          child: CircularProgressIndicator(
            value: _calculateProgress(state),
            backgroundColor: Colors.grey.shade300,
            strokeWidth: 12,
            valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(state)),
          ),
        ),
      ),
      Positioned(top: 40, child: _getIconForMode(state.mode)),
      Text(
        '$minutes : $seconds',
        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
      ),

      Positioned(
        bottom: 32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(totalIndicators, (index) {
                bool isActive = (index + 1) <= state.completedWorkSessions;
                return Padding(
                  padding: EdgeInsets.only(
                    right: (index < totalIndicators - 1) ? 3.0 : 0.0,
                  ),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color:
                          isActive ? activeSessionColor : inactiveSessionColor,
                      borderRadius: BorderRadius.all(Radius.circular(4.0)),
                    ),
                    width: 8,
                    height: 24,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                state.mode.toString().split('.').last.toUpperCase(),
                key: ValueKey(state.mode),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
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

Icon _getIconForMode(PomodoroMode mode) {
  double iconSize = 32;
  Color iconColor = Color(0xff0045f3);
  switch (mode) {
    case PomodoroMode.work:
      return Icon(
        Icons.laptop_mac,
        size: iconSize,
        color: iconColor,
      ); // Example icons
    case PomodoroMode.shortBreak:
      return Icon(Icons.coffee, size: iconSize, color: iconColor);
    case PomodoroMode.longBreak:
      return Icon(Icons.bedtime_outlined, size: iconSize, color: iconColor);
    //   return Icons.device_unknown;
  }
}

double _calculateProgress(PomodoroState state) {
  final total = switch (state.mode) {
    PomodoroMode.work => 10,
    PomodoroMode.shortBreak => 5,
    PomodoroMode.longBreak => state.longBreakDuration,
  };

  return 1 - (state.remainingSeconds / total);
}

Color _getProgressColor(PomodoroState state) {
  final progress = _calculateProgress(state);

  // Interpolate from red (0%) -> orange (50%) -> green (100%)
  if (progress < 0.5) {
    // Red to orange
    return Color.lerp(
      Colors.blue.shade200,
      Colors.blue.shade400,
      progress * 2,
    )!;
    //return Color(0xff0045F3);
  } else {
    // Orange to green
    return Color.lerp(
      Colors.blue.shade500,
      Color(0xff0045f3),
      (progress - 0.5) * 2,
    )!;
  }
}
