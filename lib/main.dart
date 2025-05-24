import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:productivity_suite_flutter/pomodoro/utils/shared_prefs_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_app/config/route_config.dart';
import 'notes/data/note.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await noteTakingSetup();
  final prefs = await SharedPreferences.getInstance();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

Future<void> noteTakingSetup() async {
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  Hive.registerAdapter(NoteTypeAdapter());
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(CategoryAdapter());
  await Hive.openBox<Category>('categoriesBox');
  await Hive.openBox<Note>('notesBox');
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
