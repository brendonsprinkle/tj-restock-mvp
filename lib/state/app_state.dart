import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/pick_entry.dart';
import '../models/section.dart';
import '../services/db_service.dart';

final selectedSectionProvider = StateProvider<Section?>((ref) => null);

final pickEntriesProvider = StateNotifierProvider<PickEntriesNotifier, List<PickEntry>>((ref) {
  return PickEntriesNotifier();
});

final sectionsProvider = Provider<List<Section>>((ref) {
  return DbService.getAllSections();
});

final lastScannedBarcodeProvider = StateProvider<String?>((ref) => null);
final lastScannedTimeProvider = StateProvider<DateTime?>((ref) => null);

class PickEntriesNotifier extends StateNotifier<List<PickEntry>> {
  PickEntriesNotifier() : super([]) {
    _loadEntries();
  }

  void _loadEntries() {
    state = DbService.getAllPickEntries();
  }

  Future<bool> addEntry({
    required String barcodeOrText,
    String? labelText,
    required String sectionId,
    int qty = 1,
  }) async {
    final existingEntry = state.firstWhere(
      (entry) => entry.barcodeOrText == barcodeOrText && entry.sectionId == sectionId,
      orElse: () => PickEntry(
        id: '',
        barcodeOrText: '',
        sectionId: '',
        createdAt: DateTime.now(),
      ),
    );

    if (existingEntry.id.isNotEmpty) {
      return false;
    }

    final entry = PickEntry(
      id: const Uuid().v4(),
      barcodeOrText: barcodeOrText,
      labelText: labelText,
      sectionId: sectionId,
      qty: qty,
      createdAt: DateTime.now(),
    );

    await DbService.addPickEntry(entry);
    _loadEntries();
    return true;
  }

  Future<void> updateQuantity(String entryId, int newQty) async {
    final entry = state.firstWhere((e) => e.id == entryId);
    entry.qty = newQty;
    await DbService.updatePickEntry(entry);
    _loadEntries();
  }

  Future<void> incrementQuantity(String entryId) async {
    final entry = state.firstWhere((e) => e.id == entryId);
    entry.qty += 1;
    await DbService.updatePickEntry(entry);
    _loadEntries();
  }

  Future<void> decrementQuantity(String entryId) async {
    final entry = state.firstWhere((e) => e.id == entryId);
    if (entry.qty > 1) {
      entry.qty -= 1;
      await DbService.updatePickEntry(entry);
      _loadEntries();
    }
  }

  Future<void> deleteEntry(String entryId) async {
    await DbService.deletePickEntry(entryId);
    _loadEntries();
  }

  Future<void> clearAll() async {
    await DbService.clearAllPickEntries();
    _loadEntries();
  }

  PickEntry? getLastEntry() {
    if (state.isEmpty) return null;
    return state.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
  }

  bool hasEntryWithBarcode(String barcode, String sectionId) {
    return state.any((entry) => 
      entry.barcodeOrText == barcode && entry.sectionId == sectionId
    );
  }

  PickEntry? getEntryByBarcode(String barcode, String sectionId) {
    try {
      return state.firstWhere((entry) => 
        entry.barcodeOrText == barcode && entry.sectionId == sectionId
      );
    } catch (e) {
      return null;
    }
  }
}
