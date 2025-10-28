import 'dart:async';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'barcode_scanner.dart';

/// Implementation of [BarcodeScanner] using the `mobile_scanner` package.
class MobileScannerService implements BarcodeScanner {
  MobileScannerService();

  final MobileScannerController _controller = MobileScannerController();
  StreamSubscription<BarcodeCapture>? _subscription;

  @override
  void start({required Function(String barcode) onScanned}) {
    _subscription?.cancel();
    _subscription = _controller.barcodes.listen((capture) {
      for (final barcode in capture.barcodes) {
        final String? value = barcode.displayValue;
        if (value != null) {
          onScanned(value);
        }
      }
    });
  }

  @override
  void pause() => _controller.stop();

  @override
  void resume() => _controller.start();

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
  }

  /// Exposes the controller to the UI for preview and torch control.
  MobileScannerController get controller => _controller;
}