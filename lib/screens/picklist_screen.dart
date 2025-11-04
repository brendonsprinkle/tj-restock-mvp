import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pick_entry.dart';
import '../services/export_service.dart';
import '../services/haptics_service.dart';
import '../services/db_service.dart';
import '../state/app_state.dart';

class PickListScreen extends ConsumerStatefulWidget {
  const PickListScreen({super.key});

  @override
  ConsumerState<PickListScreen> createState() => _PickListScreenState();
}

class _PickListScreenState extends ConsumerState<PickListScreen> {
  bool _isExporting = false;
  bool _clearAfterExport = false;

  Future<void> _exportCsv() async {
    setState(() {
      _isExporting = true;
    });

    final entries = ref.read(pickEntriesProvider);
    
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No items to export'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {
        _isExporting = false;
      });
      return;
    }

    final result = await ExportService.exportCsv(entries);

    setState(() {
      _isExporting = false;
    });

    if (result.success) {
      await HapticsService.success();
      
      if (mounted) {
        final message = result.sharedSuccessfully
            ? 'CSV exported successfully!'
            : result.message ?? 'Saved to Files';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        if (_clearAfterExport) {
          await ref.read(pickEntriesProvider.notifier).clearAll();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pick list cleared'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Export failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, List<PickEntry>> _groupBySection(List<PickEntry> entries) {
    final Map<String, List<PickEntry>> grouped = {};
    
    for (var entry in entries) {
      if (!grouped.containsKey(entry.sectionId)) {
        grouped[entry.sectionId] = [];
      }
      grouped[entry.sectionId]!.add(entry);
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(pickEntriesProvider);
    final groupedEntries = _groupBySection(entries);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick List'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All?'),
                    content: const Text('This will remove all items from the pick list.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(pickEntriesProvider.notifier).clearAll();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pick list cleared')),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No items in pick list',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView(
              children: [
                ...groupedEntries.entries.map((group) {
                  final section = DbService.getSectionById(group.key);
                  final sectionName = section?.name ?? group.key;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        color: Colors.grey.shade200,
                        child: Text(
                          sectionName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...group.value.map((entry) => _buildEntryTile(entry)),
                    ],
                  );
                }),
                const SizedBox(height: 100),
              ],
            ),
      bottomSheet: entries.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text('Clear after export'),
                    value: _clearAfterExport,
                    onChanged: (value) {
                      setState(() {
                        _clearAfterExport = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportCsv,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.file_download),
                      label: Text(_isExporting ? 'Exporting...' : 'Export CSV'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildEntryTile(PickEntry entry) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        ref.read(pickEntriesProvider.notifier).deleteEntry(entry.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed: ${entry.labelText ?? entry.barcodeOrText}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: ListTile(
        title: Text(entry.labelText ?? entry.barcodeOrText),
        subtitle: Text(entry.barcodeOrText),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () async {
                if (entry.qty > 1) {
                  ref.read(pickEntriesProvider.notifier).decrementQuantity(entry.id);
                  HapticsService.light();
                } else {
                  // Capture entry data before deletion for Undo
                  final barcode = entry.barcodeOrText;
                  final label = entry.labelText;
                  final sectionId = entry.sectionId;
                  
                  // Delete the entry
                  await ref.read(pickEntriesProvider.notifier).deleteEntry(entry.id);
                  await HapticsService.success();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed: ${label ?? barcode}'),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () async {
                            await ref.read(pickEntriesProvider.notifier).addEntry(
                              barcodeOrText: barcode,
                              labelText: label,
                              sectionId: sectionId,
                              qty: 1,
                            );
                            HapticsService.success();
                          },
                        ),
                      ),
                    );
                  }
                }
              },
            ),
            Text(
              '${entry.qty}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                ref.read(pickEntriesProvider.notifier).incrementQuantity(entry.id);
                HapticsService.light();
              },
            ),
          ],
        ),
      ),
    );
  }
}
