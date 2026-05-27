import 'package:drift/drift.dart';

class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get userId => integer()();

  IntColumn get targetType => integer()();

  IntColumn get targetId => integer()();

  IntColumn get unreadCount => integer().withDefault(const Constant(0))();

  IntColumn get updateTime => integer()();
}
