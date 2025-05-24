import 'package:go_router/go_router.dart';
import 'package:productivity_suite_flutter/notes/category.dart';
import '../../auth/auth_screen.dart';
import '../../auth/register_screen.dart';
import '../../pomodoro/pomodoro.dart';
import '../main_screen.dart';
import '../screens/views/budget_tracker_screen.dart';
import '../screens/views/main_pomodoro_screen.dart';
import '../screens/views/to_do_screen.dart';

final GoRouter routes = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => AuthScreen()),
    GoRoute(path: '/register', builder: (context, state) => RegisterScreen()),
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
                return Pomodoro();
              },
            ),
          ],
        ),
        /*StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'pomodoro',
              path: '/pomodoro',
              builder: (context, state) {
                return Pomodoro();
              },
            ),
          ],
        ),*/
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'to_do',
              path: '/to_do',
              builder: (context, state) {
                return ToDoScreen();
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
                return CategoryScreen();
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
                return BudgetTrackerScreen();
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
