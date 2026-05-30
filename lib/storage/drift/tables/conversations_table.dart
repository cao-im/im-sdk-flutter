import 'package:drift/drift.dart';

class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get userId => integer()();

  IntColumn get targetType => integer()();

  IntColumn get targetId => integer()();

  IntColumn get unreadCount => integer().withDefault(const Constant(0))();

  IntColumn get updateTime => integer()();

  TextColumn get lastMessageContent => text().nullable()();

  IntColumn get lastMessageType => integer().nullable()();

  IntColumn get lastMessageStatus => integer().nullable()();

  IntColumn get lastMessageTimestamp => integer().nullable()();

  IntColumn get lastMessageFromId => integer().nullable()();

  IntColumn get lastMessageToId => integer().nullable()();

  IntColumn get lastMessageGroupId => integer().nullable()();

  TextColumn get lastMessageLocalPath => text().nullable()();

  IntColumn get lastMsgId => integer().nullable()();

  IntColumn get isTop => integer().withDefault(const Constant(0))();

  IntColumn get isMute => integer().withDefault(const Constant(0))();

  IntColumn get isDeleted => integer().withDefault(const Constant(0))();

  TextColumn get draftContent => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {userId, targetType, targetId},
  ];
}
