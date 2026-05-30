import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'tables/contacts_table.dart';
import 'tables/conversations_table.dart';
import 'tables/messages_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Messages, Conversations, Contacts])
class AppDatabase extends _$AppDatabase {
  final int userId;

  AppDatabase(this.userId) : super(_openConnection(userId));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(conversations, conversations.lastMessageContent);
        await m.addColumn(conversations, conversations.lastMessageType);
        await m.addColumn(conversations, conversations.lastMessageStatus);
        await m.addColumn(conversations, conversations.lastMessageTimestamp);
        await m.addColumn(conversations, conversations.lastMessageFromId);
        await m.addColumn(conversations, conversations.lastMessageToId);
        await m.addColumn(conversations, conversations.lastMessageGroupId);
        await m.addColumn(conversations, conversations.lastMessageLocalPath);
      }
      if (from < 3) {
        await m.createTable(contacts);
        await m.addColumn(messages, messages.msgSeq);
        await m.addColumn(messages, messages.replyMsgId);
        await m.addColumn(messages, messages.atUserIds);
        await m.addColumn(messages, messages.extra);
        await m.addColumn(messages, messages.readStatus);
        await m.addColumn(conversations, conversations.lastMsgId);
        await m.addColumn(conversations, conversations.isTop);
        await m.addColumn(conversations, conversations.isMute);
        await m.addColumn(conversations, conversations.isDeleted);
        await m.addColumn(conversations, conversations.draftContent);
      }
      if (from < 4) {
        await m.addColumn(messages, messages.mid);
      }
    },
  );
}

String _getDbName(int userId) {
  return 'cao_im_u$userId';
}

QueryExecutor _openConnection(int userId) {
  try {
    final dbName = _getDbName(userId);

    final db = driftDatabase(
      name: dbName,
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
        onResult: (result) {
          print(
            '[AppDatabase] Web database ready: ${result.chosenImplementation}',
          );
        },
      ),
      native: DriftNativeOptions(
        shareAcrossIsolates: !kDebugMode,
      ),
    );

    print('[AppDatabase] ✅ 数据库连接创建成功 (dbName=$dbName, userId=$userId)');
    print('[AppDatabase] 🔍 Debug模式: $kDebugMode');
    print('[AppDatabase] 🔍 shareAcrossIsolates: ${!kDebugMode}');

    return db;
  } catch (e, stackTrace) {
    print('[AppDatabase] ❌ 数据库连接创建失败: $e');
    print('[AppDatabase] 📍 错误类型: ${e.runtimeType}');
    print('[AppDatabase] 📍 堆栈: $stackTrace');
    rethrow;
  }
}
