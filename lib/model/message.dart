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
  final int fromId;
  final int toId;
  final int? groupId;
  final String content;
  final MessageType msgType;
  MessageStatus status;
  final int timestamp;
  final String? localPath;

  Message({
    this.id,
    required this.fromId,
    required this.toId,
    this.groupId,
    required this.content,
    this.msgType = MessageType.text,
    this.status = MessageStatus.sending,
    int? timestamp,
    this.localPath,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      fromId: json['fromId'] ?? 0,
      toId: json['toId'] ?? 0,
      groupId: json['groupId'],
      content: json['content'] ?? '',
      msgType: MessageType.fromValue(json['msgType'] ?? 0),
      status: MessageStatus.fromValue(json['status'] ?? 0),
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      localPath: json['localPath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromId': fromId,
      'toId': toId,
      'groupId': groupId,
      'content': content,
      'msgType': msgType.value,
      'status': status.value,
      'timestamp': timestamp,
      'localPath': localPath,
    };
  }

  Map<String, dynamic> toProtocolJson() {
    return {
      'type': groupId != null ? 'group' : 'private',
      'toId': groupId ?? toId,
      'content': content,
      'msgType': msgType.value,
    };
  }

  Message copyWith({
    int? id,
    int? fromId,
    int? toId,
    int? groupId,
    String? content,
    MessageType? msgType,
    MessageStatus? status,
    int? timestamp,
    String? localPath,
  }) {
    return Message(
      id: id ?? this.id,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      groupId: groupId ?? this.groupId,
      content: content ?? this.content,
      msgType: msgType ?? this.msgType,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      localPath: localPath ?? this.localPath,
    );
  }

  @override
  String toString() {
    return 'Message{id: $id, fromId: $fromId, toId: $toId, content: $content, type: ${msgType.name}, status: ${status.name}}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fromId == other.fromId &&
          toId == other.toId &&
          groupId == other.groupId &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      id.hashCode ^
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
}
