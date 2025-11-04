import 'package:flutter_test/flutter_test.dart';
import 'package:tj_restock_mvp/services/beverage_db_service.dart';

void main() {
  group('BeverageDbService - normalizeBarcode', () {
    late BeverageDbService service;

    setUp(() {
      service = BeverageDbService.instance;
    });

    test('normalizes 8-digit TJ barcode with 90 prefix', () {
      expect(service.normalizeBarcode('90606007'), '60600');
    });

    test('normalizes 8-digit TJ barcode with 00 prefix', () {
      expect(service.normalizeBarcode('00745734'), '74573');
    });

    test('handles barcodes with non-digit characters', () {
      expect(service.normalizeBarcode('abc-90606007-xyz'), '60600');
    });

    test('handles concatenated/long scans by taking last 8 digits', () {
      expect(service.normalizeBarcode('000090606007XX'), '60600');
    });

    test('handles 12-digit UPC by taking last 5 digits', () {
      expect(service.normalizeBarcode('041508800129'), '00129');
    });

    test('handles short codes as-is', () {
      expect(service.normalizeBarcode('12345'), '12345');
    });

    test('handles barcodes with spaces and dashes', () {
      expect(service.normalizeBarcode('90-606-007'), '60600');
    });
  });

  group('BeverageDbService - lookupByBarcode', () {
    late BeverageDbService service;

    setUp(() async {
      service = BeverageDbService.instance;
      // Seed test data
      await service.addOrUpdateUser('60600', 'STRAWBERRY RHUBARB SODA 4 PK');
      await service.addOrUpdateUser('74573', 'TEST PRODUCT');
    });

    test('returns product name for known barcode', () {
      final result = service.lookupByBarcode('90606007');
      expect(result, 'STRAWBERRY RHUBARB SODA 4 PK');
    });

    test('returns product name for barcode with 00 prefix', () {
      final result = service.lookupByBarcode('00745734');
      expect(result, 'TEST PRODUCT');
    });

    test('returns null for unknown barcode', () {
      final result = service.lookupByBarcode('99999999');
      expect(result, null);
    });

    test('handles barcodes with non-digits in lookup', () {
      final result = service.lookupByBarcode('abc-90606007-xyz');
      expect(result, 'STRAWBERRY RHUBARB SODA 4 PK');
    });
  });
}
