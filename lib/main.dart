import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:productivity_suite_flutter/budgets/providers/category_provider.dart';
import 'package:productivity_suite_flutter/budgets/providers/transcation_provider.dart';
import 'package:provider/provider.dart' as provider;
import 'main_app/config/route_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  runApp(
    ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider(
            create: (_) => CategoryProvider()..getCategories(),
          ),
          provider.ChangeNotifierProvider(
            create: (_) => TranscationProvider()..getTranscations(),
          ),
        ],
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Productivity Suite',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: routes,
    );
  }
}
