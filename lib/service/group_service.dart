import '../model/group.dart';
import '../model/sender_info.dart';

abstract class GroupService {
  Future<Group> createGroup({
    required String name,
    String? avatar,
    List<int>? memberIds,
  });

  Future<Group> getGroup(int groupId);

  Future<List<Group>> getUserGroups(int userId);

  Future<void> dismissGroup(int groupId);

  Future<void> addGroupMembers({
    required int groupId,
    required List<int> userIds,
  });

  Future<void> removeGroupMember({required int groupId, required int userId});

  Future<void> transferOwner({required int groupId, required int newOwnerId});

  Future<Group> updateGroupInfo({
    required int groupId,
    String? name,
    String? avatar,
  });

  /// 根据消息中的 groupInfo 缓存群组信息（避免重复请求服务端）
  void cacheGroupFromInfo(GroupInfo groupInfo);

  /// 从缓存中获取群组信息（同步，无网络请求），未找到返回 null
  Group? getFromCache(int groupId);
}
