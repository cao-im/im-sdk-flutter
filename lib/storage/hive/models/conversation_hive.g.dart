// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConversationHiveAdapter extends TypeAdapter<ConversationHive> {
  @override
  final int typeId = 1;

  @override
  ConversationHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConversationHive(
      id: fields[0] as int?,
      userId: fields[1] as int,
      targetType: fields[2] as int,
      targetId: fields[3] as int,
      lastMessage: fields[4] as MessageHive?,
      unreadCount: fields[5] as int,
      updateTime: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ConversationHive obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.targetType)
      ..writeByte(3)
      ..write(obj.targetId)
      ..writeByte(4)
      ..write(obj.lastMessage)
      ..writeByte(5)
      ..write(obj.unreadCount)
      ..writeByte(6)
      ..write(obj.updateTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
