import 'package:flutter/services.dart';

class HapticsService {
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
  }

  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }
}
