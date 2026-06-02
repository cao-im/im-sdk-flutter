import 'package:drift/drift.dart';

/// 消息表（核心表）
/// 功能: 存储所有聊天消息（私聊+群聊），支持消息回复、@提醒等功能
class Messages extends Table {
  /// 消息记录主键(自增)
  IntColumn get id => integer().autoIncrement()();

  /// 消息全局唯一ID(雪花算法生成，0表示待分配)
  IntColumn get mid => integer().withDefault(const Constant(0))();

  /// 发送者用户ID
  IntColumn get fromId => integer()();

  /// 接收者用户ID(私聊时使用)
  IntColumn get toId => integer()();

  /// 群组ID(群聊时使用，与to_id互斥)
  IntColumn get groupId => integer().nullable()();

  /// 消息内容(文本消息为纯文本，其他类型可能为JSON或URL)
  TextColumn get content => text()();

  /// 消息类型: 0-文本, 1-图片, 2-文件, 3-语音, 4-视频, 5-位置, 6-名片, 7-系统消息, 8-合并消息, 9-表情包
  IntColumn get msgType => integer()();

  /// 消息状态: 0-发送中, 1-发送成功, 2-发送失败
  IntColumn get status => integer()();

  /// 发送时间(时间戳毫秒)
  IntColumn get timestamp => integer()();

  /// 本地存储路径(图片/视频/文件等富媒体消息的本地路径)
  TextColumn get localPath => text().nullable()();

  /// 消息序号(用于排序和去重，保证全局有序)
  IntColumn get msgSeq => integer().withDefault(const Constant(0))();

  /// 引用/回复的消息ID(实现消息引用功能)
  IntColumn get replyMsgId => integer().nullable()();

  /// @的用户ID列表(逗号分隔，如"1001,1002")
  TextColumn get atUserIds => text().withDefault(const Constant(''))();

  /// 扩展信息(JSON格式，存储消息特有属性，如图片尺寸、语音时长等)
  TextColumn get extra => text().nullable()();

  /// 阅读状态: 0-未读, 1-已读
  IntColumn get readStatus => integer().withDefault(const Constant(0))();
}
