import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/section.dart';
import '../providers/section_providers.dart';
import 'scanner_screen.dart';

/// Screen allowing users to select a section before scanning.
class SectionsScreen extends ConsumerWidget {
  const SectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(sectionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Select Section')),
      body: sectionsAsync.when(
        data: (sections) => ListView.builder(
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            return ListTile(
              title: Text(section.name),
              onTap: () {
                ref.read(selectedSectionProvider.notifier).state = section;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ScannerScreen()),
                );
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading sections: $e')),
      ),
    );
  }
}