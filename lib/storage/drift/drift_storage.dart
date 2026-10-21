import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/widgets.dart';

import '../../model/conversation.dart' as model_conv;
import '../../model/message.dart' as model;
import '../../utils/id_literal.dart';
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

      await _removeDuplicateMessages();
      await _ensureMessageIdentityIndexes();
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
      seq: Value(message.seq),
      fromId: message.fromId,
      toId: message.toId,
      groupId: Value(message.groupId),
      content: message.content,
      msgType: message.msgType.value,
      status: message.status.value,
      delivered: Value(message.delivered),
      timestamp: message.timestamp,
      localPath: Value(message.localPath),
      senderNickname: Value(message.senderNickname),
      senderAvatar: Value(message.senderAvatar),
      replyMsgId: Value(message.replyMsgId),
      atUserIds: Value(message.atUserIds ?? ''),
      extra: Value(_encodeReplyExtra(message)),
      midRaw: Value(message.midKey),
      seqRaw: Value(message.seqKey),
    );

    return _db.into(_db.messages).insert(messageCompanion);
  }

  @override
  Future<bool> saveIncomingMessage(model.Message message) async {
    final existing = await _findSameMessage(message);
    if (existing != null) {
      await _backfillIdentity(existing, message);
      return false;
    }
    await insertMessage(message);
    return true;
  }

  Future<model.Message?> _findSameMessage(model.Message message) async {
    final key = message.midKey;
    if (key == null) return null;
    return getMessageByMidKey(key);
  }

  Future<void> _backfillIdentity(model.Message existing, model.Message incoming) async {
    final localId = existing.id;
    final midKey = incoming.midKey;
    final seqKey = incoming.seqKey;
    if (localId == null) return;
    final sameMid = midKey == null || midKey == existing.midKey;
    final sameSeq = seqKey == null || seqKey == existing.seqKey;
    if (sameMid && sameSeq) return;

    await (_db.update(_db.messages)..where((tbl) => tbl.id.equals(localId))).write(
      MessagesCompanion(
        midRaw: midKey == null ? const Value.absent() : Value(midKey),
        seqRaw: seqKey == null ? const Value.absent() : Value(seqKey),
        seq: incoming.seq == null ? const Value.absent() : Value(incoming.seq),
      ),
    );
  }

  Future<void> _removeDuplicateMessages() async {
    final rows = await (_db.select(_db.messages)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final seen = <String>{};
    final removeIds = <int>[];
    for (final row in rows) {
      final keys = <String>[];
      if (row.mid > 0) keys.add('i${row.mid}');
      final raw = row.midRaw;
      if (raw != null && IdLiteral.isPositive(raw)) keys.add('s$raw');
      if (keys.isEmpty) continue;
      if (keys.any(seen.contains)) {
        removeIds.add(row.id);
        continue;
      }
      seen.addAll(keys);
    }
    if (removeIds.isEmpty) return;

    const chunkSize = 200;
    for (var start = 0; start < removeIds.length; start += chunkSize) {
      final end = start + chunkSize < removeIds.length ? start + chunkSize : removeIds.length;
      final chunk = removeIds.sublist(start, end);
      await (_db.delete(_db.messages)..where((tbl) => tbl.id.isIn(chunk))).go();
    }
    print('[DriftStorage] 已清理重复消息 ${removeIds.length} 条');
  }

  Future<void> _ensureMessageIdentityIndexes() async {
    try {
      await _db.customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_messages_mid ON messages (mid) WHERE mid > 0',
      );
      await _db.customStatement(
        "CREATE UNIQUE INDEX IF NOT EXISTS idx_messages_mid_raw ON messages (mid_raw) WHERE mid_raw IS NOT NULL AND mid_raw != ''",
      );
    } catch (e) {
      print('[DriftStorage] 消息唯一索引未建立: $e');
    }
  }

  @override
  Future<List<model.Message>> searchMessages({
    required String keyword,
    required int currentUserId,
    int limit = 50,
  }) async {
    final text = keyword.trim().replaceAll('%', '').replaceAll('_', '');
    if (text.isEmpty) return [];
    final safeLimit = limit.clamp(1, 50);
    final rows = await (_db.select(_db.messages)
          ..where((tbl) =>
              tbl.content.like('%$text%') &
              tbl.msgType.isIn(const [0, 2]) &
              tbl.status.equals(-2).not())
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(safeLimit))
        .get();
    return rows.map(_toMessage).toList();
  }

  @override
  Future<List<model.Message>> listMediaMessages({int limit = 500}) async {
    final safeLimit = limit.clamp(1, 500);
    final rows = await (_db.select(_db.messages)
          ..where((tbl) =>
              tbl.msgType.isIn(const [1, 2, 4]) & tbl.status.equals(-2).not())
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(safeLimit))
        .get();
    return rows.map(_toMessage).toList();
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
  Future<int?> getMaxSeq(int groupId) async {
    // 查询该群所有消息中 seq 的最大值（忽略 NULL）
    final rows = await (_db.selectOnly(_db.messages)
          ..addColumns([_db.messages.seq])
          ..where(_db.messages.groupId.equals(groupId))
          ..where(_db.messages.seq.isNotNull()))
        .get();

    if (rows.isEmpty) return null;

    int? maxSeq;
    for (final row in rows) {
      final s = row.read(_db.messages.seq);
      if (s != null && (maxSeq == null || s > maxSeq)) {
        maxSeq = s;
      }
    }
    return maxSeq;
  }

  @override
  Future<String?> getMaxSeqLiteral(int groupId) async {
    final rows = await (_db.selectOnly(_db.messages)
          ..addColumns([_db.messages.seq, _db.messages.seqRaw])
          ..where(_db.messages.groupId.equals(groupId)))
        .get();
    final literals = <String?>[];
    for (final row in rows) {
      literals.add(row.read(_db.messages.seqRaw));
      final seq = row.read(_db.messages.seq);
      if (seq != null && seq > 0) literals.add(seq.toString());
    }
    final maxLiteral = IdLiteral.maxOf(literals);
    if (!IdLiteral.isPositive(maxLiteral)) return null;
    return maxLiteral;
  }

  @override
  Future<model.Message?> getMessageById(int messageId) async {
    final rows = await (_db.select(_db.messages)
          ..where((tbl) => tbl.id.equals(messageId))
          ..limit(1))
        .get();

    if (rows.isEmpty) return null;
    return _toMessage(rows.first);
  }

  @override
  Future<void> updateMessageStatus(
      int messageId, model.MessageStatus status) async {
    await (_db.update(_db.messages)..where((tbl) => tbl.id.equals(messageId) | tbl.mid.equals(messageId)))
        .write(MessagesCompanion(status: Value(status.value)));
  }

  @override
  Future<model.Message?> getMessageByMid(int mid) async {
    final rows = await (_db.select(_db.messages)
          ..where((tbl) => tbl.mid.equals(mid) | tbl.midRaw.equals(mid.toString()))
          ..limit(1))
        .get();

    if (rows.isEmpty) return null;
    return _toMessage(rows.first);
  }

  @override
  Future<model.Message?> getMessageByMidKey(String midKey) async {
    if (!IdLiteral.isPositive(midKey)) return null;
    final byRaw = await (_db.select(_db.messages)
          ..where((tbl) => tbl.midRaw.equals(midKey))
          ..limit(1))
        .get();
    if (byRaw.isNotEmpty) return _toMessage(byRaw.first);

    final asInt = IdLiteral.asInt(midKey);
    if (asInt == null || asInt <= 0) return null;
    final legacy = await (_db.select(_db.messages)
          ..where((tbl) => tbl.mid.equals(asInt))
          ..limit(1))
        .get();
    if (legacy.isEmpty) return null;
    return _toMessage(legacy.first);
  }

  @override
  Future<void> updateMessage(model.Message message) async {
    // 使用 mid 作为匹配条件（mid 是稳定的，而 id 在 send_confirmation 后会从本地ID变为服务端ID）
    final key = message.midKey;
    final mid = message.mid;
    if (key == null && (mid == null || mid == 0)) return;
    final match = key != null
        ? _db.messages.midRaw.equals(key) |
            (mid != null && mid > 0 ? _db.messages.mid.equals(mid) : const Constant(false))
        : _db.messages.mid.equals(mid!);
    await (_db.update(_db.messages)..where((tbl) => match))
        .write(MessagesCompanion(
              seq: message.seq == null ? const Value.absent() : Value(message.seq),
              seqRaw: message.seqKey == null ? const Value.absent() : Value(message.seqKey),
              midRaw: message.midKey == null ? const Value.absent() : Value(message.midKey),
              status: Value(message.status.value),
            ));
  }

  @override
  Future<void> updateMessageDelivered(int mid) async {
    await (_db.update(_db.messages)..where((tbl) => tbl.mid.equals(mid)))
        .write(const MessagesCompanion(delivered: Value(true)));
  }

  @override
  Future<void> deleteMessage({int? id, int? mid}) async {
    final table = _db.messages;
    final Expression<bool> match = (mid != null && mid > 0)
        ? table.mid.equals(mid)
        : (id != null ? table.id.equals(id) : const Constant(false));
    if (mid == null && id == null) return;

    final rows = await (_db.select(table)..where((tbl) => match)).get();
    if (rows.isEmpty) return;
    final row = rows.first;

    await (_db.delete(table)..where((tbl) => tbl.id.equals(row.id))).go();
    await _refreshConversationPreview(row);
  }

  Future<void> _refreshConversationPreview(Message row) async {
    final isGroup = row.groupId != null && row.groupId! > 0;
    final targetId = isGroup
        ? row.groupId!
        : (row.fromId == _currentUserId ? row.toId : row.fromId);
    final latest = await getLastMessage(
      targetId,
      groupId: isGroup ? row.groupId : null,
    );

    await (_db.update(_db.conversations)
          ..where((tbl) => tbl.targetId.equals(targetId)))
        .write(ConversationsCompanion(
          lastMessageContent: Value(latest?.content),
          lastMessageType: Value(latest?.msgType.value),
          lastMessageStatus: Value(latest?.status.value),
          lastMessageTimestamp: Value(latest?.timestamp),
          lastMessageFromId: Value(latest?.fromId),
          lastMessageToId: Value(latest?.toId),
          lastMessageGroupId: Value(latest?.groupId),
          lastMessageLocalPath: Value(latest?.localPath),
          lastMsgId: Value(latest?.id),
        ));
  }

  @override
  Future<void> updateMessageContent(
      int messageId, String content, model.MessageStatus status) async {
    // 使用 mid 作为匹配条件（与 updateMessage 保持一致）
    await (_db.update(_db.messages)..where((tbl) => tbl.mid.equals(messageId)))
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
                tbl.fromId.equals(userId).not() &
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
      isTop: Value(conversation.isTop ? 1 : 0),
      isMute: Value(conversation.isMute ? 1 : 0),
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

    query.orderBy([
      (t) => OrderingTerm.desc(t.isTop),
      (t) => OrderingTerm.desc(t.updateTime),
    ]);

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
              isTop: Value(conversation.isTop ? 1 : 0),
              isMute: Value(conversation.isMute ? 1 : 0),
            ));
  }

  @override
  Future<void> updateUnreadCount(int conversationId, int count) async {
    await (_db.update(_db.conversations)..where((tbl) => tbl.id.equals(conversationId)))
        .write(ConversationsCompanion(unreadCount: Value(count)));
  }

  @override
  Future<void> updateConversationFlags(
    int conversationId, {
    bool? isTop,
    bool? isMute,
  }) async {
    if (isTop == null && isMute == null) return;
    await (_db.update(_db.conversations)..where((tbl) => tbl.id.equals(conversationId)))
        .write(ConversationsCompanion(
              isTop: isTop != null ? Value(isTop ? 1 : 0) : const Value.absent(),
              isMute: isMute != null ? Value(isMute ? 1 : 0) : const Value.absent(),
            ));
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
      midLiteral: row.midRaw,
      seq: row.seq,
      seqLiteral: row.seqRaw,
      fromId: row.fromId,
      toId: row.toId,
      groupId: row.groupId,
      content: row.content,
      msgType: model.MessageType.fromValue(row.msgType),
      status: model.MessageStatus.fromValue(row.status),
      delivered: row.delivered,
      timestamp: row.timestamp,
      localPath: row.localPath,
      senderNickname: row.senderNickname,
      senderAvatar: row.senderAvatar,
      replyMsgId: row.replyMsgId,
      replyPreview: _replyFromExtra(row.extra, 'replyPreview'),
      replySenderName: _replyFromExtra(row.extra, 'replySenderName'),
      atUserIds: row.atUserIds,
    );
  }

  String? _encodeReplyExtra(model.Message message) {
    final preview = message.replyPreview;
    final senderName = message.replySenderName;
    if ((preview == null || preview.isEmpty) &&
        (senderName == null || senderName.isEmpty)) {
      return null;
    }
    return jsonEncode({
      'replyPreview': preview,
      'replySenderName': senderName,
    });
  }

  String? _replyFromExtra(String? extra, String key) {
    if (extra == null || extra.isEmpty) return null;
    try {
      final decoded = jsonDecode(extra);
      if (decoded is Map) {
        final value = decoded[key];
        if (value == null || value.toString().isEmpty) return null;
        return value.toString();
      }
    } catch (_) {}
    return null;
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
      isTop: row.isTop == 1,
      isMute: row.isMute == 1,
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
