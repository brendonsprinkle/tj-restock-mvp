import 'package:hive/hive.dart';

part 'pick_entry.g.dart';

@HiveType(typeId: 1)
class PickEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String barcodeOrText;

  @HiveField(2)
  final String? labelText;

  @HiveField(3)
  final String sectionId;

  @HiveField(4)
  int qty;

  @HiveField(5)
  final DateTime createdAt;

  PickEntry({
    required this.id,
    required this.barcodeOrText,
    this.labelText,
    required this.sectionId,
    this.qty = 1,
    required this.createdAt,
  });

  PickEntry copyWith({
    String? id,
    String? barcodeOrText,
    String? labelText,
    String? sectionId,
    int? qty,
    DateTime? createdAt,
  }) {
    return PickEntry(
      id: id ?? this.id,
      barcodeOrText: barcodeOrText ?? this.barcodeOrText,
      labelText: labelText ?? this.labelText,
      sectionId: sectionId ?? this.sectionId,
      qty: qty ?? this.qty,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
