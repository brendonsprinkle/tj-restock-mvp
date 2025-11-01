import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/db_service.dart';
import 'screens/sections_screen.dart';
import 'screens/picklist_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await DbService.init();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TJ Restock MVP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const SectionsScreen(),
      routes: {
        '/picklist': (context) => const PickListScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
