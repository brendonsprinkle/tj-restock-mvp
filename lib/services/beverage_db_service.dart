import 'dart:io';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/debug_log.dart';

class BeverageDbService {
  static final BeverageDbService _instance = BeverageDbService._internal();
  factory BeverageDbService() => _instance;
  static BeverageDbService get instance => _instance;
  
  BeverageDbService._internal();

  final Map<String, String> _database = {};
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    await _loadBaseDatabase();
    await _loadUserAddedDatabase();
    
    _isInitialized = true;
  }

  Future<void> _loadBaseDatabase() async {
    try {
      final raw = await rootBundle.loadString('assets/TJ_Beverage_SKU_CSV.csv');
      print('CSV raw length: ${raw.length} chars');
      
      final csvString = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      final List<List<dynamic>> csvData = const CsvToListConverter(eol: '\n').convert(csvString);
      
      print('CSV parsed rows (including header): ${csvData.length}');
      
      for (var i = 1; i < csvData.length; i++) {
        if (csvData[i].isEmpty) continue;
        
        if (csvData[i].length >= 2) {
          final sku = csvData[i].last.toString().trim();
          final productParts = csvData[i].sublist(0, csvData[i].length - 1);
          final productName = productParts.join(',').trim();
          
          if (sku.isNotEmpty && productName.isNotEmpty) {
            _database[sku] = productName;
          }
        }
      }
      
      print('Loaded ${_database.length} products from base beverage database');
      print('Has SKU 60600? ${_database.containsKey('60600')}');
      if (_database.containsKey('60600')) {
        print('60600 maps to: ${_database['60600']}');
      }
    } catch (e) {
      print('Error loading base beverage database: $e');
    }
  }

  Future<void> _loadUserAddedDatabase() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/user_added.csv');
      
      if (await file.exists()) {
        final csvString = await file.readAsString();
        final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);
        
        for (var i = 1; i < csvData.length; i++) {
          if (csvData[i].isEmpty) continue;
          
          if (csvData[i].length >= 2) {
            final sku = csvData[i][0].toString().trim();
            final productName = csvData[i][1].toString().trim();
            
            if (sku.isNotEmpty && productName.isNotEmpty) {
              _database[sku] = productName;
            }
          }
        }
        
        print('Loaded user-added products from user_added.csv');
      }
    } catch (e) {
      print('Error loading user-added database: $e');
    }
  }

  String normalizeBarcode(String raw) {
    final original = raw;
    raw = raw.trim();
    
    // Clean non-digits first (handles barcodes with dashes, spaces, etc.)
    String cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Handle concatenated/long scans by taking last 8 digits
    if (cleaned.length > 8) {
      cleaned = cleaned.substring(cleaned.length - 8);
    }
    
    String normalized;
    String branch;
    
    // TJ private-label 8-digit barcodes: extract middle 5 digits
    if (cleaned.length == 8 && (cleaned.startsWith('00') || cleaned.startsWith('90'))) {
      normalized = cleaned.substring(2, 7);
      branch = '8-digit TJ';
    }
    // Fallback: take last 5 digits for longer codes
    else if (cleaned.length > 5) {
      normalized = cleaned.substring(cleaned.length - 5);
      branch = 'last-5 fallback';
    }
    // Short codes: use as-is
    else {
      normalized = cleaned;
      branch = 'short code';
    }
    
    dlog('Scan Debug: raw="$original", cleaned="$cleaned", normalized="$normalized", branch=$branch');
    return normalized;
  }

  String? lookupByBarcode(String barcode) {
    final normalized = normalizeBarcode(barcode);
    final name = _database[normalized];
    
    if (name != null) {
      dlog('DB Hit: $normalized -> $name');
    } else {
      dlog('DB Miss: $normalized');
    }
    
    return name;
  }

  Future<void> addOrUpdateUser(String sku, String productName) async {
    _database[sku] = productName;
    await _saveUserAddedDatabase();
  }

  Future<void> deleteUser(String sku) async {
    _database.remove(sku);
    await _saveUserAddedDatabase();
  }

  Future<void> _saveUserAddedDatabase() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/user_added.csv');
      
      final List<List<dynamic>> csvData = [
        ['sku', 'product_name']
      ];
      
      final baseSkus = await _getBaseSkus();
      
      _database.forEach((sku, productName) {
        if (!baseSkus.contains(sku)) {
          csvData.add([sku, productName]);
        }
      });
      
      final csvString = const ListToCsvConverter().convert(csvData);
      await file.writeAsString(csvString);
      
      print('Saved ${csvData.length - 1} user-added products');
    } catch (e) {
      print('Error saving user-added database: $e');
    }
  }

  Future<Set<String>> _getBaseSkus() async {
    final Set<String> baseSkus = {};
    
    try {
      final raw = await rootBundle.loadString('assets/TJ_Beverage_SKU_CSV.csv');
      final csvString = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      final List<List<dynamic>> csvData = const CsvToListConverter(eol: '\n').convert(csvString);
      
      for (var i = 1; i < csvData.length; i++) {
        if (csvData[i].isEmpty) continue;
        
        if (csvData[i].length >= 2) {
          final sku = csvData[i].last.toString().trim();
          if (sku.isNotEmpty) {
            baseSkus.add(sku);
          }
        }
      }
    } catch (e) {
      print('Error loading base SKUs: $e');
    }
    
    return baseSkus;
  }

  List<Map<String, dynamic>> listEntries() {
    final List<Map<String, dynamic>> entries = [];
    
    _database.forEach((sku, productName) {
      entries.add({
        'sku': sku,
        'product_name': productName,
      });
    });
    
    entries.sort((a, b) => a['product_name'].compareTo(b['product_name']));
    
    return entries;
  }

  int get totalProducts => _database.length;
}
