import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/section.dart';
import '../providers/pick_list_provider.dart';
import '../providers/section_providers.dart';
import '../services/haptics_service.dart';
import '../services/scanner_service.dart';
import 'pick_list_screen.dart';

/// Scanner screen for capturing barcodes and adding to pick list.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  late final MobileScannerService _scanner;
  late final HapticsService _haptics;
  String? _lastBarcode;
  Timer? _debounceTimer;
  bool _torchOn = false;
  int _quickQty = 1;

  @override
  void initState() {
    super.initState();
    _scanner = MobileScannerService();
    _haptics = HapticsService();
    _scanner.start(onScanned: _onBarcodeScanned);
  }

  void _onBarcodeScanned(String barcode) {
    // Debounce duplicates within 1.5 seconds.
    if (_lastBarcode == barcode && _debounceTimer?.isActive == true) {
      return;
    }
    _lastBarcode = barcode;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _lastBarcode = null;
    });
    _haptics.success();
    final section = ref.read(selectedSectionProvider);
    if (section != null) {
      ref.read(pickListProvider.notifier).addEntry(
        barcode,
        section.id,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $barcode'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              // Undo by removing the last entry with same barcode.
              final picks = ref.read(pickListProvider);
              final toRemove = picks.lastWhere(
                (p) => p.barcode == barcode,
                orElse: () => picks.isNotEmpty ? picks.last : null,
              );
              if (toRemove != null) {
                ref.read(pickListProvider.notifier).deleteEntry(toRemove);
              }
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scanner.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Section? section = ref.watch(selectedSectionProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(section?.name ?? 'Scanner'),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_off : Icons.flash_on),
            onPressed: () {
              setState(() {
                _torchOn = !_torchOn;
                _scanner.controller.toggleTorch();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PickListScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _scanner.controller,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      if (_quickQty > 1) _quickQty--;
                    });
                  },
                ),
                Text('$_quickQty', style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _quickQty++;
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ElevatedButton(
              onPressed: () async {
                // Prompt manual entry via dialog.
                final controller = TextEditingController();
                final result = await showDialog<String?>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Manual Entry'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Enter barcode',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, controller.text),
                          child: const Text('Add'),
                        ),
                      ],
                    );
                  },
                );
                if (result != null && result.isNotEmpty) {
                  final currentSection = ref.read(selectedSectionProvider);
                  if (currentSection != null) {
                    await ref.read(pickListProvider.notifier).addEntry(
                      result,
                      currentSection.id,
                    );
                  }
                }
              },
              child: const Text('Manual Entry'),
            ),
          ),
        ],
      ),
    );
  }
}