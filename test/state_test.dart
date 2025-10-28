import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../lib/models/pick_entry.dart';
import '../lib/providers/pick_list_provider.dart';
import '../lib/services/db_service.dart';

void main() {
  test('PickListNotifier add/edit/delete', () async {
    final container = ProviderContainer(overrides: [
      dbServiceProvider.overrideWithValue(DbService()),
    ]);
    addTearDown(container.dispose);
    final notifier = container.read(pickListProvider.notifier);
    // Add entry.
    await notifier.addEntry('123', 'section1');
    expect(container.read(pickListProvider).length, 1);
    final entry = container.read(pickListProvider).first;
    // Update quantity.
    await notifier.updateQty(entry, 5);
    expect(container.read(pickListProvider).first.qty, 5);
    // Delete.
    await notifier.deleteEntry(entry);
    expect(container.read(pickListProvider), isEmpty);
  });
}