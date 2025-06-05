import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:productivity_suite_flutter/pomodoro/models/state_class.dart';

import 'models/pomodoro_state_model.dart';
import 'notifiers/pomodoro_state_notifier.dart';

class Pomodoro extends StatelessWidget {
  const Pomodoro({super.key});

  @override
  Widget build(BuildContext context) {
    return const PomodoroHomePage();
  }
}

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
      final mode = ref.read(pomodoroNotifierProvider).mode;
      _tabController.index = mode.index;

      // Use the notifier's connection method instead of creating a new server
      ref.read(pomodoroNotifierProvider.notifier).connect();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pomodoro = ref.watch(pomodoroNotifierProvider);
    final notifier = ref.read(pomodoroNotifierProvider.notifier);

    ref.listen<PomodoroState>(pomodoroNotifierProvider, (prev, next) {
      if (prev?.mode != next.mode) {
        _tabController.animateTo(next.mode.index);
      }

      // Show error messages
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                notifier.clearError();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pomodoro Timer'),
            const SizedBox(width: 8),
            _buildConnectionIndicator(pomodoro.connectionState),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showInputDialog(context, notifier, pomodoro);
            },
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xff0045f3),
          labelColor: const Color(0xff0045f3),
          tabs: const [
            Tab(text: 'Focus'),
            Tab(text: 'Short Break'),
            Tab(text: 'Long Break'),
          ],
          onTap: (index) {
            final selectedMode = PomodoroMode.values[index];
            if (pomodoro.mode != selectedMode && !pomodoro.isRunning) {
              notifier.changeMode(selectedMode);
            }
          },
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
                  icon: _getPlayPauseIcon(pomodoro),
                  color: const Color(0xff0045f3),
                  onPressed: () {
                    switch (StateClass.pState) {
                      /*case PomodoroTimerState.running:
                        notifier.stopTimer();
                        print('Running :::::::::::');
                        break;
                      case PomodoroTimerState.paused:
                        print('Resumed :::::::::::');
                        break;
                      case PomodoroTimerState.idle:
                        print('Idle :::::::::::');
                        notifier.startNewPomodoro();
                        break;
                      case PomodoroTimerState.completed:
                        break;*/
                      case 0:
                        print('Running :::::::::::');
                        notifier.startNewPomodoro();
                        break;
                      case 1:
                        print('Paused :::::::::::');
                        notifier.stopTimer();
                        break;
                      case 2:
                        print('Resumed :::::::::::');
                        notifier.resumeTimer(
                          remainingTime: pomodoro.remainingTime,
                          timerId: pomodoro.currentTimerId ?? 0,
                          sequenceId: pomodoro.currentSequenceId ?? 0,
                        );
                        break;
                      default:
                        break;
                    }
                  },
                ),
                const SizedBox(width: 20),
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.refresh),
                  color: const Color(0xff0045f3),
                  onPressed: () {
                    notifier.resetTimer(timerId: pomodoro.currentTimerId ?? 0);
                  },
                ),
              ],
            ),
            /*const SizedBox(height: 20),
            Text('Completed Sessions: ${pomodoro.completedSessions}'),
            Text('Work Sessions: ${pomodoro.completedWorkSessions}'),*/
            const SizedBox(height: 20),
            Expanded(child: const _ModeWidgets()),
          ],
        ),
      ),
    );
  }

  Widget _getPlayPauseIcon(PomodoroState pomodoro) {
    switch (pomodoro.timerState) {
      case PomodoroTimerState.running:
        return const Icon(Icons.pause);
      case PomodoroTimerState.paused:
        return const Icon(Icons.play_arrow); // Resume icon
      case PomodoroTimerState.idle:
      case PomodoroTimerState.completed:
      default:
        return const Icon(Icons.play_arrow); // Start icon
    }
  }

  void _handlePlayPausePress(PomodoroState state, PomodoroNotifier notifier) {
    print(' ${state.timerState} :::::::::::');
    switch (state.timerState) {
      case PomodoroTimerState.running:
        notifier.stopTimer();
        break;
      case PomodoroTimerState.paused:
        notifier.resumeTimer(
          remainingTime: state.remainingTime,
          timerId: state.currentTimerId ?? 0,
          sequenceId: state.currentSequenceId ?? 0,
        );
        print('Resumed Timer :::::::::::');
        break;
      default:
        notifier.startNewPomodoro();
        break;
    }
  }

  Widget _buildConnectionIndicator(PomodoroConnectionState state) {
    Color color;
    IconData icon;

    switch (state) {
      case PomodoroConnectionState.connected:
        color = Colors.green;
        icon = Icons.wifi;
        break;
      case PomodoroConnectionState.connecting:
        color = Colors.orange;
        icon = Icons.wifi_protected_setup;
        break;
      case PomodoroConnectionState.error:
        color = Colors.red;
        icon = Icons.wifi_off;
        break;
      case PomodoroConnectionState.disconnected:
      default:
        color = Colors.grey;
        icon = Icons.wifi_off;
        break;
    }

    return Icon(icon, color: color, size: 24);
  }
}

