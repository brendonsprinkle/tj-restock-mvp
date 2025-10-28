import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/section.dart';
import '../models/pick_entry.dart';

/// Keys for Hive boxes.
const String kSectionsBox = 'sections_box';
const String kPicksBox = 'picks_box';

/// Database service for sections and pick entries using Hive.
class DbService {
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    // Register adapters if not already registered.
    if (!Hive.isAdapterRegistered(SectionAdapter().typeId)) {
      Hive.registerAdapter(SectionAdapter());
    }
    if (!Hive.isAdapterRegistered(PickEntryAdapter().typeId)) {
      Hive.registerAdapter(PickEntryAdapter());
    }
    await Hive.openBox<Section>(kSectionsBox);
    await Hive.openBox<PickEntry>(kPicksBox);
    _initialized = true;
  }

  Box<Section> get _sectionsBox => Hive.box<Section>(kSectionsBox);
  Box<PickEntry> get _picksBox => Hive.box<PickEntry>(kPicksBox);

  /// Returns a list of all sections.
  List<Section> getAllSections() {
    return _sectionsBox.values.toList();
  }

  /// Seeds default sections if none exist.
  Future<void> seedSections(List<Section> sections) async {
    if (_sectionsBox.isEmpty) {
      await _sectionsBox.addAll(sections);
    }
  }

  /// Adds a pick entry.
  Future<void> addPick(PickEntry entry) async {
    await _picksBox.put(entry.id, entry);
  }

  /// Updates an existing pick entry.
  Future<void> updatePick(PickEntry entry) async {
    await entry.save();
  }

  /// Removes a pick entry by key.
  Future<void> deletePick(String id) async {
    await _picksBox.delete(id);
  }

  /// Clears all picks.
  Future<void> clearPicks() async {
    await _picksBox.clear();
  }

  /// Returns all pick entries.
  List<PickEntry> getAllPicks() {
    return _picksBox.values.toList();
  }
}