import 'package:hive/hive.dart';

part 'pick_entry.g.dart';

/// Represents an entry in the pick list.
@HiveType(typeId: 1)
class PickEntry extends HiveObject {
  PickEntry({
    required this.id,
    required this.barcode,
    this.labelText,
    required this.sectionId,
    this.qty = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String barcode;

  @HiveField(2)
  final String? labelText;

  @HiveField(3)
  final String sectionId;

  @HiveField(4)
  int qty;

  @HiveField(5)
  final DateTime createdAt;

  /// Increase quantity by 1.
  void increment() => qty++;

  /// Decrease quantity by 1. Minimum is 1.
  void decrement() {
    if (qty > 1) {
      qty--;
    }
  }
}