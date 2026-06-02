import 'package:drift/drift.dart';

/// 联系人表（好友列表）
/// 功能: 存储用户的好友/联系人信息，支持备注、在线状态等
class Contacts extends Table {
  /// 联系人ID(对应服务端im_user.id)
  IntColumn get id => integer()();

  /// IM用户名(登录账号)
  TextColumn get username => text()();

  /// 昵称(显示名称，优先级低于remark)
  TextColumn get nickname => text().withDefault(const Constant(''))();

  /// 头像URL
  TextColumn get avatar => text().withDefault(const Constant(''))();

  /// 个性签名
  TextColumn get signature => text().nullable()();

  /// 性别: 0-未知, 1-男, 2-女
  IntColumn get gender => integer().withDefault(const Constant(0))();

  /// 所在地
  TextColumn get location => text().withDefault(const Constant(''))();

  /// 手机号
  TextColumn get phone => text().withDefault(const Constant(''))();

  /// 邮箱
  TextColumn get email => text().withDefault(const Constant(''))();

  /// 在线状态: 0-离线, 1-在线, 2-忙碌, 3-隐身
  IntColumn get onlineStatus => integer().withDefault(const Constant(0))();

  /// 最后在线时间(时间戳毫秒)
  IntColumn get lastOnlineTime => integer().nullable()();

  /// 备注名(可自定义显示名称，优先显示)
  TextColumn get remark => text().withDefault(const Constant(''))();

  /// 好友状态: 0-正常, 1-已删除
  IntColumn get status => integer().withDefault(const Constant(0))();

  /// 添加来源: 0-搜索, 1-群聊, 2-二维码, 3-名片分享, 4-通讯录
  IntColumn get source => integer().withDefault(const Constant(0))();

  /// 用户ID(联系人所有者，即当前登录用户ID)
  IntColumn get userId => integer().withDefault(const Constant(0))();

  /// 建立好友关系的时间(时间戳毫秒)
  IntColumn get createTime => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
