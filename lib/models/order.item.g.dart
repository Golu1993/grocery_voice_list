part of 'order_item.dart';

class OrderItemAdapter extends TypeAdapter<OrderItem> {
  @override
  final int typeId = 1;

  @override
  OrderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return OrderItem(
      time: fields[0] as String,
      storeName: fields[1] as String,
      itemCount: fields[2] as int,
      amount: (fields[3] as num).toDouble(),
      status: fields[4] as String,
      itemList: (fields[5] as List).cast<GroceryField>(),
      isExpanded: fields[6] as bool? ?? false,
      orderId: fields[7] as int? ??0,
      isCurrent: fields[8] as bool? ??true,
    );
  }

  @override
  void write(BinaryWriter writer, OrderItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.time)
      ..writeByte(1)
      ..write(obj.storeName)
      ..writeByte(2)
      ..write(obj.itemCount)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.itemList)
      ..writeByte(6)
      ..write(obj.isExpanded)
      ..writeByte(7)
      ..write(obj.orderId)
      ..writeByte(8)
      ..write(obj.isCurrent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is OrderItemAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}