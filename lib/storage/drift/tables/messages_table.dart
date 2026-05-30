import 'package:drift/drift.dart';

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get mid => integer().nullable()();

  IntColumn get fromId => integer()();

  IntColumn get toId => integer()();

  IntColumn get groupId => integer().nullable()();

  TextColumn get content => text()();

  IntColumn get msgType => integer()();

  IntColumn get status => integer()();

  IntColumn get timestamp => integer()();

  TextColumn get localPath => text().nullable()();

  IntColumn get msgSeq => integer().withDefault(const Constant(0))();

  IntColumn get replyMsgId => integer().nullable()();

  TextColumn get atUserIds => text().withDefault(const Constant(''))();

  TextColumn get extra => text().nullable()();

  IntColumn get readStatus => integer().withDefault(const Constant(0))();
}
