import 'dart:convert' show jsonDecode;

import '../model/conversation.dart';
import '../model/message.dart';
import '../storage/storage_interface.dart';
import '../utils/logger.dart';
import '../event/event_bus.dart';
import '../event/im_event.dart';
import 'conversation_service.dart';

/// 已读回执发送回调：将已读回执通过 WebSocket 发送到服务端
/// 参数为会话的目标ID和群组ID，由调用方（IMClient）负责查询未读消息并批量发送
typedef OnSendReadReceipt = Future<void> Function({
  required int targetId,
  int? groupId,
});

class ConversationServiceImpl implements ConversationService {
  final StorageInterface _dbHelper;
  final EventBus _eventBus = EventBus();
  final OnSendReadReceipt? _onSendReadReceipt;

  final Logger _log = AppLogger.instance;

  ConversationServiceImpl({
    required StorageInterface dbHelper,
    OnSendReadReceipt? onSendReadReceipt,
  }) : _dbHelper = dbHelper,
       _onSendReadReceipt = onSendReadReceipt;

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
    _log.i('🔍 [ConversationService] getOrCreateConversation 开始: userId=$userId, targetType=$targetType, targetId=$targetId');
    _log.i('🔍 [ConversationService] dbHelper 类型: ${_dbHelper.runtimeType}');

    final conversations = await _dbHelper.getConversations(userId);
    _log.i('🔍 [ConversationService] 获取到 ${conversations.length} 个会话');

    final existing = conversations.where((c) =>
      c.userId == userId &&
      c.targetType.value == targetType &&
      c.targetId == targetId
    ).toList();

    if (existing.isNotEmpty) {
      _log.i('✅ [ConversationService] 找到已存在的会话: id=${existing.first.id}');
      return existing.first;
    }

    _log.i('📝 [ConversationService] 未找到匹配会话，创建新会话...');

    final now = DateTime.now().millisecondsSinceEpoch;
    final conversation = Conversation(
      userId: userId,
      targetType: TargetType.fromValue(targetType),
      targetId: targetId,
      unreadCount: 0,
      updateTime: now,
    );

    _log.i('💾 [ConversationService] 调用 insertConversation...');
    final id = await _dbHelper.insertConversation(conversation);
    _log.i('✅ [ConversationService] 会话插入成功: 新ID=$id');

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

    // 先更新会话未读数（会话级别操作，MessageService 不处理）
    await _dbHelper.updateUnreadCount(conversationId, 0);

    // 委托给 IMClient 回调 → MessageService 处理：标记消息已读 + 发送 WebSocket 回执
    if (_onSendReadReceipt != null) {
      try {
        await _onSendReadReceipt!(
          targetId: conversation.targetId,
          groupId: conversation.isGroup ? conversation.targetId : null,
        );
        _log.i('✅ 已读回执委托发送完成: targetId=${conversation.targetId}');
      } catch (e) {
        _log.e('❌ 已读回执委托发送失败: $e');
      }
    }

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

}
