import 'package:hive/hive.dart';
import 'message_hive.dart';
import '../../../model/conversation.dart';

part 'conversation_hive.g.dart';

@HiveType(typeId: 1)
class ConversationHive extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  int userId;

  @HiveField(2)
  int targetType;

  @HiveField(3)
  int targetId;

  @HiveField(4)
  MessageHive? lastMessage;

  @HiveField(5)
  int unreadCount;

  @HiveField(6)
  int updateTime;

  ConversationHive({
    this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updateTime,
  });

  factory ConversationHive.fromConversation(Conversation conversation) {
    return ConversationHive(
      id: conversation.id,
      userId: conversation.userId,
      targetType: conversation.targetType.value,
      targetId: conversation.targetId,
      lastMessage: conversation.lastMessage != null
          ? MessageHive.fromMessage(conversation.lastMessage!)
          : null,
      unreadCount: conversation.unreadCount,
      updateTime: conversation.updateTime,
    );
  }

  Conversation toConversation() {
    return Conversation(
      id: id,
      userId: userId,
      targetType: TargetType.fromValue(targetType),
      targetId: targetId,
      lastMessage: lastMessage?.toMessage(),
      unreadCount: unreadCount,
      updateTime: updateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'targetType': targetType,
      'targetId': targetId,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'updateTime': updateTime,
    };
  }

  factory ConversationHive.fromJson(Map<String, dynamic> json) {
    return ConversationHive(
      id: json['id'],
      userId: json['userId'] ?? 0,
      targetType: json['targetType'] ?? 1,
      targetId: json['targetId'] ?? 0,
      lastMessage: json['lastMessage'] != null
          ? MessageHive.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      updateTime: json['updateTime'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
