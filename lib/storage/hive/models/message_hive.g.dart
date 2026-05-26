// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageHiveAdapter extends TypeAdapter<MessageHive> {
  @override
  final int typeId = 0;

  @override
  MessageHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageHive(
      id: fields[0] as int?,
      fromId: fields[1] as int,
      toId: fields[2] as int,
      groupId: fields[3] as int?,
      content: fields[4] as String,
      msgType: fields[5] as int,
      status: fields[6] as int,
      timestamp: fields[7] as int,
      localPath: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MessageHive obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fromId)
      ..writeByte(2)
      ..write(obj.toId)
      ..writeByte(3)
      ..write(obj.groupId)
      ..writeByte(4)
      ..write(obj.content)
      ..writeByte(5)
      ..write(obj.msgType)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.timestamp)
      ..writeByte(8)
      ..write(obj.localPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
