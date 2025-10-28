import 'package:hive/hive.dart';

part 'section.g.dart';

/// Represents a store section where items are found.
@HiveType(typeId: 0)
class Section extends HiveObject {
  Section({required this.id, required this.name});

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @override
  String toString() => 'Section(id: $id, name: $name)';
}