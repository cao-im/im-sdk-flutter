import 'sender_info.dart';

enum MessageType {
  text(0),
  image(1),
  file(2),
  system(99);

  final int value;
  const MessageType(this.value);

  static MessageType fromValue(int value) {
    return MessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageType.text,
    );
  }
}

enum MessageStatus {
  sending(0),
  sent(1),
  delivered(2),
  read(3),
  failed(-1),
  recalled(-2);

  final int value;
  const MessageStatus(this.value);

  static MessageStatus fromValue(int value) {
    return MessageStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageStatus.sending,
    );
  }
}

class Message {
  final int? id;
  /// 消息全局唯一ID（客户端生成，雪花算法），0表示未分配
  final int? mid;
  final int fromId;
  final int toId;
  final int? groupId;
  final String content;
  final MessageType msgType;
  MessageStatus status;
  final int timestamp;
  final String? localPath;
  final SenderInfo? senderInfo;
  final GroupInfo? groupInfo;

  Message({
    this.id,
    this.mid,
    required this.fromId,
    required this.toId,
    this.groupId,
    required this.content,
    this.msgType = MessageType.text,
    this.status = MessageStatus.sending,
    int? timestamp,
    this.localPath,
    this.senderInfo,
    this.groupInfo,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory Message.fromJson(Map<String, dynamic> json) {
    print('📥 [Message.fromJson] 原始JSON: $json');
    return Message(
      id: json['id'],
      mid: json['mid'],
      fromId: json['fromId'] ?? 0,
      toId: json['toId'] ?? 0,
      groupId: json['groupId'],
      content: json['content'] ?? '',
      msgType: MessageType.fromValue(json['msgType'] ?? 0),
      status: MessageStatus.fromValue(json['status'] ?? 0),
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      localPath: json['localPath'],
      senderInfo: json['senderInfo'] != null
          ? SenderInfo.fromJson(json['senderInfo'])
          : null,
      groupInfo: json['groupInfo'] != null
          ? GroupInfo.fromJson(json['groupInfo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'mid': mid,
      'fromId': fromId,
      'toId': toId,
      'groupId': groupId,
      'content': content,
      'msgType': msgType.value,
      'status': status.value,
      'timestamp': timestamp,
      'localPath': localPath,
      if (senderInfo != null) 'senderInfo': senderInfo!.toJson(),
      if (groupInfo != null) 'groupInfo': groupInfo!.toJson(),
    };
    print('📦 [Message.toJson] $json');
    return json;
  }

  Map<String, dynamic> toProtocolJson() {
    final json = {
      'type': groupId != null ? 'group' : 'private',
      'toId': groupId ?? toId,
      'content': content,
      'msgType': msgType.value,
      if (mid != null) 'mid': mid,
    };
    print('📤 [Message.toProtocolJson] $json');
    return json;
  }

  Message copyWith({
    int? id,
    int? mid,
    int? fromId,
    int? toId,
    int? groupId,
    String? content,
    MessageType? msgType,
    MessageStatus? status,
    int? timestamp,
    String? localPath,
    SenderInfo? senderInfo,
    GroupInfo? groupInfo,
  }) {
    return Message(
      id: id ?? this.id,
      mid: mid ?? this.mid,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      groupId: groupId ?? this.groupId,
      content: content ?? this.content,
      msgType: msgType ?? this.msgType,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      localPath: localPath ?? this.localPath,
      senderInfo: senderInfo ?? this.senderInfo,
      groupInfo: groupInfo ?? this.groupInfo,
    );
  }

  @override
  String toString() {
    return 'Message{id: $id, mid: $mid, fromId: $fromId, toId: $toId, content: $content, type: ${msgType.name}, status: ${status.name}}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          mid == other.mid &&
          fromId == other.fromId &&
          toId == other.toId &&
          groupId == other.groupId &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      mid.hashCode ^
      fromId.hashCode ^
      toId.hashCode ^
      (groupId?.hashCode ?? 0) ^
      timestamp.hashCode;

  String get displayText {
    if (status == MessageStatus.recalled) {
      return '[消息已撤回]';
    }
    return content;
  }

  bool get canRecall {
    if (status != MessageStatus.sent && status != MessageStatus.delivered) {
      return false;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - timestamp) <= 120000;
  }

  String get statusText {
    switch (status) {
      case MessageStatus.sending:
        return '发送中...';
      case MessageStatus.sent:
        return '已发送';
      case MessageStatus.delivered:
        return '已送达';
      case MessageStatus.read:
        return '已读';
      case MessageStatus.failed:
        return '发送失败';
      case MessageStatus.recalled:
        return '已撤回';
    }
  }

  String get senderDisplayName {
    if (senderInfo != null) {
      if (senderInfo!.groupNickname != null && senderInfo!.groupNickname!.isNotEmpty) {
        return senderInfo!.groupNickname!;
      }
      if (senderInfo!.nickname.isNotEmpty) {
        return senderInfo!.nickname;
      }
    }
    return '用户$fromId';
  }

  String? get senderDisplayAvatar {
    return senderInfo?.avatar;
  }

  String? get groupDisplayName {
    return groupInfo?.groupName;
  }
}
