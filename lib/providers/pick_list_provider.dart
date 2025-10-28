import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/pick_entry.dart';
import '../services/db_service.dart';
import 'section_providers.dart';
import '../services/export_service.dart';

final _uuid = const Uuid();

/// Provider for the export service.
final exportServiceProvider = Provider<ExportService>((ref) => ExportService());

/// State notifier for managing the pick list.
class PickListNotifier extends StateNotifier<List<PickEntry>> {
  PickListNotifier(this._db) : super([]) {
    loadFromDb();
  }

  final DbService _db;

  Future<void> loadFromDb() async {
    await _db.init();
    state = _db.getAllPicks();
  }

  Future<void> addEntry(String barcode, String sectionId, {String? labelText}) async {
    final entry = PickEntry(
      id: _uuid.v4(),
      barcode: barcode,
      labelText: labelText,
      sectionId: sectionId,
    );
    await _db.addPick(entry);
    state = [...state, entry];
  }

  Future<void> updateQty(PickEntry entry, int qty) async {
    entry.qty = qty;
    await _db.updatePick(entry);
    state = [for (final e in state) if (e.id == entry.id) entry else e];
  }

  Future<void> deleteEntry(PickEntry entry) async {
    await _db.deletePick(entry.id);
    state = state.where((e) => e.id != entry.id).toList();
  }

  Future<void> clear() async {
    await _db.clearPicks();
    state = [];
  }
}

final pickListProvider = StateNotifierProvider<PickListNotifier, List<PickEntry>>((ref) {
  final db = ref.read(dbServiceProvider);
  return PickListNotifier(db);
});