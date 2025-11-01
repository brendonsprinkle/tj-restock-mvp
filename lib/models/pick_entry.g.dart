// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pick_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PickEntryAdapter extends TypeAdapter<PickEntry> {
  @override
  final int typeId = 1;

  @override
  PickEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PickEntry(
      id: fields[0] as String,
      barcodeOrText: fields[1] as String,
      labelText: fields[2] as String?,
      sectionId: fields[3] as String,
      qty: fields[4] as int,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PickEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.barcodeOrText)
      ..writeByte(2)
      ..write(obj.labelText)
      ..writeByte(3)
      ..write(obj.sectionId)
      ..writeByte(4)
      ..write(obj.qty)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PickEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
