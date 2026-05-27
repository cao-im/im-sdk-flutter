import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../model/message.dart' as model;
import '../../model/conversation.dart' as model_conv;
import '../storage_interface.dart';
import 'app_database.dart';

class DriftStorage implements StorageInterface {
  late AppDatabase _db;
  bool _isInitialized = false;

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    print('[DriftStorage] 🗄️ 初始化 Drift (SQLite) 本地存储...');
try {
      _db = AppDatabase();

      print('[DriftStorage] ✅ 初始化完成');
      print('[DriftStorage] 📊 Schema 版本: ${_db.schemaVersion}');

      if (kIsWeb) {
        print('[DriftStorage] 🌐 Web 平台: 内存模式');
      } else if (Platform.isWindows) {
        print('[DriftStorage] 💻 Windows 平台: NativeDatabase (文件持久化)');
      } else if (Platform.isLinux) {
        print('[DriftStorage] 💻 Linux 平台: NativeDatabase (文件持久化)');
      } else if (Platform.isMacOS) {
        print('[DriftStorage] 💻 macOS 平台: NativeDatabase (文件持久化)');
      } else if (Platform.isAndroid) {
        print('[DriftStorage] 📱 Android 平台: NativeDatabase (文件持久化)');
      } else if (Platform.isIOS) {
        print('[DriftStorage] 📱 iOS 平台: NativeDatabase (文件持久化)');
      }

      _isInitialized = true;
    } catch (e, stackTrace) {
      print('[DriftStorage] ❌ 初始化失败: $e');
      print('[DriftStorage] 📍 堆栈: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<int> insertMessage(model.Message message) async {
    final messageCompanion = MessagesCompanion.insert(
      fromId: message.fromId,
      toId: message.toId,
      groupId: Value(message.groupId),
      content: message.content,
      msgType: message.msgType.value,
      status: message.status.value,
      timestamp: message.timestamp,
      localPath: Value(message.localPath),
    );

    return await _db.into(_db.messages).insert(messageCompanion);
  }

  @override
  Future<List<model.Message>> getMessages({
    required int targetId,
    int? groupId,
    int? currentUserId,
    int page = 1,
    int size = 20,
  }) async {
    final query = _db.select(_db.messages);

    if (groupId != null) {
      query.where((tbl) => tbl.groupId.equals(groupId));
    } else {
      final userId = currentUserId ?? 0;
      query.where((tbl) =>
          (tbl.fromId.equals(targetId) & tbl.toId.equals(userId)) |
          (tbl.fromId.equals(userId) & tbl.toId.equals(targetId)));
    }

    query.orderBy([(t) => OrderingTerm.asc(t.timestamp)]);
    query.limit(size, offset: (page - 1) * size);

    final rows = await query.get();
    return rows.map((row) => _toMessage(row)).toList();
  }

  @override
  Future<model.Message?> getLastMessage(int targetId, {int? groupId}) async {
    late final List<Message> result;

    if (groupId != null) {
      result = await (_db.select(_db.messages)
            ..where((tbl) => tbl.groupId.equals(groupId))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
            ..limit(1))
          .get();
    } else {
      result = await (_db.select(_db.messages)
            ..where((tbl) =>
                tbl.fromId.equals(targetId) | tbl.toId.equals(targetId))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
            ..limit(1))
          .get();
    }

    if (result.isEmpty) return null;
    return _toMessage(result.first);
  }

  @override
  Future<model.Message?> getMessageById(int messageId) async {
    final row = await (_db.select(_db.messages)
          ..where((tbl) => tbl.id.equals(messageId)))
        .getSingleOrNull();

    if (row == null) return null;
    return _toMessage(row);
  }

  @override
  Future<void> updateMessageStatus(
      int messageId, model.MessageStatus status) async {
    await (_db.update(_db.messages)..where((tbl) => tbl.id.equals(messageId)))
        .write(MessagesCompanion(status: Value(status.value)));
  }

  @override
  Future<void> updateMessageContent(
      int messageId, String content, model.MessageStatus status) async {
    await (_db.update(_db.messages)..where((tbl) => tbl.id.equals(messageId)))
        .write(MessagesCompanion(
              content: Value(content),
              status: Value(status.value),
            ));
  }

  @override
  Future<int> getUnreadCount(int userId) async {
    final rows = await (_db.selectOnly(_db.conversations)
          ..addColumns([_db.conversations.unreadCount])
          ..where(_db.conversations.userId.equals(userId)))
        .get();

    return rows.fold<int>(0, (sum, row) => sum + (row.read(_db.conversations.unreadCount) ?? 0));
  }

  @override
  Future<void> markAsRead(int userId, {int? groupId}) async {
    if (groupId != null) {
      await (_db.update(_db.messages)
            ..where((tbl) =>
                tbl.groupId.equals(groupId) &
                tbl.toId.equals(userId) &
                tbl.status.isSmallerThan(Constant(model.MessageStatus.read.value))))
          .write(MessagesCompanion(status: Value(model.MessageStatus.read.value)));
    } else {
      await (_db.update(_db.conversations)
            ..where((tbl) => tbl.userId.equals(userId)))
          .write(ConversationsCompanion(unreadCount: Value(0)));
    }
  }

  @override
  Future<int> insertConversation(model_conv.Conversation conversation) async {
    final convCompanion = ConversationsCompanion.insert(
      userId: conversation.userId,
      targetType: conversation.targetType.value,
      targetId: conversation.targetId,
      unreadCount: Value(conversation.unreadCount),
      updateTime: conversation.updateTime,
    );

    return await _db.into(_db.conversations).insert(convCompanion);
  }

  @override
  Future<List<model_conv.Conversation>> getConversations(int userId) async {
    final query = _db.select(_db.conversations);

    if (userId != 0) {
      query.where((tbl) => tbl.userId.equals(userId));
    }

    query.orderBy([(t) => OrderingTerm.desc(t.updateTime)]);

    final rows = await query.get();
    return rows.map((row) => _toConversation(row)).toList();
  }

  @override
  Future<void> updateConversation(model_conv.Conversation conversation) async {
    if (conversation.id == null || conversation.id! <= 0) return;

    await (_db.update(_db.conversations)..where((tbl) => tbl.id.equals(conversation.id!)))
        .write(ConversationsCompanion(
              updateTime: Value(DateTime.now().millisecondsSinceEpoch),
              unreadCount: Value(conversation.unreadCount),
            ));
  }

  @override
  Future<void> updateUnreadCount(int conversationId, int count) async {
    await (_db.update(_db.conversations)..where((tbl) => tbl.id.equals(conversationId)))
        .write(ConversationsCompanion(unreadCount: Value(count)));
  }

  @override
  Future<void> deleteConversation(int conversationId) async {
    await (_db.delete(_db.conversations)..where((tbl) => tbl.id.equals(conversationId))).go();

    print('[DriftStorage] 🗑️ 会话已删除: id=$conversationId');
  }

  @override
  Future<void> close() async {
    if (_isInitialized) {
      await _db.close();
      _isInitialized = false;
      print('[DriftStorage] ✓ 连接已关闭');
    }
  }

  model.Message _toMessage(Message row) {
    return model.Message(
      id: row.id,
      fromId: row.fromId,
      toId: row.toId,
      groupId: row.groupId,
      content: row.content,
      msgType: model.MessageType.fromValue(row.msgType),
      status: model.MessageStatus.fromValue(row.status),
      timestamp: row.timestamp,
      localPath: row.localPath,
    );
  }

  model_conv.Conversation _toConversation(Conversation row) {
    return model_conv.Conversation(
      id: row.id,
      userId: row.userId,
      targetType: model_conv.TargetType.fromValue(row.targetType),
      targetId: row.targetId,
      unreadCount: row.unreadCount,
      updateTime: row.updateTime,
    );
  }
}
