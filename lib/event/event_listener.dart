import '../model/message.dart';
import '../model/conversation.dart';
import '../model/group.dart';
import '../core/connection_status.dart';
import 'im_event.dart';

abstract class MessageListener {
  void onMessageReceived(Message message);
  void onMessageSent(Message message);
  void onMessageRecalled(Message message);
}

abstract class ConnectionListener {
  void onConnected();
  void onDisconnected();
  void onConnecting();
  void onReconnecting();
  void onReconnectFailed();
}

abstract class ConversationListener {
  void onConversationUpdated(Conversation conversation);
}

abstract class GroupListener {
  void onGroupCreated(Group group);
  void onGroupDismissed(int groupId);
  void onMemberJoined(int groupId, int userId);
  void onMemberLeft(int groupId, int userId);
}
