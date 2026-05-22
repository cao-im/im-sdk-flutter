import '../model/conversation.dart';
import '../model/message.dart';

abstract class ConversationService {
  Future<List<Conversation>> getConversationList(int userId);

  Future<Conversation?> getConversation(int conversationId);

  Future<Conversation> getOrCreateConversation({
    required int userId,
    required int targetType,
    required int targetId,
  });

  Future<void> deleteConversation(int conversationId);

  Future<void> markConversationAsRead(int conversationId);

  Future<int> getTotalUnreadCount(int userId);

  Future<void> updateLastMessage(int conversationId, Message message);

  Future<void> incrementUnreadCount(int conversationId, {int count = 1});
}
