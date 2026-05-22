import '../model/group.dart';

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
}
