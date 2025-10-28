import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

import '../lib/models/pick_entry.dart';
import '../lib/services/export_service.dart';

void main() {
  test('CSV round trip and autosave', () async {
    final service = ExportService();
    final entries = [
      PickEntry(id: '1', barcode: 'abc', sectionId: 's', labelText: 'Label1'),
      PickEntry(id: '2', barcode: 'def', sectionId: 's', labelText: 'Label2'),
    ];
    final csv = service.toCsv(entries);
    // Save and read back.
    final path = await service.saveCsvToFile(csv);
    final file = File(path);
    expect(await file.exists(), isTrue);
    final content = await file.readAsString();
    final rows = const CsvToListConverter().convert(content);
    // 3 rows: header + 2 entries.
    expect(rows.length, 3);
    expect(rows[1][1], 'abc');
  });
}