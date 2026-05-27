import 'package:drift/drift.dart';

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get fromId => integer()();

  IntColumn get toId => integer()();

  IntColumn get groupId => integer().nullable()();

  TextColumn get content => text()();

  IntColumn get msgType => integer()();

  IntColumn get status => integer()();

  IntColumn get timestamp => integer()();

  TextColumn get localPath => text().nullable()();
}
