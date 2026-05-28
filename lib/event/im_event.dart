import '../model/message.dart';
import '../model/conversation.dart';
import '../model/user.dart';
import '../model/group.dart';

abstract class IMEvent {
  final int timestamp;

  IMEvent({int? timestamp})
    : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;
}

class MessageEvent extends IMEvent {
  final Message message;

  MessageEvent({required this.message, super.timestamp});
}

class MessageReceivedEvent extends MessageEvent {
  MessageReceivedEvent({required super.message});
}

class MessageSentEvent extends MessageEvent {
  MessageSentEvent({required super.message});
}

class MessageRecalledEvent extends MessageEvent {
  MessageRecalledEvent({required super.message});
}

class MessagesReadEvent extends IMEvent {
  final List<int> messageIds;

  MessagesReadEvent({required this.messageIds, super.timestamp});
}

class ConnectionEvent extends IMEvent {
  final ConnectionEventType type;

  ConnectionEvent({required this.type, super.timestamp});
}

enum ConnectionEventType {
  connected,
  disconnected,
  connecting,
  reconnecting,
  reconnectFailed,
}

class ConversationEvent extends IMEvent {
  final Conversation conversation;

  ConversationEvent({required this.conversation, super.timestamp});
}

class ConversationUpdatedEvent extends ConversationEvent {
  ConversationUpdatedEvent({required super.conversation});
}

class UserEvent extends IMEvent {
  final User user;

  UserEvent({required this.user, super.timestamp});
}

class GroupEvent extends IMEvent {
  final Group group;

  GroupEvent({required this.group, super.timestamp});
}

class GroupCreatedEvent extends GroupEvent {
  GroupCreatedEvent({required super.group});
}

class GroupDismissedEvent extends GroupEvent {
  GroupDismissedEvent({required super.group});
}

class MemberJoinedEvent extends GroupEvent {
  final int userId;

  MemberJoinedEvent({required super.group, required this.userId});
}

class MemberLeftEvent extends GroupEvent {
  final int userId;

  MemberLeftEvent({required super.group, required this.userId});
}

class GroupUpdatedEvent extends GroupEvent {
  GroupUpdatedEvent({required super.group});
}

class GroupMutedEvent extends GroupEvent {
  final bool isMuted;

  GroupMutedEvent({required super.group, required this.isMuted});
}

class MemberMutedEvent extends GroupEvent {
  final int userId;
  final bool isMuted;

  MemberMutedEvent({required super.group, required this.userId, required this.isMuted});
}

class FriendRequestEvent extends IMEvent {
  final int fromId;
  final int toId;

  FriendRequestEvent({
    required this.fromId,
    required this.toId,
    super.timestamp,
  });
}

class FriendAcceptedEvent extends IMEvent {
  final int fromId;
  final int toId;

  FriendAcceptedEvent({
    required this.fromId,
    required this.toId,
    super.timestamp,
  });
}

class FriendRejectedEvent extends IMEvent {
  final int fromId;
  final int toId;

  FriendRejectedEvent({
    required this.fromId,
    required this.toId,
    super.timestamp,
  });
}

class OfflineMessagesEvent extends IMEvent {
  final List<Map<String, dynamic>> messages;

  OfflineMessagesEvent({required this.messages, super.timestamp});
}

class OfflineSyncCompletedEvent extends IMEvent {
  final int totalSynced;

  OfflineSyncCompletedEvent({required this.totalSynced, super.timestamp});
}

class OfflineSyncFailedEvent extends IMEvent {
  final String error;
  final int retryCount;

  OfflineSyncFailedEvent({
    required this.error,
    required this.retryCount,
    super.timestamp,
  });
}

class SyncModeChangedEvent extends IMEvent {
  final SyncMode from;
  final SyncMode to;
  final String reason;

  SyncModeChangedEvent({
    required this.from,
    required this.to,
    required this.reason,
    super.timestamp,
  });
}

enum SyncMode {
  realtime,
  offline,
  fallback,
}
