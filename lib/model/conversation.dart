import 'message.dart';

enum TargetType {
  private(1),
  group(2);

  final int value;
  const TargetType(this.value);

  static TargetType fromValue(int value) {
    return TargetType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TargetType.private,
    );
  }
}

class Conversation {
  final int? id;
  final int userId;
  final TargetType targetType;
  final int targetId;
  final Message? lastMessage;
  int unreadCount;
  final int updateTime;
  /// 是否置顶
  final bool isTop;
  /// 是否免打扰
  final bool isMute;

  Conversation({
    this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    this.lastMessage,
    this.unreadCount = 0,
    int? updateTime,
    this.isTop = false,
    this.isMute = false,
  }) : updateTime = updateTime ?? DateTime.now().millisecondsSinceEpoch;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      userId: json['userId'] ?? 0,
      targetType: TargetType.fromValue(json['targetType'] ?? 1),
      targetId: json['targetId'] ?? 0,
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      updateTime: json['updateTime'] ?? DateTime.now().millisecondsSinceEpoch,
      isTop: json['isTop'] == true || json['isTop'] == 1,
      isMute: json['isMute'] == true || json['isMute'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'targetType': targetType.value,
      'targetId': targetId,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'updateTime': updateTime,
      'isTop': isTop,
      'isMute': isMute,
    };
  }

  String get conversationId =>
      '$targetId';

  bool get isPrivate => targetType == TargetType.private;
  bool get isGroup => targetType == TargetType.group;

  Conversation copyWith({
    int? id,
    int? userId,
    TargetType? targetType,
    int? targetId,
    Message? lastMessage,
    int? unreadCount,
    int? updateTime,
    bool? isTop,
    bool? isMute,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      updateTime: updateTime ?? this.updateTime,
      isTop: isTop ?? this.isTop,
      isMute: isMute ?? this.isMute,
    );
  }

  @override
  String toString() {
    return 'Conversation{id: $id, type: ${targetType.name}, targetId: $targetId, unread: $unreadCount}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conversation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          targetType == other.targetType &&
          targetId == other.targetId;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      targetType.hashCode ^
      targetId.hashCode;
}
