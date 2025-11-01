import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/mobile_scanner_adapter.dart';
import '../services/haptics_service.dart';
import '../services/barcode_lookup_service.dart';
import '../state/app_state.dart';
import '../widgets/manual_entry_sheet.dart';

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

  void _handleScanResult(result) {
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
    final lookupService = BarcodeLookupService();
    final productName = lookupService.lookupBarcode(barcode);
    
    final displayText = productName ?? barcode;
    
    final notifier = ref.read(pickEntriesProvider.notifier);
    final added = await notifier.addEntry(
      barcodeOrText: displayText,
      labelText: productName != null ? null : barcode,
      sectionId: sectionId,
    );

    if (added) {
      await HapticsService.success();
      if (mounted) {
        final message = productName != null 
            ? 'Added: $productName'
            : 'Added: $barcode (unknown product)';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
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
  }

  void _showDuplicateChip(String barcode) {
    final selectedSection = ref.read(selectedSectionProvider);
    if (selectedSection == null) return;

    final notifier = ref.read(pickEntriesProvider.notifier);
    final entry = notifier.getEntryByBarcode(barcode, selectedSection.id);

    if (entry != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Already added: $barcode'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: '+1',
            onPressed: () {
              notifier.incrementQuantity(entry.id);
              HapticsService.light();
            },
          ),
        ),
      );
    }
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
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerAdapter.controller,
            onDetect: (capture) {
              if (capture.barcodes.isNotEmpty) {
                final barcode = capture.barcodes.first;
                if (barcode.rawValue != null) {
                  _handleScanResult(_scannerAdapter.results);
                }
              }
            },
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
