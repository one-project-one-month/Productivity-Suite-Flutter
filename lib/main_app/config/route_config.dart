import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:productivity_suite_flutter/budgets/pages/budgets_page.dart';
import 'package:productivity_suite_flutter/notes/category.dart';
import '../../auth/auth_screen.dart';
import '../../auth/register_screen.dart';
import '../../auth/auth_provider.dart';
import '../../pomodoro/pomodoro.dart';
import '../main_screen.dart';
import '../screens/views/to_do_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.matchedLocation;
      print('Router redirect check: location=$location, isInitialized=${authState.isInitialized}, isAuthenticated=${authState.isAuthenticated}');

      // Don't redirect while auth is being initialized
      if (!authState.isInitialized) {
        if (location != '/splash') {
          print('Not initialized, redirecting to splash');
          return '/splash';
        }
        return null;
      }

      final isLoggedIn = authState.isAuthenticated;
      final isOnAuthPage = location == '/login' || location == '/register';
      final isOnSplash = location == '/splash';

      // If on splash and initialized, redirect based on auth status
      if (isOnSplash) {
        return isLoggedIn ? '/' : '/login';
      }

      // If not logged in and not on auth pages, redirect to login
      if (!isLoggedIn && !isOnAuthPage) {
        print('Not logged in, redirecting to login');
        return '/login';
      }

      // If logged in and on auth pages, redirect to home
      if (isLoggedIn && isOnAuthPage) {
        print('Logged in on auth page, redirecting to home');
        return '/';
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(),
      ),
      GoRoute(
          path: '/login',
          builder: (context, state) => AuthScreen()
      ),
      GoRoute(
          path: '/register',
          builder: (context, state) => RegisterScreen()
      ),
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
                  return BudgetPage();
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// Simple splash screen for auth initialization
class SplashScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Add a fallback timeout in case auth initialization gets stuck
    _initWithTimeout();
  }

  void _initWithTimeout() async {
    // Wait for auth initialization with a timeout
    await Future.delayed(Duration(seconds: 5));

    // If still not initialized after timeout, force initialization
    final authState = ref.read(authProvider);
    if (!authState.isInitialized && mounted) {
      print('Auth initialization timeout, forcing redirect to login');
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isInitialized && mounted) {
        // Once initialized, the router redirect will handle navigation
        print('Auth initialized, letting router handle navigation');
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi, color: Colors.blue, size: 80),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Loading...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}