import '../model/message.dart';
import '../model/conversation.dart';

abstract class StorageInterface {
  Future<void> init({int? userId});

  Future<int> insertMessage(Message message);

  /// 保存收到的消息。本地已有同一条 mid 时返回 false，并且不会再插一行。
  Future<bool> saveIncomingMessage(Message message);

  /// 按 mid 原文查找。数字和字符串两种形式都能命中。
  Future<Message?> getMessageByMidKey(String midKey);

  /// 在本地消息里按文本或文件名搜索。数据库已按用户隔离。
  Future<List<Message>> searchMessages({
    required String keyword,
    required int currentUserId,
    int limit = 50,
  });

  /// 本地图片、视频和文件消息，按时间从新到旧。
  Future<List<Message>> listMediaMessages({int limit = 500});

  Future<List<Message>> getMessages({
    required int targetId,
    int? groupId,
    int? currentUserId,
    int page = 1,
    int size = 20,
  });

  Future<Message?> getLastMessage(int targetId, {int? groupId});

  /// 查询指定群组中消息的最大 seq（用于离线增量同步的 sinceSeq 基准）
  Future<int?> getMaxSeq(int groupId);

  /// 群内最大 seq 的十进制原文。没有记录时返回 null。
  Future<String?> getMaxSeqLiteral(int groupId);

  Future<Message?> getMessageById(int messageId);

  /// 根据 mid（客户端生成的全局唯一ID）查找消息
  Future<Message?> getMessageByMid(int mid);

  Future<void> updateMessageStatus(int messageId, MessageStatus status);

  /// 更新消息（支持更新 id、status 等字段）
  Future<void> updateMessage(Message message);

  /// 更新消息送达状态（通过 mid 匹配）
  Future<void> updateMessageDelivered(int mid);

  Future<void> updateMessageContent(int messageId, String content, MessageStatus status);

  /// 删除本地消息。优先按 mid，否则按本地 id。
  Future<void> deleteMessage({int? id, int? mid});

  Future<int> getUnreadCount(int userId);

  Future<void> markAsRead(int userId, {int? targetId, int? groupId});

  Future<int> insertConversation(Conversation conversation);

  Future<List<Conversation>> getConversations(int userId);

  Future<void> updateConversation(Conversation conversation);

  Future<void> updateUnreadCount(int conversationId, int count);

  /// 更新会话置顶 / 免打扰标记
  Future<void> updateConversationFlags(
    int conversationId, {
    bool? isTop,
    bool? isMute,
  });

  Future<void> deleteConversation(int conversationId);

  Future<void> close();
}
