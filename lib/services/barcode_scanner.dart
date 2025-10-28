/// Abstraction for a barcode scanner. Allows swapping scanner implementations.
abstract class BarcodeScanner {
  /// Starts scanning and emits barcodes through a callback.
  void start({required Function(String barcode) onScanned});

  /// Pauses scanning.
  void pause();

  /// Resumes scanning.
  void resume();

  /// Disposes resources.
  void dispose();
}