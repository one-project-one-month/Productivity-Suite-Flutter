
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(authProvider.notifier).logout();
                if (mounted) {
                  context.go('/login');
                }
              },
              child: Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

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
          if (index == 4) {
            // Logout button tapped
            _showLogoutDialog();
          } else {
            shell.goBranch(index);
          }
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
              color: shell.currentIndex == 3? Colors.white : null,
            ),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.logout,
              color: Colors.red,
            ),
            label: 'Logout',
          ),
        ],
      ),
    );
  }
}
