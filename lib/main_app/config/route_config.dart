import 'package:go_router/go_router.dart';
import 'package:productivity_suite_flutter/budgets/budgets.dart';
import '../main_screen.dart';
import '../screens/views/notes_screen.dart';
import '../screens/views/pomodoro_screen.dart';
import '../screens/views/to_do_screen.dart';

final GoRouter routes = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) {
        return MainScreen(shell: shell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'home',
              path: '/',
              builder: (context, state) {
                return PomodoroScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'to_do',
              path: '/to_do',
              builder: (context, state) {
                String? name = state.uri.queryParameters['name'];
                return ToDoScreen(name: name!);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'notes',
              path: '/notes',
              builder: (context, state) {
                return NotesScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'budget_tracker',
              path: '/budget_tracker',
              builder: (context, state) {
                return BudgetPage();
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
