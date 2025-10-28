import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/section.dart';
import '../services/db_service.dart';

/// Provides the list of sections loaded from the database.
final sectionsProvider = FutureProvider<List<Section>>((ref) async {
  final db = ref.read(dbServiceProvider);
  await db.init();
  final seeded = <Section>[
    Section(id: 'dry_produce', name: 'Dry Produce'),
    Section(id: 'wet_produce', name: 'Wet Produce'),
    Section(id: 'fresh', name: 'Fresh'),
    Section(id: 'milk_yogurt', name: 'Milk/Yogurt (Box)'),
    Section(id: 'meat', name: 'Meat'),
  ];
  await db.seedSections(seeded);
  return db.getAllSections();
});

/// Tracks the currently selected section.
final selectedSectionProvider = StateProvider<Section?>((ref) => null);

/// Provides access to the DB service.
final dbServiceProvider = Provider<DbService>((ref) => DbService());