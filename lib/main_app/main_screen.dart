import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  Widget build(BuildContext context) {
    StatefulNavigationShell shell = widget.shell;
    return Scaffold(
      body: Column(children: [Expanded(child: shell)]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) {
          shell.goBranch(index);
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.access_time),
            label: 'Pomodoro',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist),
            label: 'To Do List',
          ),
          NavigationDestination(icon: Icon(Icons.note), label: 'Notes'),
          NavigationDestination(
            icon: Icon(Icons.attach_money),
            label: 'Budget Tracker',
          ),
        ],
      ),
    );
  }
}
