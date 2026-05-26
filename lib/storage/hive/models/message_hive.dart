import 'package:hive/hive.dart';
import '../../../model/message.dart';

part 'message_hive.g.dart';

@HiveType(typeId: 0)
class MessageHive extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  int fromId;

  @HiveField(2)
  int toId;

  @HiveField(3)
  int? groupId;

  @HiveField(4)
  String content;

  @HiveField(5)
  int msgType;

  @HiveField(6)
  int status;

  @HiveField(7)
  int timestamp;

  @HiveField(8)
  String? localPath;

  MessageHive({
    this.id,
    required this.fromId,
    required this.toId,
    this.groupId,
    required this.content,
    required this.msgType,
    required this.status,
    required this.timestamp,
    this.localPath,
  });

  factory MessageHive.fromMessage(Message message) {
    return MessageHive(
      id: message.id,
      fromId: message.fromId,
      toId: message.toId,
      groupId: message.groupId,
      content: message.content,
      msgType: message.msgType.value,
      status: message.status.value,
      timestamp: message.timestamp,
      localPath: message.localPath,
    );
  }

  Message toMessage() {
    return Message(
      id: id,
      fromId: fromId,
      toId: toId,
      groupId: groupId,
      content: content,
      msgType: MessageType.fromValue(msgType),
      status: MessageStatus.fromValue(status),
      timestamp: timestamp,
      localPath: localPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromId': fromId,
      'toId': toId,
      'groupId': groupId,
      'content': content,
      'msgType': msgType,
      'status': status,
      'timestamp': timestamp,
      'localPath': localPath,
    };
  }

  factory MessageHive.fromJson(Map<String, dynamic> json) {
    return MessageHive(
      id: json['id'],
      fromId: json['fromId'] ?? 0,
      toId: json['toId'] ?? 0,
      groupId: json['groupId'],
      content: json['content'] ?? '',
      msgType: json['msgType'] ?? 0,
      status: json['status'] ?? 0,
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      localPath: json['localPath'],
    );
  }
}
