import 'package:sqflite/sqflite.dart';
import 'dart:convert' show jsonDecode;

import '../model/conversation.dart';
import '../model/message.dart';
import '../storage/database_helper.dart';
import '../utils/logger.dart';
import '../event/event_bus.dart';
import '../event/im_event.dart';
import 'conversation_service.dart';

class ConversationServiceImpl implements ConversationService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final EventBus _eventBus = EventBus();

  final Logger _log = AppLogger.instance;

  @override
  Future<List<Conversation>> getConversationList(int userId) async {
    final conversations = await _dbHelper.getConversations(userId);
    return conversations;
  }

  @override
  Future<Conversation?> getConversation(int conversationId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToConversation(maps.first);
  }

  @override
  Future<Conversation> getOrCreateConversation({
    required int userId,
    required int targetType,
    required int targetId,
  }) async {
    final db = await _dbHelper.database;

    final existing = await db.query(
      'conversations',
      where: 'user_id = ? AND target_type = ? AND target_id = ?',
      whereArgs: [userId, targetType, targetId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return _mapToConversation(existing.first);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final conversation = Conversation(
      userId: userId,
      targetType: TargetType.fromValue(targetType),
      targetId: targetId,
      unreadCount: 0,
      updateTime: now,
    );

    final id = await db.insert(
      'conversations',
      _conversationToMap(conversation),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final created = conversation.copyWith(id: id);
    _eventBus.fire(ConversationUpdatedEvent(conversation: created));
    return created;
  }

  @override
  Future<void> deleteConversation(int conversationId) async {
    final db = await _dbHelper.database;

    final conversation = await getConversation(conversationId);
    if (conversation == null) return;

    await db.transaction((txn) async {
      await txn.delete(
        'conversations',
        where: 'id = ?',
        whereArgs: [conversationId],
      );

      if (conversation.isGroup) {
        await txn.delete(
          'messages',
          where: 'group_id = ?',
          whereArgs: [conversation.targetId],
        );
      } else {
        await txn.rawDelete(
          'DELETE FROM messages WHERE (from_id = ? AND to_id = ?) OR (from_id = ? AND to_id = ?)',
          [
            conversation.userId,
            conversation.targetId,
            conversation.targetId,
            conversation.userId,
          ],
        );
      }
    });

    _eventBus.fire(ConversationUpdatedEvent(conversation: conversation));
  }

  @override
  Future<void> markConversationAsRead(int conversationId) async {
    final conversation = await getConversation(conversationId);
    if (conversation == null || conversation.unreadCount <= 0) return;

    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      if (conversation.isGroup) {
        await txn.update(
          'messages',
          {'status': MessageStatus.read.value},
          where: 'to_id = ? AND group_id = ? AND status < ?',
          whereArgs: [
            conversation.userId,
            conversation.targetId,
            MessageStatus.read.value,
          ],
        );
      } else {
        await txn.update(
          'messages',
          {'status': MessageStatus.read.value},
          where: 'to_id = ? AND from_id = ? AND status < ?',
          whereArgs: [
            conversation.userId,
            conversation.targetId,
            MessageStatus.read.value,
          ],
        );
      }

      await txn.update(
        'conversations',
        {
          'unread_count': 0,
          'update_time': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [conversationId],
      );
    });

    _sendReadReceipt(conversation);

    final updated = conversation.copyWith(unreadCount: 0);
    _eventBus.fire(ConversationUpdatedEvent(conversation: updated));
  }

  @override
  Future<int> getTotalUnreadCount(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(unread_count), 0) as total FROM conversations WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<void> updateLastMessage(int conversationId, Message message) async {
    final conversation = await getConversation(conversationId);
    if (conversation == null) return;

    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'conversations',
      {'last_message': message.toJson(), 'update_time': now},
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    final updated = conversation.copyWith(
      lastMessage: message,
      updateTime: now,
    );
    _eventBus.fire(ConversationUpdatedEvent(conversation: updated));
  }

  @override
  Future<void> incrementUnreadCount(int conversationId, {int count = 1}) async {
    final conversation = await getConversation(conversationId);
    if (conversation == null) return;

    final db = await _dbHelper.database;
    final newCount = conversation.unreadCount + count;

    await db.rawUpdate(
      'UPDATE conversations SET unread_count = ?, update_time = ? WHERE id = ?',
      [newCount, DateTime.now().millisecondsSinceEpoch, conversationId],
    );

    final updated = conversation.copyWith(unreadCount: newCount);
    _eventBus.fire(ConversationUpdatedEvent(conversation: updated));
  }

  void _sendReadReceipt(Conversation conversation) {
    try {
      final receiptData = {
        'type': conversation.isGroup
            ? 'group_read_receipt'
            : 'private_read_receipt',
        'targetId': conversation.targetId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      _log.d('发送已读回执: $receiptData');
    } catch (e) {
      _log.e('发送已读回执失败', error: e);
    }
  }

  Conversation _mapToConversation(Map<String, dynamic> map) {
    return Conversation.fromJson({
      'id': map['id'],
      'userId': map['user_id'],
      'targetType': map['target_type'],
      'targetId': map['target_id'],
      'lastMessage': map['last_message'] != null
          ? _decodeJson(map['last_message'])
          : null,
      'unreadCount': map['unread_count'],
      'updateTime': map['update_time'],
    });
  }

  Map<String, dynamic> _conversationToMap(Conversation conversation) {
    return {
      'id': conversation.id,
      'user_id': conversation.userId,
      'target_type': conversation.targetType.value,
      'target_id': conversation.targetId,
      'last_message': conversation.lastMessage?.toJson(),
      'unread_count': conversation.unreadCount,
      'update_time': conversation.updateTime,
    };
  }

  dynamic _decodeJson(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }
}
