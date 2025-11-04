import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../services/beverage_db_service.dart';

class ViewEditDbScreen extends StatefulWidget {
  const ViewEditDbScreen({super.key});

  @override
  State<ViewEditDbScreen> createState() => _ViewEditDbScreenState();
}

class _ViewEditDbScreenState extends State<ViewEditDbScreen> {
  List<Map<String, dynamic>> _entries = [];
  Set<String> _baseSkus = {};

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries = BeverageDbService.instance.listEntries();
    final baseSkus = await _getBaseSkus();
    
    setState(() {
      _entries = entries;
      _baseSkus = baseSkus;
    });
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

  bool _isUserAdded(String sku) {
    return !_baseSkus.contains(sku);
  }

  void _editEntry(Map<String, dynamic> entry) {
    if (!_isUserAdded(entry['sku'])) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Base database entries cannot be edited'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final controller = TextEditingController(text: entry['product_name']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${entry['sku']}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                await BeverageDbService.instance.addOrUpdateUser(entry['sku'], value);
                await _loadEntries();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product updated'),
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteEntry(Map<String, dynamic> entry) {
    if (!_isUserAdded(entry['sku'])) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Base database entries cannot be deleted'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${entry['product_name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await BeverageDbService.instance.deleteUser(entry['sku']);
              await _loadEntries();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product deleted'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseEntries = _entries.where((e) => !_isUserAdded(e['sku'])).toList();
    final userEntries = _entries.where((e) => _isUserAdded(e['sku'])).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('View/Edit Database'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          if (baseEntries.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Base Beverage Database (Read-Only)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...baseEntries.map((entry) => ListTile(
              title: Text(entry['product_name']),
              subtitle: Text('SKU: ${entry['sku']}'),
              trailing: const Icon(Icons.lock, color: Colors.grey),
            )),
            const Divider(thickness: 2),
          ],
          if (userEntries.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Your Added Items (Editable)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...userEntries.map((entry) => ListTile(
              title: Text(entry['product_name']),
              subtitle: Text('SKU: ${entry['sku']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editEntry(entry),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteEntry(entry),
                  ),
                ],
              ),
            )),
          ] else if (baseEntries.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Your Added Items (Editable)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No user-added items yet. Scan unknown products to add them here.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
          if (_entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Database is empty',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
