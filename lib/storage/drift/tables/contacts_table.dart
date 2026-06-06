import 'package:drift/drift.dart';

/// 联系人表（好友列表）
class Contacts extends Table {
  /// 本地记录ID（自增，无业务含义，不存储服务端返回的任何ID）
  IntColumn get id => integer().autoIncrement()();

  /// IM用户名(登录账号)
  TextColumn get username => text()();

  /// 昵称(显示名称，优先级低于remark)
  TextColumn get nickname => text().withDefault(const Constant(''))();

  /// 头像URL
  TextColumn get avatar => text()();

  /// 个性签名
  TextColumn get signature => text().nullable()();

  /// 性别: 0-未知, 1-男, 2-女
  IntColumn get gender => integer().withDefault(const Constant(0))();

  /// 所在地
  TextColumn get location => text()();

  /// 手机号
  TextColumn get phone => text()();

  /// 邮箱
  TextColumn get email => text()();

  /// 在线状态: 0-离线, 1-在线, 2-忙碌, 3-隐身
  IntColumn get onlineStatus => integer().withDefault(const Constant(0))();

  /// 最后在线时间(时间戳毫秒)
  IntColumn get lastOnlineTime => integer().nullable()();

  /// 备注名(可自定义显示名称，优先显示)
  TextColumn get remark => text()();

  /// 好友状态: 0-正常, 1-已删除
  IntColumn get status => integer().withDefault(const Constant(0))();

  /// 添加来源: 0-搜索, 1-群聊, 2-二维码, 3-名片分享, 4-通讯录
  IntColumn get source => integer().withDefault(const Constant(0))();

  /// 用户ID（对应服务端 contactUserId / im_user.id，真正的聊天对象ID）
  IntColumn get userId => integer().withDefault(const Constant(0))();

  /// 建立好友关系的时间(时间戳毫秒)
  IntColumn get createTime => integer()();
}
