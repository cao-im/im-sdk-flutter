import '../model/message.dart';

abstract class MessageService {
  Future<Message> sendMessage({
    required int toId,
    required String content,
    int msgType = 0,
    int? groupId,
  });

  Future<Message> sendGroupMessage({
    required int groupId,
    required String content,
    int msgType = 0,
  });

  Future<List<Message>> getHistoryMessages({
    required int targetId,
    int? groupId,
    int page = 1,
    int size = 20,
  });

  Future<void> recallMessage(int messageId);

  Future<Message?> getMessage(int messageId);

  Future<List<Message>> getUnreadMessages(int userId);

  Future<void> markAsRead(int messageId, {int? groupId});

  Future<void> markConversationAsRead({required int targetId, int? groupId});
}
