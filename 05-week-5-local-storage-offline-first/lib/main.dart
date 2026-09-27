import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/notes_page.dart';

import 'data/prefs.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefsRepository().markOpenedNow();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Week 5 - Local Storage & Offline-First',
        theme: ThemeData(
            colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const NotesPage(),
      );
}