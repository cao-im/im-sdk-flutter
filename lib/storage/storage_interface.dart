import '../model/message.dart';
import '../model/conversation.dart';

abstract class StorageInterface {
  Future<void> init();

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

  Future<void> updateMessageStatus(int messageId, MessageStatus status);

  Future<void> updateMessageContent(int messageId, String content, MessageStatus status);

  Future<int> getUnreadCount(int userId);

  Future<void> markAsRead(int userId, {int? groupId});

  Future<int> insertConversation(Conversation conversation);

  Future<List<Conversation>> getConversations(int userId);

  Future<void> updateConversation(Conversation conversation);

  Future<void> updateUnreadCount(int conversationId, int count);

  Future<void> deleteConversation(int conversationId);

  Future<void> close();
}
