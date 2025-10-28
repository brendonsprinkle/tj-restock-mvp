import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/pick_entry.dart';

/// Handles CSV export and sharing. Also writes a backup file to the documents directory.
class ExportService {
  /// Converts the list of [PickEntry] to CSV string.
  String toCsv(List<PickEntry> picks) {
    final headers = [
      'id',
      'barcode',
      'labelText',
      'sectionId',
      'qty',
      'createdAt',
    ];
    final rows = [headers];
    for (final pick in picks) {
      rows.add([
        pick.id,
        pick.barcode,
        pick.labelText ?? '',
        pick.sectionId,
        pick.qty.toString(),
        pick.createdAt.toIso8601String(),
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }

  /// Saves the CSV to a file in the documents directory and returns the file path.
  Future<String> saveCsvToFile(String csv) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/pick_list_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  /// Shares the CSV file via the platform share sheet.
  Future<void> shareCsvFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'Pick list export');
  }
}