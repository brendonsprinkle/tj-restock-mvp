import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/pick_entry.dart';
import 'db_service.dart';

class ExportService {
  static Future<String> generateCsv(List<PickEntry> entries) async {
    final List<List<dynamic>> rows = [
      ['timestamp', 'section', 'barcode_or_text', 'label', 'qty']
    ];

    for (var entry in entries) {
      final section = DbService.getSectionById(entry.sectionId);
      final sectionName = section?.name ?? entry.sectionId;
      
      rows.add([
        entry.createdAt.toIso8601String(),
        sectionName,
        entry.barcodeOrText,
        entry.labelText ?? '',
        entry.qty,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  static Future<ExportResult> exportCsv(List<PickEntry> entries) async {
    try {
      final csvContent = await generateCsv(entries);
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'tj_restock_$timestamp.csv';

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);
      await file.writeAsString(csvContent);

      try {
        final xFile = XFile(filePath);
        await Share.shareXFiles([xFile], text: 'TJ Restock Pick List');
        
        return ExportResult(
          success: true,
          filePath: filePath,
          sharedSuccessfully: true,
        );
      } catch (shareError) {
        return ExportResult(
          success: true,
          filePath: filePath,
          sharedSuccessfully: false,
          message: 'File saved to: $filePath',
        );
      }
    } catch (e) {
      return ExportResult(
        success: false,
        message: 'Export failed: $e',
      );
    }
  }

  static Future<String?> getLastExportPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);
      final files = dir.listSync()
          .where((file) => file.path.endsWith('.csv') && file.path.contains('tj_restock_'))
          .toList();
      
      if (files.isEmpty) return null;
      
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return files.first.path;
    } catch (e) {
      return null;
    }
  }
}

class ExportResult {
  final bool success;
  final String? filePath;
  final bool sharedSuccessfully;
  final String? message;

  ExportResult({
    required this.success,
    this.filePath,
    this.sharedSuccessfully = false,
    this.message,
  });
}
