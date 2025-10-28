import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/sections_screen.dart';

/// Entry point of the application.
void main() {
  runApp(const ProviderScope(child: TJRestockApp()));
}

/// Root widget that sets up theming and navigation.
class TJRestockApp extends StatelessWidget {
  const TJRestockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TJ Restock MVP',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SectionsScreen(),
    );
  }
}