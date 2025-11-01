import 'package:hive_flutter/hive_flutter.dart';
import '../models/pick_entry.dart';
import '../models/section.dart';

class DbService {
  static const String _pickEntriesBox = 'pick_entries';
  static const String _sectionsBox = 'sections';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    Hive.registerAdapter(SectionAdapter());
    Hive.registerAdapter(PickEntryAdapter());
    
    await Hive.openBox<PickEntry>(_pickEntriesBox);
    await Hive.openBox<Section>(_sectionsBox);
    
    await _initializeSections();
  }

  static Future<void> _initializeSections() async {
    final sectionsBox = Hive.box<Section>(_sectionsBox);
    
    if (sectionsBox.isEmpty) {
      final defaultSections = Section.getDefaultSections();
      for (var section in defaultSections) {
        await sectionsBox.put(section.id, section);
      }
    }
  }

  static Box<PickEntry> get pickEntriesBox => Hive.box<PickEntry>(_pickEntriesBox);
  static Box<Section> get sectionsBox => Hive.box<Section>(_sectionsBox);

  static Future<void> addPickEntry(PickEntry entry) async {
    await pickEntriesBox.put(entry.id, entry);
  }

  static Future<void> updatePickEntry(PickEntry entry) async {
    await pickEntriesBox.put(entry.id, entry);
  }

  static Future<void> deletePickEntry(String id) async {
    await pickEntriesBox.delete(id);
  }

  static List<PickEntry> getAllPickEntries() {
    return pickEntriesBox.values.toList();
  }

  static List<PickEntry> getPickEntriesBySection(String sectionId) {
    return pickEntriesBox.values
        .where((entry) => entry.sectionId == sectionId)
        .toList();
  }

  static Future<void> clearAllPickEntries() async {
    await pickEntriesBox.clear();
  }

  static List<Section> getAllSections() {
    return sectionsBox.values.toList();
  }

  static Section? getSectionById(String id) {
    return sectionsBox.get(id);
  }

  static PickEntry? getPickEntryByBarcode(String barcode, String sectionId) {
    return pickEntriesBox.values.firstWhere(
      (entry) => entry.barcodeOrText == barcode && entry.sectionId == sectionId,
      orElse: () => PickEntry(
        id: '',
        barcodeOrText: '',
        sectionId: '',
        createdAt: DateTime.now(),
      ),
    );
  }

  static bool hasPickEntryWithBarcode(String barcode, String sectionId) {
    return pickEntriesBox.values.any(
      (entry) => entry.barcodeOrText == barcode && entry.sectionId == sectionId,
    );
  }
}
