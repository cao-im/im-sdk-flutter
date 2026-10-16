import '../model/message.dart';

abstract class MessageService {
  Future<Message> sendMessage({
    required int toId,
    required String content,
    int msgType = 0,
    int? groupId,
    String? senderNickname,
    String? senderAvatar,
    int? replyMsgId,
    String? replyPreview,
    String? replySenderName,
  });

  Future<Message> sendGroupMessage({
    required int groupId,
    required String content,
    int msgType = 0,
    String? senderNickname,
    String? senderAvatar,
    int? replyMsgId,
    String? replyPreview,
    String? replySenderName,
  });

  Future<List<Message>> getHistoryMessages({
    required int targetId,
    int? groupId,
    int page = 1,
    int size = 20,
  });

  Future<void> recallMessage(int messageId);

  Future<void> deleteLocalMessage({int? id, int? mid});

  /// 只写入本地，不发送。用于上传失败后仍能在下次打开会话时看到并重试。
  Future<Message> saveLocalOutgoing({
    required int toId,
    int? groupId,
    required String content,
    int msgType = 0,
    MessageStatus status = MessageStatus.failed,
    String? localPath,
    String? senderNickname,
    String? senderAvatar,
  });

  /// 用已有本地消息重发，避免再插一条新记录。
  Future<Message> resendSavedMessage({
    required int mid,
    required String content,
  });

  Future<Message?> getMessage(int messageId);

  Future<Message?> getMessageByMid(int mid);

  Future<List<Message>> getUnreadMessages(int userId);

  Future<void> markAsRead(int messageId, {int? groupId});

  Future<void> markConversationAsRead({required int targetId, int? groupId});
}
