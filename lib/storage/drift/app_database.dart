import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/conversations_table.dart';
import 'tables/messages_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Messages, Conversations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

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
    },
  );
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'cao_im',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
      onResult: (result) {
        print(
          '[AppDatabase] Web database ready: ${result.chosenImplementation}',
        );
      },
    ),
    native: const DriftNativeOptions(
      shareAcrossIsolates: true,
    ),
  );
}
