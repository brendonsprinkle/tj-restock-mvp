import 'package:flutter/foundation.dart';

/// Debug logging helper that only prints in debug mode
/// Keeps release builds clean and performant
void dlog(String message) {
  if (kDebugMode) {
    print(message);
  }
}
