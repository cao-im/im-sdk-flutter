import 'package:drift/drift.dart';

/// 会话表（用户会话列表）
/// 功能: 存储用户的会话列表，支持置顶、免打扰、草稿等功能
class Conversations extends Table {
  /// 会话记录主键(自增)
  IntColumn get id => integer().autoIncrement()();

  /// 用户ID(会话所属者)
  IntColumn get userId => integer()();

  /// 目标类型: 1-私聊, 2-群聊
  IntColumn get targetType => integer()();

  /// 目标ID(对方用户ID或群组ID)
  IntColumn get targetId => integer()();

  /// 未读消息数
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();

  /// 更新时间(时间戳毫秒，用于会话列表排序)
  IntColumn get updateTime => integer()();

  /// 最后一条消息内容(冗余字段，提升列表查询性能)
  TextColumn get lastMessageContent => text().nullable()();

  /// 最后一条消息类型(0-文本, 1-图片, 2-文件...)
  IntColumn get lastMessageType => integer().nullable()();

  /// 最后一条消息状态(0-发送中, 1-发送成功, 2-发送失败)
  IntColumn get lastMessageStatus => integer().nullable()();

  /// 最后一条消息发送时间(时间戳毫秒)
  IntColumn get lastMessageTimestamp => integer().nullable()();

  /// 最后一条消息发送者ID
  IntColumn get lastMessageFromId => integer().nullable()();

  /// 最后一条消息接收者ID(私聊时使用)
  IntColumn get lastMessageToId => integer().nullable()();

  /// 最后一条消息所属群组ID(群聊时使用)
  IntColumn get lastMessageGroupId => integer().nullable()();

  /// 最后一条消息本地存储路径(图片/视频/文件等富媒体消息)
  TextColumn get lastMessageLocalPath => text().nullable()();

  /// 最后一条消息ID(关联messages表.id)
  IntColumn get lastMsgId => integer().nullable()();

  /// 是否置顶: 0-否, 1-是
  IntColumn get isTop => integer().withDefault(const Constant(0))();

  /// 是否免打扰: 0-否, 1-是(不推送通知)
  IntColumn get isMute => integer().withDefault(const Constant(0))();

  /// 是否删除: 0-否, 1-是(仅删除会话，不删除消息)
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();

  /// 草稿内容(输入框未发送的内容)
  TextColumn get draftContent => text().nullable()();
}
