import 'dart:convert';

import 'sender_info.dart';

enum MessageType {
  text(0),
  image(1),
  file(2),
  voice(3),
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
  /// 送达状态（独立于status，发送方视角）：false=未送达, true=已送达
  bool delivered;
  final int timestamp;
  final String? localPath;
  final SenderInfo? senderInfo;
  final GroupInfo? groupInfo;
  /// 发送者昵称（冗余存储，避免频繁查询用户表）
  final String? senderNickname;
  /// 发送者头像（冗余存储，避免频繁查询用户表）
  final String? senderAvatar;
  /// 被引用消息的 mid
  final int? replyMsgId;
  final String? replyPreview;
  final String? replySenderName;

  /// 服务端序号（完全由服务端生成，严格递增，用于增量离线同步）
  final int? seq;

  Message({
    this.id,
    this.mid,
    this.seq,
    required this.fromId,
    required this.toId,
    this.groupId,
    required this.content,
    this.msgType = MessageType.text,
    this.status = MessageStatus.sending,
    this.delivered = false,
    int? timestamp,
    this.localPath,
    this.senderInfo,
    this.groupInfo,
    this.senderNickname,
    this.senderAvatar,
    this.replyMsgId,
    this.replyPreview,
    this.replySenderName,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory Message.fromJson(Map<String, dynamic> json) {
    print('📥 [Message.fromJson] 原始JSON: $json');
    
    // 从 senderInfo 中提取昵称和头像
    String? senderNickname;
    String? senderAvatar;
    final senderInfoData = json['senderInfo'];
    if (senderInfoData != null && senderInfoData is Map<String, dynamic>) {
      senderNickname = senderInfoData['nickname'];
      senderAvatar = senderInfoData['avatar'];
    }
    
    return Message(
      id: json['id'],
      mid: json['mid'],
      seq: json['seq'],
      fromId: json['fromId'] ?? 0,
      toId: json['toId'] ?? 0,
      groupId: json['groupId'],
      content: json['content'] ?? '',
      msgType: MessageType.fromValue(json['msgType'] ?? 0),
      status: statusFromPayload(json),
      delivered: json['delivered'] == true || json['delivered'] == 1,
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      localPath: json['localPath'],
      senderInfo: json['senderInfo'] != null
          ? SenderInfo.fromJson(json['senderInfo'])
          : null,
      groupInfo: json['groupInfo'] != null
          ? GroupInfo.fromJson(json['groupInfo'])
          : null,
      senderNickname: senderNickname,
      senderAvatar: senderAvatar,
      replyMsgId: _asInt(json['replyMsgId']),
      replyPreview: _replyField(json, 'replyPreview'),
      replySenderName: _replyField(json, 'replySenderName'),
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String? _replyField(Map<String, dynamic> json, String key) {
    final direct = json[key];
    if (direct != null && direct.toString().isNotEmpty) {
      return direct.toString();
    }
    Map<String, dynamic>? extraMap;
    final extra = json['extra'];
    if (extra is Map) {
      extraMap = Map<String, dynamic>.from(extra);
    } else if (extra is String && extra.isNotEmpty) {
      try {
        final decoded = jsonDecode(extra);
        if (decoded is Map<String, dynamic>) extraMap = decoded;
      } catch (_) {}
    }
    final nested = extraMap?[key];
    if (nested == null || nested.toString().isEmpty) return null;
    return nested.toString();
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'mid': mid,
      'seq': seq,
      'fromId': fromId,
      'toId': toId,
      'groupId': groupId,
      'content': content,
      'msgType': msgType.value,
      'status': status.value,
      'delivered': delivered,
      'timestamp': timestamp,
      'localPath': localPath,
      if (senderInfo != null) 'senderInfo': senderInfo!.toJson(),
      if (groupInfo != null) 'groupInfo': groupInfo!.toJson(),
      if (replyMsgId != null) 'replyMsgId': replyMsgId,
      if (replyPreview != null) 'replyPreview': replyPreview,
      if (replySenderName != null) 'replySenderName': replySenderName,
    };
    print('📦 [Message.toJson] $json');
    return json;
  }

  Map<String, dynamic> toProtocolJson() {
    final json = {
      'type': groupId != null ? 'group' : 'private',
      'toId': toId,
      if (groupId != null) 'groupId': groupId,  // 群聊时单独传 groupId 字段
      'content': content,
      'msgType': msgType.value,
      if (mid != null) 'mid': mid,
      if (replyMsgId != null && replyMsgId! > 0) 'replyMsgId': replyMsgId,
      if (replyPreview != null && replyPreview!.isNotEmpty) 'replyPreview': replyPreview,
      if (replySenderName != null && replySenderName!.isNotEmpty)
        'replySenderName': replySenderName,
    };
    print('📤 [Message.toProtocolJson] type=${json['type']}, toId=${json['toId']}, msgType=${json['msgType']}, contentBytes=${content.length}');
    return json;
  }

  Message copyWith({
    int? id,
    int? mid,
    int? seq,
    int? fromId,
    int? toId,
    int? groupId,
    String? content,
    MessageType? msgType,
    MessageStatus? status,
    bool? delivered,
    int? timestamp,
    String? localPath,
    SenderInfo? senderInfo,
    GroupInfo? groupInfo,
    String? senderNickname,
    String? senderAvatar,
    int? replyMsgId,
    String? replyPreview,
    String? replySenderName,
  }) {
    return Message(
      id: id ?? this.id,
      mid: mid ?? this.mid,
      seq: seq ?? this.seq,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      groupId: groupId ?? this.groupId,
      content: content ?? this.content,
      msgType: msgType ?? this.msgType,
      status: status ?? this.status,
      delivered: delivered ?? this.delivered,
      timestamp: timestamp ?? this.timestamp,
      localPath: localPath ?? this.localPath,
      senderInfo: senderInfo ?? this.senderInfo,
      groupInfo: groupInfo ?? this.groupInfo,
      senderNickname: senderNickname ?? this.senderNickname,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      replyMsgId: replyMsgId ?? this.replyMsgId,
      replyPreview: replyPreview ?? this.replyPreview,
      replySenderName: replySenderName ?? this.replySenderName,
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

/// 服务端下行同时带有客户端语义的 status，以及历史字段 msgStatus（0 未读 / 1 已读 / -2 撤回）。
MessageStatus statusFromPayload(Map<String, dynamic> json) {
  if (json.containsKey('status') && json['status'] != null) {
    final value = json['status'];
    if (value is int) {
      return MessageStatus.fromValue(value);
    }
  }
  final msgStatus = json['msgStatus'];
  if (msgStatus == -2) {
    return MessageStatus.recalled;
  }
  if (msgStatus == 1) {
    return MessageStatus.read;
  }
  if (json['delivered'] == 1 || json['delivered'] == true) {
    return MessageStatus.delivered;
  }
  return MessageStatus.sent;
}
