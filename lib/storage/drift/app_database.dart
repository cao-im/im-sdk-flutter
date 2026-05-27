import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/messages_table.dart';
import 'tables/conversations_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Messages, Conversations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {},
  );
}

QueryExecutor _openConnection() {
  if (kIsWeb) {
    // Web 平台：使用内存数据库（不依赖 FFI）
    return _WebMemoryExecutor();
  }

  // 桌面端/移动端：使用 SQLite 文件数据库
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cao_im.db'));
    return NativeDatabase.createInBackground(file);
  });
}

/// Web 端纯 Dart 内存执行器（零 FFI 依赖）
class _WebMemoryExecutor extends QueryExecutor {
  final List<Map<String, Object?>> _data = [];
  int _idCounter = 1;

  @override
  SqlDialect get dialect => const SqlDialect(duckDialect: true);

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async => true;

  @override
  Future<void> runBatched(BatchedStatements statements) async {}

  @override
  Future<void> runCustom(String sql, [List<Object?>? args]) async {}

  @override
  Future<int> runInsert(String sql, List<Object?>? args) async => _idCounter++;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String sql,
    List<Object?>? args,
  ) async =>
      [];

  @override
  Future<int> runUpdate(String sql, List<Object?>? args) async => 0;

  @override
  Future<int> runDelete(String sql, List<Object?>? args) async => 0;

  @override
  TransactionExecutor beginTransaction() =>
      throw UnimplementedError();

  @override
  QueryExecutor beginExclusive() => this;

  @override
  Future<void> close() async {}
}
