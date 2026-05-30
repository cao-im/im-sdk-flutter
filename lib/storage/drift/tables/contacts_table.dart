import 'package:drift/drift.dart';

class Contacts extends Table {
  IntColumn get id => integer()();

  TextColumn get username => text()();

  TextColumn get nickname => text().withDefault(const Constant(''))();

  TextColumn get avatar => text().withDefault(const Constant(''))();

  TextColumn get signature => text().nullable()();

  IntColumn get gender => integer().withDefault(const Constant(0))();

  TextColumn get location => text().withDefault(const Constant(''))();

  TextColumn get phone => text().withDefault(const Constant(''))();

  TextColumn get email => text().withDefault(const Constant(''))();

  IntColumn get onlineStatus => integer().withDefault(const Constant(0))();

  IntColumn get lastOnlineTime => integer().nullable()();

  TextColumn get remark => text().withDefault(const Constant(''))();

  IntColumn get status => integer().withDefault(const Constant(0))();

  IntColumn get source => integer().withDefault(const Constant(0))();

  IntColumn get createTime => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
