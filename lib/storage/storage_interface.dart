import '../model/message.dart';
import '../model/conversation.dart';

abstract class StorageInterface {
  Future<void> init({int? userId});

  Future<int> insertMessage(Message message);

  Future<List<Message>> getMessages({
    required int targetId,
    int? groupId,
    int? currentUserId,
    int page = 1,
    int size = 20,
  });

  Future<Message?> getLastMessage(int targetId, {int? groupId});

  Future<Message?> getMessageById(int messageId);

  /// 根据 mid（客户端生成的全局唯一ID）查找消息
  Future<Message?> getMessageByMid(int mid);

  Future<void> updateMessageStatus(int messageId, MessageStatus status);

  /// 更新消息（支持更新 id、status 等字段）
  Future<void> updateMessage(Message message);

  Future<void> updateMessageContent(int messageId, String content, MessageStatus status);

  Future<int> getUnreadCount(int userId);

  Future<void> markAsRead(int userId, {int? targetId, int? groupId});

  Future<int> insertConversation(Conversation conversation);

  Future<List<Conversation>> getConversations(int userId);

  Future<void> updateConversation(Conversation conversation);

  Future<void> updateUnreadCount(int conversationId, int count);

  Future<void> deleteConversation(int conversationId);

  Future<void> close();
}
