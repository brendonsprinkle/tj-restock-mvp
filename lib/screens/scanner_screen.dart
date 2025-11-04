import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/mobile_scanner_adapter.dart';
import '../services/barcode_scanner.dart';
import '../services/haptics_service.dart';
import '../services/beverage_db_service.dart';
import '../state/app_state.dart';
import '../widgets/manual_entry_sheet.dart';
import '../utils/debug_log.dart';
import 'view_edit_db_screen.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  late MobileScannerAdapter _scannerAdapter;
  StreamSubscription? _scanSubscription;
  bool _isTorchOn = false;
  String? _lastScannedBarcode;
  DateTime? _lastScanTime;
  bool _dialogOpen = false;
  static const Duration _debounceDuration = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _scannerAdapter = MobileScannerAdapter();
    _initScanner();
  }

  Future<void> _initScanner() async {
    await _scannerAdapter.start();
    _scanSubscription = _scannerAdapter.results.listen(_handleScanResult);
  }

  void _handleScanResult(ScanResult result) {
    if (_dialogOpen) return;
    
    final barcode = result.barcode;
    final now = DateTime.now();

    if (_lastScannedBarcode == barcode &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < _debounceDuration) {
      _showDuplicateChip(barcode);
      return;
    }

    _lastScannedBarcode = barcode;
    _lastScanTime = now;

    final selectedSection = ref.read(selectedSectionProvider);
    if (selectedSection == null) {
      _showError('Please select a section first');
      return;
    }

    final notifier = ref.read(pickEntriesProvider.notifier);
    final hasEntry = notifier.hasEntryWithBarcode(barcode, selectedSection.id);

    if (hasEntry) {
      _showDuplicateChip(barcode);
    } else {
      _addEntry(barcode, selectedSection.id);
    }
  }

  Future<void> _addEntry(String barcode, String sectionId) async {
    final beverageDb = BeverageDbService.instance;
    final productName = beverageDb.lookupByBarcode(barcode);
    
    if (productName != null) {
      final notifier = ref.read(pickEntriesProvider.notifier);
      final added = await notifier.addEntry(
        barcodeOrText: barcode,
        labelText: productName,
        sectionId: sectionId,
      );

      if (added) {
        await HapticsService.success();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added: $productName'),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  final lastEntry = notifier.getLastEntry();
                  if (lastEntry != null) {
                    notifier.deleteEntry(lastEntry.id);
                  }
                },
              ),
            ),
          );
        }
      }
    } else {
      _showFastManualEntry(barcode, sectionId);
    }
  }

  void _showFastManualEntry(String barcode, String sectionId) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unknown Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Barcode: $barcode'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                hintText: 'Enter product name',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) async {
                if (value.trim().isNotEmpty) {
                  final normalized = BeverageDbService.instance.normalizeBarcode(barcode);
                  await BeverageDbService.instance.addOrUpdateUser(normalized, value.trim());
                  
                  final notifier = ref.read(pickEntriesProvider.notifier);
                  await notifier.addEntry(
                    barcodeOrText: barcode,
                    labelText: value.trim(),
                    sectionId: sectionId,
                  );
                  
                  await HapticsService.success();
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added: ${value.trim()}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                final normalized = BeverageDbService.instance.normalizeBarcode(barcode);
                await BeverageDbService.instance.addOrUpdateUser(normalized, value);
                
                final notifier = ref.read(pickEntriesProvider.notifier);
                await notifier.addEntry(
                  barcodeOrText: barcode,
                  labelText: value,
                  sectionId: sectionId,
                );
                
                await HapticsService.success();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added: $value'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDuplicateChip(String barcode) {
    final selectedSection = ref.read(selectedSectionProvider);
    if (selectedSection == null) return;

    final notifier = ref.read(pickEntriesProvider.notifier);
    final entry = notifier.getEntryByBarcode(barcode, selectedSection.id);

    if (entry != null && mounted) {
      _showQuantityDialog(entry.labelText ?? entry.barcodeOrText, entry.id);
    }
  }

  void _showQuantityDialog(String productName, String entryId) {
    _dialogOpen = true;
    
    // Get current quantity to pre-fill the dialog
    final entries = ref.read(pickEntriesProvider);
    final entry = entries.firstWhere((e) => e.id == entryId);
    final currentQty = entry.qty;
    
    dlog('QuantityDialog: opened for $productName/$entryId (current qty=$currentQty)');
    final controller = TextEditingController(text: currentQty.toString());
    
    // Helper to handle setting total quantity with validation
    Future<void> handleSetQuantity(int? newTotal) async {
      if (newTotal == null) {
        dlog('QuantityDialog: invalid quantity (null)');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid number'),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }
      
      if (newTotal < 0) {
        dlog('QuantityDialog: invalid quantity (negative)');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quantity cannot be negative'),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }
      
      if (newTotal == 0) {
        // Delete item with Undo (restores previous quantity)
        dlog('QuantityDialog: delete via qty=0 (previous qty=$currentQty)');
        final notifier = ref.read(pickEntriesProvider.notifier);
        final entries = ref.read(pickEntriesProvider);
        final entry = entries.firstWhere((e) => e.id == entryId);
        
        final barcode = entry.barcodeOrText;
        final label = entry.labelText;
        final sectionId = entry.sectionId;
        final prevQty = entry.qty;
        
        await notifier.deleteEntry(entryId);
        await HapticsService.success();
        _dialogOpen = false;
        Navigator.pop(context);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed: ${label ?? barcode}'),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  dlog('QuantityDialog: undo delete (restoring qty=$prevQty)');
                  await notifier.addEntry(
                    barcodeOrText: barcode,
                    labelText: label,
                    sectionId: sectionId,
                    qty: prevQty,
                  );
                  HapticsService.success();
                },
              ),
            ),
          );
        }
        return;
      }
      
      if (newTotal > 0) {
        if (newTotal == currentQty) {
          // No change, just close dialog
          dlog('QuantityDialog: no change (qty=$currentQty)');
          _dialogOpen = false;
          Navigator.pop(context);
          return;
        }
        
        dlog('QuantityDialog: set total qty=$newTotal (was $currentQty)');
        final notifier = ref.read(pickEntriesProvider.notifier);
        await notifier.updateQuantity(entryId, newTotal);
        await HapticsService.success();
        _dialogOpen = false;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Set quantity to $newTotal'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(productName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How many total? (0 to delete)'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Total Quantity',
                hintText: '0 to delete',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) async {
                final qty = int.tryParse(value);
                await handleSetQuantity(qty);
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    dlog('QuantityDialog: set to 1');
                    await handleSetQuantity(1);
                  },
                  child: const Text('1'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    dlog('QuantityDialog: set to 2');
                    await handleSetQuantity(2);
                  },
                  child: const Text('2'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    dlog('QuantityDialog: set to 5');
                    await handleSetQuantity(5);
                  },
                  child: const Text('5'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              dlog('QuantityDialog: cancel');
              _dialogOpen = false;
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(controller.text);
              await handleSetQuantity(qty);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleTorch() async {
    await _scannerAdapter.toggleTorch();
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
    await HapticsService.light();
  }

  void _showManualEntry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ManualEntrySheet(),
    );
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scannerAdapter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedSection = ref.watch(selectedSectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedSection?.name ?? 'Scanner'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.pushNamed(context, '/picklist');
            },
            tooltip: 'View Pick List',
          ),
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ViewEditDbScreen(),
                ),
              );
            },
            tooltip: 'View/Edit Database',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerAdapter.controller,
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Point camera at barcode',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: 'torch',
                  onPressed: _toggleTorch,
                  backgroundColor: _isTorchOn ? Colors.yellow : Colors.white,
                  child: Icon(
                    _isTorchOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.black,
                  ),
                ),
                FloatingActionButton.extended(
                  heroTag: 'manual',
                  onPressed: _showManualEntry,
                  backgroundColor: Colors.blue,
                  icon: const Icon(Icons.keyboard),
                  label: const Text('Manual Entry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
