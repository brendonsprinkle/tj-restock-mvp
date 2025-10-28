import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Debounce prevents duplicate scan within 1.5s', () async {
    String? lastBarcode;
    Timer? debounceTimer;
    int count = 0;
    void onScan(String barcode) {
      if (lastBarcode == barcode && debounceTimer?.isActive == true) {
        return;
      }
      lastBarcode = barcode;
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 1500), () {
        lastBarcode = null;
      });
      count++;
    }

    // First scan should increment.
    onScan('abc');
    expect(count, 1);
    // Second scan within debounce window should be ignored.
    onScan('abc');
    expect(count, 1);
    // After debounce window, scan again should be accepted.
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    onScan('abc');
    expect(count, 2);
  });
}