import 'dart:io';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

class BarcodeLookupService {
  static final BarcodeLookupService _instance = BarcodeLookupService._internal();
  factory BarcodeLookupService() => _instance;
  BarcodeLookupService._internal();

  final Map<String, String> _barcodeDatabase = {};
  final Map<String, String> _userAddedDatabase = {};
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadBundledDatabase();
    await _loadUserAddedDatabase();
    
    _isInitialized = true;
  }

  Future<void> _loadBundledDatabase() async {
    try {
      final csvString = await rootBundle.loadString('assets/tj_barcodes.csv');
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);
      
      for (var i = 1; i < csvData.length; i++) {
        if (csvData[i].length >= 2) {
          final barcode = csvData[i][0].toString().trim();
          final productName = csvData[i][1].toString().trim();
          if (barcode.isNotEmpty && productName.isNotEmpty) {
            _barcodeDatabase[barcode] = productName;
          }
        }
      }
      
      print('Loaded ${_barcodeDatabase.length} products from bundled database');
    } catch (e) {
      print('Error loading bundled barcode database: $e');
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
          if (csvData[i].length >= 2) {
            final barcode = csvData[i][0].toString().trim();
            final productName = csvData[i][1].toString().trim();
            if (barcode.isNotEmpty && productName.isNotEmpty) {
              _userAddedDatabase[barcode] = productName;
            }
          }
        }
        
        print('Loaded ${_userAddedDatabase.length} user-added products');
      }
    } catch (e) {
      print('Error loading user-added database: $e');
    }
  }

  String? lookupBarcode(String barcode) {
    final normalizedBarcode = _normalizeBarcode(barcode);
    
    if (_userAddedDatabase.containsKey(normalizedBarcode)) {
      return _userAddedDatabase[normalizedBarcode];
    }
    
    if (_barcodeDatabase.containsKey(normalizedBarcode)) {
      return _barcodeDatabase[normalizedBarcode];
    }
    
    final paddedBarcode = normalizedBarcode.padLeft(8, '0');
    if (_barcodeDatabase.containsKey(paddedBarcode)) {
      return _barcodeDatabase[paddedBarcode];
    }
    
    if (normalizedBarcode.length > 8) {
      final truncatedBarcode = normalizedBarcode.substring(normalizedBarcode.length - 8);
      if (_barcodeDatabase.containsKey(truncatedBarcode)) {
        return _barcodeDatabase[truncatedBarcode];
      }
    }
    
    return null;
  }

  Future<void> addUserBarcode(String barcode, String productName) async {
    final normalizedBarcode = _normalizeBarcode(barcode);
    _userAddedDatabase[normalizedBarcode] = productName;
    
    await _saveUserAddedDatabase();
  }

  Future<void> _saveUserAddedDatabase() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/user_added.csv');
      
      final List<List<dynamic>> csvData = [
        ['barcode', 'product_name']
      ];
      
      _userAddedDatabase.forEach((barcode, productName) {
        csvData.add([barcode, productName]);
      });
      
      final csvString = const ListToCsvConverter().convert(csvData);
      await file.writeAsString(csvString);
      
      print('Saved ${_userAddedDatabase.length} user-added products');
    } catch (e) {
      print('Error saving user-added database: $e');
    }
  }

  String _normalizeBarcode(String barcode) {
    return barcode.replaceAll(RegExp(r'[^0-9]'), '');
  }

  int get totalProducts => _barcodeDatabase.length + _userAddedDatabase.length;
  int get bundledProducts => _barcodeDatabase.length;
  int get userAddedProducts => _userAddedDatabase.length;
}
