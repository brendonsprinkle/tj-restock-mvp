import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import 'barcode_scanner.dart';

class MobileScannerAdapter implements BarcodeScanner {
  final ms.MobileScannerController _controller;
  final StreamController<ScanResult> _resultsController = StreamController<ScanResult>.broadcast();
  bool _isTorchOn = false;

  MobileScannerAdapter()
      : _controller = ms.MobileScannerController(
          detectionSpeed: ms.DetectionSpeed.normal,
          facing: ms.CameraFacing.back,
          torchEnabled: false,
        ) {
    _controller.barcodes.listen((capture) {
      if (capture.barcodes.isNotEmpty) {
        final barcode = capture.barcodes.first;
        if (barcode.rawValue != null) {
          _resultsController.add(ScanResult(
            barcode: barcode.rawValue!,
            format: barcode.format.name,
            timestamp: DateTime.now(),
          ));
        }
      }
    });
  }

  @override
  Stream<ScanResult> get results => _resultsController.stream;

  @override
  Future<void> start() async {
    await _controller.start();
  }

  @override
  Future<void> stop() async {
    await _controller.stop();
  }

  @override
  Future<void> dispose() async {
    await _controller.dispose();
    await _resultsController.close();
  }

  @override
  Future<void> toggleTorch() async {
    _isTorchOn = !_isTorchOn;
    await _controller.toggleTorch();
  }

  @override
  bool get isTorchOn => _isTorchOn;

  ms.MobileScannerController get controller => _controller;
}
