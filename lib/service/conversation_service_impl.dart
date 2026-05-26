import 'dart:convert' show jsonDecode;

import '../model/conversation.dart';
import '../model/message.dart';
import '../storage/storage_interface.dart';
import '../utils/logger.dart';
import '../event/event_bus.dart';
import '../event/im_event.dart';
import 'conversation_service.dart';

class ConversationServiceImpl implements ConversationService {
  final StorageInterface _dbHelper;
  final EventBus _eventBus = EventBus();

  final Logger _log = AppLogger.instance;

  ConversationServiceImpl({required StorageInterface dbHelper}) : _dbHelper = dbHelper;

  @override
  Future<List<Conversation>> getConversationList(int userId) async {
    return await _dbHelper.getConversations(userId);
  }

  @override
  Future<Conversation?> getConversation(int conversationId) async {
    final conversations = await _dbHelper.getConversations(0);
    try {
      return conversations.firstWhere((c) => c.id == conversationId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Conversation> getOrCreateConversation({
    required int userId,
    required int targetType,
    required int targetId,
  }) async {
    final conversations = await _dbHelper.getConversations(userId);
    final existing = conversations.where((c) =>
      c.userId == userId &&
      c.targetType.value == targetType &&
      c.targetId == targetId
    ).toList();

    if (existing.isNotEmpty) {
      return existing.first;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final conversation = Conversation(
      userId: userId,
      targetType: TargetType.fromValue(targetType),
      targetId: targetId,
      unreadCount: 0,
      updateTime: now,
    );

    final id = await _dbHelper.insertConversation(conversation);
    final created = conversation.copyWith(id: id);
    _eventBus.fire(ConversationUpdatedEvent(conversation: created));
    return created;
  }

  @override
  Future<void> deleteConversation(int conversationId) async {
    final conversation = await getConversation(conversationId);
    if (conversation == null) return;

    await _dbHelper.deleteConversation(conversationId);

    _eventBus.fire(ConversationUpdatedEvent(conversation: conversation));
  }

  @override
  Future<void> markConversationAsRead(int conversationId) async {
    final conversation = await getConversation(conversationId);
    if (conversation == null || conversation.unreadCount <= 0) return;

    await _dbHelper.updateUnreadCount(conversationId, 0);

    if (conversation.isGroup) {
      await _dbHelper.markAsRead(conversation.userId, groupId: conversation.targetId);
    } else {
      await _dbHelper.markAsRead(conversation.userId);
    }

    _sendReadReceipt(conversation);

    final updated = conversation.copyWith(unreadCount: 0);
    _eventBus.fire(ConversationUpdatedEvent(conversation: updated));
  }

  @override
  Future<int> getTotalUnreadCount(int userId) async {
    final conversations = await _dbHelper.getConversations(userId);
    int total = 0;
    for (final c in conversations) {
      total += c.unreadCount;
    }
    return total;
  }

  @override
  Future<void> updateLastMessage(int conversationId, Message message) async {
    final conversation = await getConversation(conversationId);
    if (conversation == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = conversation.copyWith(
      lastMessage: message,
      updateTime: now,
    );

    await _dbHelper.updateConversation(updated);
    _eventBus.fire(ConversationUpdatedEvent(conversation: updated));
  }

  @override
  Future<void> incrementUnreadCount(int conversationId, {int count = 1}) async {
    final conversation = await getConversation(conversationId);
    if (conversation == null) return;

    final newCount = conversation.unreadCount + count;
    await _dbHelper.updateUnreadCount(conversationId, newCount);

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
}
