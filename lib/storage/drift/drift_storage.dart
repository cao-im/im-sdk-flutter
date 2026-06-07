import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/widgets.dart';

import '../../model/conversation.dart' as model_conv;
import '../../model/message.dart' as model;
import '../storage_interface.dart';
import 'app_database.dart';

class DriftStorage implements StorageInterface {
  late AppDatabase _db;
  int? _currentUserId;
  bool _isInitialized = false;

  @override
  Future<void> init({int? userId}) async {
    if (_isInitialized && _currentUserId == userId) return;

    if (_isInitialized && _currentUserId != userId) {
      print('[DriftStorage] 🔄 切换账号: $_currentUserId -> $userId, 关闭旧连接');
      await close();
    }

    print('[DriftStorage] 🗄️ 初始化 Drift (SQLite) 本地存储... (userId=$userId)');
    try {
      if (userId == null) {
        throw ArgumentError('userId 不能为空，必须指定当前登录用户');
      }
      _currentUserId = userId;
      _db = AppDatabase(userId);

      print('[DriftStorage] ✅ 初始化完成');
      print('[DriftStorage] 📊 Schema 版本: ${_db.schemaVersion}');

      if (kIsWeb) {
        print('[DriftStorage] 🌐 Web 平台: WasmDatabase (持久化)');
      } else {
        print('[DriftStorage] ${_platformLabel()} 平台: NativeDatabase (文件持久化)');
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
      mid: Value(message.mid ?? 0),
      fromId: message.fromId,
      toId: message.toId,
      groupId: Value(message.groupId),
      content: message.content,
      msgType: message.msgType.value,
      status: message.status.value,
      timestamp: message.timestamp,
      localPath: Value(message.localPath),
    );

    return _db.into(_db.messages).insert(messageCompanion);
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
  Future<model.Message?> getMessageByMid(int mid) async {
    final row = await (_db.select(_db.messages)
          ..where((tbl) => tbl.mid.equals(mid)))
        .getSingleOrNull();

    if (row == null) return null;
    return _toMessage(row);
  }

  @override
  Future<void> updateMessage(model.Message message) async {
    if (message.id == null) return;
    await (_db.update(_db.messages)..where((tbl) => tbl.id.equals(message.id!)))
        .write(MessagesCompanion(
              id: Value(message.id!),
              mid: Value(message.mid ?? 0),
              status: Value(message.status.value),
            ));
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
  Future<void> markAsRead(int userId, {int? targetId, int? groupId}) async {
    if (groupId != null) {
      await (_db.update(_db.messages)
            ..where((tbl) =>
                tbl.groupId.equals(groupId) &
                tbl.toId.equals(userId) &
                tbl.status.isSmallerThan(Constant(model.MessageStatus.read.value))))
          .write(MessagesCompanion(status: Value(model.MessageStatus.read.value)));
      await (_db.update(_db.conversations)
            ..where((tbl) =>
                tbl.userId.equals(userId) &
                tbl.targetType.equals(model_conv.TargetType.group.value) &
                tbl.targetId.equals(groupId)))
          .write(const ConversationsCompanion(unreadCount: Value(0)));
    } else if (targetId != null) {
      await (_db.update(_db.messages)
            ..where((tbl) =>
                ((tbl.fromId.equals(targetId) & tbl.toId.equals(userId)) |
                    (tbl.fromId.equals(userId) & tbl.toId.equals(targetId))) &
                tbl.groupId.isNull() &
                tbl.status.isSmallerThan(Constant(model.MessageStatus.read.value))))
          .write(MessagesCompanion(status: Value(model.MessageStatus.read.value)));

      await (_db.update(_db.conversations)
            ..where((tbl) =>
                tbl.userId.equals(userId) &
                tbl.targetType.equals(model_conv.TargetType.private.value) &
                tbl.targetId.equals(targetId)))
          .write(const ConversationsCompanion(unreadCount: Value(0)));
    }
  }

  @override
  Future<int> insertConversation(model_conv.Conversation conversation) async {
    print('[DriftStorage] 📝 insertConversation 被调用: userId=${conversation.userId}, targetId=${conversation.targetId}, targetType=${conversation.targetType.value}');

    final convCompanion = ConversationsCompanion.insert(
      userId: conversation.userId,
      targetType: conversation.targetType.value,
      targetId: conversation.targetId,
      unreadCount: Value(conversation.unreadCount),
      updateTime: conversation.updateTime,
      lastMessageContent: Value(conversation.lastMessage?.content),
      lastMessageType: Value(conversation.lastMessage?.msgType.value),
      lastMessageStatus: Value(conversation.lastMessage?.status.value),
      lastMessageTimestamp: Value(conversation.lastMessage?.timestamp),
      lastMessageFromId: Value(conversation.lastMessage?.fromId),
      lastMessageToId: Value(conversation.lastMessage?.toId),
      lastMessageGroupId: Value(conversation.lastMessage?.groupId),
      lastMessageLocalPath: Value(conversation.lastMessage?.localPath),
    );

    try {
      final id = await _db.into(_db.conversations).insert(convCompanion);
      print('[DriftStorage] ✅ insertConversation 成功: 会话ID=$id');
      return id;
    } catch (e, stackTrace) {
      print('[DriftStorage] ❌ insertConversation 失败: $e');
      print('[DriftStorage] 📍 堆栈: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<model_conv.Conversation>> getConversations(int userId) async {
    print('[DriftStorage] 🔍 getConversations 被调用: userId=$userId');

    final query = _db.select(_db.conversations);

    if (userId != 0) {
      query.where((tbl) =>
          tbl.userId.equals(userId) &
          tbl.isDeleted.equals(0));
    } else {
      query.where((tbl) => tbl.isDeleted.equals(0));
    }

    query.orderBy([(t) => OrderingTerm.desc(t.updateTime)]);

    final rows = await query.get();
    print('[DriftStorage] ✅ getConversations 完成: 找到 ${rows.length} 个会话（已排除已删除记录）');

    return rows.map((row) => _toConversation(row)).toList();
  }

  @override
  Future<void> updateConversation(model_conv.Conversation conversation) async {
    if (conversation.id == null || conversation.id! <= 0) return;

    await (_db.update(_db.conversations)..where((tbl) => tbl.id.equals(conversation.id!)))
        .write(ConversationsCompanion(
              updateTime: Value(conversation.updateTime),
              unreadCount: Value(conversation.unreadCount),
              lastMessageContent: Value(conversation.lastMessage?.content),
              lastMessageType: Value(conversation.lastMessage?.msgType.value),
              lastMessageStatus: Value(conversation.lastMessage?.status.value),
              lastMessageTimestamp: Value(conversation.lastMessage?.timestamp),
              lastMessageFromId: Value(conversation.lastMessage?.fromId),
              lastMessageToId: Value(conversation.lastMessage?.toId),
              lastMessageGroupId: Value(conversation.lastMessage?.groupId),
              lastMessageLocalPath: Value(conversation.lastMessage?.localPath),
            ));
  }

  @override
  Future<void> updateUnreadCount(int conversationId, int count) async {
    await (_db.update(_db.conversations)..where((tbl) => tbl.id.equals(conversationId)))
        .write(ConversationsCompanion(unreadCount: Value(count)));
  }

  @override
  Future<void> deleteConversation(int conversationId) async {
    await (_db.update(_db.conversations)..where((tbl) => tbl.id.equals(conversationId)))
        .write(const ConversationsCompanion(isDeleted: Value(1)));

    print('[DriftStorage] 🗑️ 会话已标记为已删除（软删除）: id=$conversationId');
  }

  @override
  Future<void> close() async {
    if (_isInitialized) {
      await _db.close();
      _isInitialized = false;
      print('[DriftStorage] ✓ 连接已关闭');
    }
  }

  /// 暴露底层 AppDatabase 实例（供需要直接操作数据库的组件复用连接）
  AppDatabase get appDatabase => _db;

  model.Message _toMessage(Message row) {
    return model.Message(
      id: row.id,
      mid: row.mid,
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
      lastMessage: _buildLastMessage(row),
      unreadCount: row.unreadCount,
      updateTime: row.updateTime,
    );
  }

  model.Message? _buildLastMessage(Conversation row) {
    final timestamp = row.lastMessageTimestamp;
    final content = row.lastMessageContent;
    final msgType = row.lastMessageType;
    final status = row.lastMessageStatus;
    final fromId = row.lastMessageFromId;
    final toId = row.lastMessageToId;

    if (timestamp == null ||
        content == null ||
        msgType == null ||
        status == null ||
        fromId == null ||
        toId == null) {
      return null;
    }

    return model.Message(
      fromId: fromId,
      toId: toId,
      groupId: row.lastMessageGroupId,
      content: content,
      msgType: model.MessageType.fromValue(msgType),
      status: model.MessageStatus.fromValue(status),
      timestamp: timestamp,
      localPath: row.lastMessageLocalPath,
    );
  }

  String _platformLabel() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '📱 Android';
      case TargetPlatform.iOS:
        return '📱 iOS';
      case TargetPlatform.macOS:
        return '💻 macOS';
      case TargetPlatform.windows:
        return '💻 Windows';
      case TargetPlatform.linux:
        return '💻 Linux';
      case TargetPlatform.fuchsia:
        return '🧪 Fuchsia';
    }
  }
}
