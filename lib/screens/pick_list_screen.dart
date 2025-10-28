import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pick_entry.dart';
import '../providers/pick_list_provider.dart';
import '../providers/section_providers.dart';

/// Screen displaying the current pick list grouped by section.
class PickListScreen extends ConsumerWidget {
  const PickListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picks = ref.watch(pickListProvider);
    final sections = ref.watch(sectionsProvider).maybeWhen(data: (data) => data, orElse: () => []);
    final sectionMap = {for (final s in sections) s.id: s};
    final grouped = <String, List<PickEntry>>{};
    for (final pick in picks) {
      grouped.putIfAbsent(pick.sectionId, () => []).add(pick);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () async {
              final exportService = ref.read(exportServiceProvider);
              final csv = exportService.toCsv(picks);
              final path = await exportService.saveCsvToFile(csv);
              await exportService.shareCsvFile(path);
              // Ask if list should be cleared after export.
              final clear = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear after export?'),
                  content: const Text('Would you like to clear the pick list after exporting?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
                  ],
                ),
              );
              if (clear == true) {
                await ref.read(pickListProvider.notifier).clear();
              }
            },
          ),
        ],
      ),
      body: grouped.isEmpty
          ? const Center(child: Text('No items scanned yet.'))
          : ListView(
              children: grouped.entries.map((entry) {
                final sectionId = entry.key;
                final items = entry.value;
                final sectionName = sectionMap[sectionId]?.name ?? sectionId;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(sectionName, style: Theme.of(context).textTheme.titleLarge),
                    ),
                    ...items.map(
                      (item) => Dismissible(
                        key: ValueKey(item.id),
                        background: Container(color: Colors.red),
                        onDismissed: (_) {
                          ref.read(pickListProvider.notifier).deleteEntry(item);
                        },
                        child: ListTile(
                          title: Text(item.barcode),
                          subtitle: Text(item.labelText ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  if (item.qty > 1) {
                                    ref.read(pickListProvider.notifier).updateQty(item, item.qty - 1);
                                  }
                                },
                              ),
                              Text(item.qty.toString()),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  ref.read(pickListProvider.notifier).updateQty(item, item.qty + 1);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
    );
  }
}