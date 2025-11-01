abstract class BarcodeScanner {
  Stream<ScanResult> get results;
  Future<void> start();
  Future<void> stop();
  Future<void> dispose();
  Future<void> toggleTorch();
  bool get isTorchOn;
}

class ScanResult {
  final String barcode;
  final String format;
  final DateTime timestamp;

  ScanResult({
    required this.barcode,
    required this.format,
    required this.timestamp,
  });
}
