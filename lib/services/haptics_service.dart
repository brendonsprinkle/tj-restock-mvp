import 'package:flutter/services.dart';

/// Provides haptic feedback for user interactions.
class HapticsService {
  /// Vibrates lightly to indicate success (e.g., barcode scanned).
  Future<void> success() async {
    await HapticFeedback.lightImpact();
  }
}