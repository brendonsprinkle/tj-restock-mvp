import 'dart:io';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

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
      final csvString = await rootBundle.loadString('assets/TJ_Beverage_SKU_CSV.csv');
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);
      
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
    raw = raw.trim();
    
    if (raw.length == 8 && (raw.startsWith('00') || raw.startsWith('90'))) {
      return raw.substring(2, 7);
    }
    
    if (raw.length > 5) {
      return raw.substring(raw.length - 5);
    }
    
    return raw;
  }

  String? lookupByBarcode(String barcode) {
    final normalized = normalizeBarcode(barcode);
    return _database[normalized];
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
      final csvString = await rootBundle.loadString('assets/TJ_Beverage_SKU_CSV.csv');
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);
      
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
