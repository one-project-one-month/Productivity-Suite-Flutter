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
        backgroundColor: Colors.white,
        surfaceTintColor: const Color(0xff0045f3),
        indicatorColor: const Color(0xff0045f3),
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) {
          shell.goBranch(index);
        },
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.access_time,
              color: shell.currentIndex == 0 ? Colors.white : null,
            ),
            label: 'Pomodoro',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.checklist,
              color: shell.currentIndex == 1 ? Colors.white : null,
            ),
            label: 'To Do List',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.note,
              color: shell.currentIndex == 2 ? Colors.white : null,
            ),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.attach_money,
              color: shell.currentIndex == 3 ? Colors.white : null,
            ),
            label: 'Budget Tracker',
          ),
        ],
      ),
    );
  }
}