class _ModeWidgets extends ConsumerWidget {
  const _ModeWidgets();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroNotifierProvider);
    final notifier = ref.read(pomodoroNotifierProvider.notifier);

    return ListView(
      children: [
        InkWell(
          onTap: () async {
            final selectedMinutes = await showDialog<int>(
              context: context,
              builder:
                  (_) => CustomTimePickerDialog(
                    initialMinutes: state.focusDuration ~/ 60,
                  ),
            );

            if (selectedMinutes != null) {
              notifier.setFocusDuration(selectedMinutes);
            }
          },
          child: _modeRow(
            title: 'Focus Session',
            value: '${state.focusDuration ~/ 60} min',
            isInteractive: true,
          ),
        ),
        InkWell(
          onTap: () async {
            final selectedMinutes = await showDialog<int>(
              context: context,
              builder:
                  (_) => CustomTimePickerDialog(
                    initialMinutes: state.shortBreakDuration ~/ 60,
                  ),
            );

            if (selectedMinutes != null) {
              notifier.setShortBreakDuration(selectedMinutes);
            }
          },
          child: _modeRow(
            title: 'Short Break',
            value: '${state.shortBreakDuration ~/ 60} min',
            isInteractive: true,
          ),
        ),
        InkWell(
          onTap: () async {
            final selectedMinutes = await showDialog<int>(
              context: context,
              builder:
                  (_) => CustomTimePickerDialog(
                    initialMinutes: state.longBreakDuration ~/ 60,
                  ),
            );

            if (selectedMinutes != null) {
              notifier.setLongBreakDuration(selectedMinutes);
            }
          },
          child: _modeRow(
            title: 'Long Break',
            value: '${state.longBreakDuration ~/ 60} min',
            isInteractive: true,
          ),
        ),
        _modeRow(title: 'Long Break After', value: '4 sessions'),
      ],
    );
  }

  Widget _modeRow({
    required String title,
    required String value,
    bool isInteractive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Text(value),
              if (isInteractive) const Icon(Icons.arrow_right),
            ],
          ),
        ],
      ),
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
      title: const Text('Select Time'),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (selectedMinutes > 1) {
                    setState(() => selectedMinutes--);
                  }
                },
              ),
              Text(
                '$selectedMinutes min',
                style: const TextStyle(fontSize: 24),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => selectedMinutes++),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xff0045f3)),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xff0045f3),
          ),
          onPressed: () => Navigator.pop(context, selectedMinutes),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

