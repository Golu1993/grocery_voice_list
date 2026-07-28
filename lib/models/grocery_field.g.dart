
part of 'grocery_field.dart';
class GroceryFieldAdapter extends TypeAdapter<GroceryField> {
  @override
  final int typeId = 2;

  @override
  GroceryField read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return GroceryField(
      name: fields[0] as String,
      quantity: (fields[1] as num).toDouble(),
      unit: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GroceryField obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.unit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is GroceryFieldAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}