Future<void> _showInputDialog(
  BuildContext context,
  PomodoroNotifier notifier,
  PomodoroState state,
) async {
  final List<String> alertDialogDropdownOptions = [
    'Default',
    'Work',
    'Study',
    'Social',
  ];
  String? selectedDropdownValue = alertDialogDropdownOptions[0];
  final TextEditingController textFieldController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setStateInDialog) {
          return AlertDialog(
            title: const Text('Choose Type:'),
            content: SingleChildScrollView(
              // In case content is too long for the screen
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // To make the column compact
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Select Type:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      value: selectedDropdownValue,
                      isExpanded: true,
                      hint: const Text('Select an option'),
                      icon: const Icon(Icons.arrow_drop_down),
                      onChanged: (String? newValue) {
                        setStateInDialog(() {
                          selectedDropdownValue = newValue;
                        });
                      },
                      items:
                          alertDialogDropdownOptions
                              .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              })
                              .toList(),
                      validator:
                          (value) =>
                              value == null ? 'Please select an option' : null,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Enter Description:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: textFieldController,
                      decoration: const InputDecoration(
                        hintText: 'Enter description here...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter some descriptions';
                        }
                        return null;
                      },
                      maxLines: 3, // Allow multi-line input
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Return null
                },
              ),
              FilledButton(
                // Or ElevatedButton
                child: const Text('OK'),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(dialogContext).pop({
                      'selectedOption': selectedDropdownValue,
                      'description': textFieldController.text,
                    });
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );

  // Handle the result
  if (result != null) {
    final currentIndex = alertDialogDropdownOptions.indexOf(
      result['selectedOption'],
    );
    notifier.setSelectedTaskType(currentIndex);
    if (state.isNewPomodoro == false) {
      notifier.startNewPomodoro(
        timerType: currentIndex,
        description: result['description'],
        duration: state.remainingTime,
      );
    } else {
      notifier.startExistingPomodoro(
        duration: state.remainingTime,
        remainingTime: state.remainingTime,
        timerType: state.selectedTaskTypeIndex,
        sequenceId: state.currentSequenceId ?? 0,
      );
    }
  } else {
    print('Dialog canceled.');
  }
}

Widget _buildTimerDisplay(PomodoroState state) {
  final minutes = (state.remainingTime ~/ 60).toString().padLeft(2, '0');
  final seconds = (state.remainingTime % 60).toString().padLeft(2, '0');
  const Color activeColor = Color(0xff0045f3);
  final Color inactiveColor = Colors.grey.shade300;

  return Stack(
    alignment: Alignment.center,
    children: [
      SizedBox(
        width: 250,
        height: 250,
        child: CircularProgressIndicator(
          value: _calculateProgress(state),
          backgroundColor: inactiveColor,
          strokeWidth: 12,
          valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(state)),
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
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (index) {
                bool isActive = (index + 1) <= state.completedWorkSessions;
                return Padding(
                  padding: EdgeInsets.only(right: index < 3 ? 3.0 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 8,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isActive ? activeColor : inactiveColor,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                state.mode.name.toUpperCase(),
                key: ValueKey(state.mode),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

double _calculateProgress(PomodoroState state) {
  final total = switch (state.mode) {
    PomodoroMode.work => 25 * 60,
    PomodoroMode.shortBreak => 5 * 60,
    PomodoroMode.longBreak => state.longBreakDuration,
  };

  final remaining = state.remainingTime;
  return 1 - (remaining / total);
}

Color _getProgressColor(PomodoroState state) {
  final progress = _calculateProgress(state);
  if (progress < 0.5) {
    return Color.lerp(
      Colors.blue.shade200,
      Colors.blue.shade400,
      progress * 2,
    )!;
  } else {
    return Color.lerp(
      Colors.blue.shade500,
      const Color(0xff0045f3),
      (progress - 0.5) * 2,
    )!;
  }
}

Icon _getIconForMode(PomodoroMode mode) {
  const color = Color(0xff0045f3);
  switch (mode) {
    case PomodoroMode.work:
      return const Icon(Icons.laptop_mac, size: 32, color: color);
    case PomodoroMode.shortBreak:
      return const Icon(Icons.coffee, size: 32, color: color);
    case PomodoroMode.longBreak:
      return const Icon(Icons.bedtime_outlined, size: 32, color: color);
  }
}
