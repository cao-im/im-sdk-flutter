import 'dart:async';
import 'dart:convert';

import '../core/connection_manager.dart';
import '../core/exceptions.dart';
import '../event/event_bus.dart';
import '../event/im_event.dart';
import '../model/group.dart';
import '../model/sender_info.dart';
import '../storage/storage_interface.dart';
import '../utils/logger.dart';
import 'group_service.dart';

class GroupServiceImpl implements GroupService {
  final ConnectionManager _connectionManager;
  final StorageInterface _databaseHelper;
  final EventBus _eventBus;

  final Map<int, Group> _groupCache = {};
  Completer<Map<String, dynamic>>? _pendingResponse;
  StreamSubscription? _messageSubscription;

  static const int _requestTimeout = 30;

  final Logger _log = AppLogger.instance;

  GroupServiceImpl({
    required ConnectionManager connectionManager,
    required StorageInterface databaseHelper,
    required EventBus eventBus,
  }) : _connectionManager = connectionManager,
       _databaseHelper = databaseHelper,
       _eventBus = eventBus {
    _initMessageListener();
  }

  void _initMessageListener() {
    _messageSubscription?.cancel();
    _messageSubscription = _connectionManager.onMessage.listen(
      _handleServerMessage,
    );
  }

  void _handleServerMessage(Map<String, dynamic> message) {
    final type = message['type'] as String? ?? '';
    // 只拦截群组信息响应（包含 name/id 等字段），不拦截消息类响应（group_message/group_history/group_offline_sync）
    final isGroupInfoResponse = message.containsKey('name') || message.containsKey('memberIds');
    if (type.startsWith('group_') &&
        isGroupInfoResponse &&
        _pendingResponse != null &&
        !_pendingResponse!.isCompleted) {
      _pendingResponse!.complete(message);
      _pendingResponse = null;
    }
  }

  Future<Map<String, dynamic>> _sendRequest(
    Map<String, dynamic> request,
  ) async {
    if (!_connectionManager.isConnected) {
      throw IMException.network('未连接到服务器，请先建立连接');
    }

    _pendingResponse?.completeError(TimeoutException('上一个请求被覆盖'));
    _pendingResponse = Completer<Map<String, dynamic>>();

    try {
      _connectionManager.sendMessage(request);
      return await _pendingResponse!.future.timeout(
        Duration(seconds: _requestTimeout),
      );
    } on TimeoutException {
      _pendingResponse = null;
      throw IMException.timeout('群组操作请求超时（${_requestTimeout}秒）');
    } catch (e) {
      _pendingResponse = null;
      rethrow;
    }
  }

  void _validateGroupExists(Group? group, int groupId) {
    if (group == null) {
      throw IMException.notFound('群组不存在: groupId=$groupId');
    }
  }

  void _validateOwnerPermission(Group group, int currentUserId) {
    if (group.ownerId != currentUserId) {
      throw IMException.permission(
        '权限不足：只有群主才能执行此操作 | 当前用户ID: $currentUserId, 群主ID: ${group.ownerId}, 群组名称: ${group.name}',
      );
    }
  }

  void _validateMemberInGroup(Group group, int userId) {
    final memberIds = group.memberIds ?? [];
    if (!memberIds.contains(userId)) {
      throw IMException.params(
        '用户不在群组中，无法执行操作 | 用户ID: $userId, 群组ID: ${group.id}, 群组名称: ${group.name}',
      );
    }
  }

  Future<void> _cacheGroupLocally(Group group) async {
    _groupCache[group.id] = group;
    await _saveGroupToDb(group);
  }

  Future<void> _saveGroupToDb(Group group) async {
    try {
      _log.d('群组已缓存: ${group.id}');
    } catch (e) {
      _log.e('群组本地存储失败', error: e);
    }
  }

  Future<Group?> _loadGroupFromDb(int groupId) async {
    return null;
  }

  Future<List<int>> _getCurrentUserMemberGroups(int userId) async {
    return [];
  }

  Future<void> _removeGroupFromCache(int groupId) async {
    _groupCache.remove(groupId);
  }

  @override
  Future<Group> createGroup({
    required String name,
    String? avatar,
    List<int>? memberIds,
  }) async {
    if (name.trim().isEmpty) {
      throw IMException.params('群组名称不能为空');
    }

    final allMembers = <int>[...?memberIds];

    final request = {
      'type': 'group_create',
      'name': name.trim(),
      'avatar': avatar,
      'memberIds': allMembers,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final response = await _sendRequest(request);

    final success = response['success'] as bool? ?? false;
    if (!success) {
      final errorMsg = response['message'] as String? ?? '创建群组失败';
      throw IMException.server(-1, errorMsg);
    }

    final data = response['data'] as Map<String, dynamic>? ?? {};
    final group = Group.fromJson(data);

    await _cacheGroupLocally(group);

    _eventBus.fire(GroupCreatedEvent(group: group));

    return group;
  }

  @override
  Future<Group> getGroup(int groupId) async {
    if (groupId <= 0) {
      throw IMException.params('无效的群组ID: $groupId');
    }

    final cached = _groupCache[groupId];
    if (cached != null) {
      return cached;
    }

    final localGroup = await _loadGroupFromDb(groupId);
    if (localGroup != null) {
      _groupCache[groupId] = localGroup;
      return localGroup;
    }

    final request = {
      'type': 'group_get',
      'groupId': groupId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final response = await _sendRequest(request);

    final success = response['success'] as bool? ?? false;
    if (!success) {
      final errorMsg = response['message'] as String? ?? '获取群组信息失败';
      throw IMException.server(-1, errorMsg);
    }

    final data = response['data'] as Map<String, dynamic>? ?? {};
    final group = Group.fromJson(data);

    _groupCache[groupId] = group;
    await _saveGroupToDb(group);

    return group;
  }

  @override
  Future<List<Group>> getUserGroups(int userId) async {
    if (userId <= 0) {
      throw IMException.params('无效的用户ID: $userId');
    }

    final cachedGroups = _groupCache.values
        .where((g) => g.memberIds?.contains(userId) == true)
        .toList();

    if (cachedGroups.isNotEmpty) {
      return cachedGroups;
    }

    final request = {
      'type': 'group_list',
      'userId': userId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      final response = await _sendRequest(request);

      final success = response['success'] as bool? ?? false;
      if (!success) {
        final errorMsg = response['message'] as String? ?? '获取群组列表失败';
        throw IMException.server(-1, errorMsg);
      }

      final data = response['data'] as List<dynamic>? ?? [];
      final groups = <Group>[];

      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final group = Group.fromJson(item);
          groups.add(group);
          _groupCache[group.id] = group;
          await _saveGroupToDb(group);
        }
      }

      return groups;
    } catch (e) {
      if (e is StateError || e is TimeoutException || e is IMException) {
        rethrow;
      }

      final localGroupIds = await _getCurrentUserMemberGroups(userId);
      final localGroups = <Group>[];

      for (final gid in localGroupIds) {
        final group = await _loadGroupFromDb(gid);
        if (group != null) {
          localGroups.add(group);
          _groupCache[gid] = group;
        }
      }

      return localGroups;
    }
  }

  @override
  Future<void> dismissGroup(int groupId) async {
    if (groupId <= 0) {
      throw IMException.params('无效的群组ID: $groupId');
    }

    final group = await getGroup(groupId);
    _validateGroupExists(group, groupId);

    final request = {
      'type': 'group_dismiss',
      'groupId': groupId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final response = await _sendRequest(request);

    final success = response['success'] as bool? ?? false;
    if (!success) {
      final errorCode = response['code'] as int? ?? -1;
      final errorMsg = response['message'] as String? ?? '解散群组失败';

      if (errorCode == 403 || errorMsg.contains('权限')) {
        throw IMException.permission(
          '权限不足：只有群主才能解散群组 | 群组名称: ${group.name}, 群主ID: ${group.ownerId}',
        );
      }
      throw IMException.server(errorCode, errorMsg);
    }

    _eventBus.fire(GroupDismissedEvent(group: group));

    await _removeGroupFromCache(groupId);
  }

  @override
  Future<void> addGroupMembers({
    required int groupId,
    required List<int> userIds,
  }) async {
    if (groupId <= 0) {
      throw IMException.params('无效的群组ID: $groupId');
    }

    if (userIds.isEmpty) {
      throw IMException.params('待添加的成员列表不能为空');
    }

    final uniqueUserIds = userIds.toSet().toList();
    final group = await getGroup(groupId);
    _validateGroupExists(group, groupId);

    final existingMembers = group.memberIds ?? [];
    final newMembers = uniqueUserIds
        .where((id) => !existingMembers.contains(id))
        .toList();

    if (newMembers.isEmpty) {
      return;
    }

    final request = {
      'type': 'group_add_members',
      'groupId': groupId,
      'userIds': newMembers,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final response = await _sendRequest(request);

    final success = response['success'] as bool? ?? false;
    if (!success) {
      final errorMsg = response['message'] as String? ?? '添加群成员失败';
      throw IMException.server(-1, errorMsg);
    }

    final updatedMemberIds = [...existingMembers, ...newMembers];
    final updatedGroup = group.copyWith(
      memberCount: updatedMemberIds.length,
      memberIds: updatedMemberIds,
    );

    await _cacheGroupLocally(updatedGroup);

    for (final userId in newMembers) {
      _eventBus.fire(MemberJoinedEvent(group: updatedGroup, userId: userId));
    }
  }

  @override
  Future<void> removeGroupMember({
    required int groupId,
    required int userId,
  }) async {
    if (groupId <= 0) {
      throw IMException.params('无效的群组ID: $groupId');
    }

    if (userId <= 0) {
      throw IMException.params('无效的用户ID: $userId');
    }

    final group = await getGroup(groupId);
    _validateGroupExists(group, groupId);

    if (group.ownerId == userId) {
      throw IMException.invalidOperation(
        '无法移除群主 | 如需转让群主身份，请使用 transferOwner 方法 | 群组名称: ${group.name}',
      );
    }

    _validateMemberInGroup(group, userId);

    final request = {
      'type': 'group_remove_member',
      'groupId': groupId,
      'userId': userId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final response = await _sendRequest(request);

    final success = response['success'] as bool? ?? false;
    if (!success) {
      final errorCode = response['code'] as int? ?? -1;
      final errorMsg = response['message'] as String? ?? '移除群成员失败';

      if (errorCode == 403 || errorMsg.contains('权限')) {
        throw IMException.permission(
          '权限不足：只有群主或管理员可以移除成员 | 群组名称: ${group.name}',
        );
      }
      throw IMException.server(errorCode, errorMsg);
    }

    final updatedMemberIds = (group.memberIds ?? [])
        .where((id) => id != userId)
        .toList();
    final updatedGroup = group.copyWith(
      memberCount: updatedMemberIds.length,
      memberIds: updatedMemberIds,
    );

    await _cacheGroupLocally(updatedGroup);

    _eventBus.fire(MemberLeftEvent(group: updatedGroup, userId: userId));
  }

  @override
  Future<void> transferOwner({
    required int groupId,
    required int newOwnerId,
  }) async {
    if (groupId <= 0) {
      throw IMException.params('无效的群组ID: $groupId');
    }

    if (newOwnerId <= 0) {
      throw IMException.params('无效的新群主ID: $newOwnerId');
    }

    final group = await getGroup(groupId);
    _validateGroupExists(group, groupId);

    if (group.ownerId == newOwnerId) {
      throw IMException.params(
        '该用户已是群主，无需转让 | 群组名称: ${group.name}, 当前群主ID: ${group.ownerId}',
      );
    }

    _validateOwnerPermission(group, group.ownerId);

    _validateMemberInGroup(group, newOwnerId);

    final request = {
      'type': 'group_transfer_owner',
      'groupId': groupId,
      'newOwnerId': newOwnerId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final response = await _sendRequest(request);

    final success = response['success'] as bool? ?? false;
    if (!success) {
      final errorCode = response['code'] as int? ?? -1;
      final errorMsg = response['message'] as String? ?? '转让群主失败';

      if (errorCode == 403 || errorMsg.contains('权限')) {
        throw IMException.permission(
          '权限不足：只有当前群主才能转让群主身份 | 群组名称: ${group.name}, 当前群主ID: ${group.ownerId}',
        );
      }
      throw IMException.server(errorCode, errorMsg);
    }

    final updatedGroup = group.copyWith(ownerId: newOwnerId);

    await _cacheGroupLocally(updatedGroup);
  }

  @override
  Future<Group> updateGroupInfo({
    required int groupId,
    String? name,
    String? avatar,
  }) async {
    if (groupId <= 0) {
      throw IMException.params('无效的群组ID: $groupId');
    }

    if (name != null && name.trim().isEmpty) {
      throw IMException.params('群组名称不能为空字符串');
    }

    final group = await getGroup(groupId);
    _validateGroupExists(group, groupId);

    final trimmedName = name?.trim();

    final updates = <String, dynamic>{};
    if (trimmedName != null && trimmedName != group.name) {
      updates['name'] = trimmedName;
    }
    if (avatar != null && avatar != group.avatar) {
      updates['avatar'] = avatar;
    }

    if (updates.isEmpty) {
      return group;
    }

    final request = {
      'type': 'group_update_info',
      'groupId': groupId,
      ...updates,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final response = await _sendRequest(request);

    final success = response['success'] as bool? ?? false;
    if (!success) {
      final errorCode = response['code'] as int? ?? -1;
      final errorMsg = response['message'] as String? ?? '更新群组信息失败';

      if (errorCode == 403 || errorMsg.contains('权限')) {
        throw IMException.permission(
          '权限不足：只有群主或管理员可以更新群组信息 | 群组名称: ${group.name}',
        );
      }
      throw IMException.server(errorCode, errorMsg);
    }

    final updatedGroup = group.copyWith(
      name: trimmedName ?? group.name,
      avatar: avatar ?? group.avatar,
    );

    await _cacheGroupLocally(updatedGroup);

    return updatedGroup;
  }

  @override
  void cacheGroupFromInfo(GroupInfo groupInfo) {
    final groupId = groupInfo.groupId;
    if (groupId <= 0 || groupInfo.groupName.isEmpty) return;

    // 如果缓存中已存在且名称非空，不覆盖（已有更完整的信息）
    final existing = _groupCache[groupId];
    if (existing != null && existing.name.isNotEmpty) return;

    final group = Group(
      id: groupId,
      name: groupInfo.groupName,
      avatar: groupInfo.groupAvatar,
      ownerId: 0, // groupInfo 中没有 ownerId，后续可通过 getGroup 获取完整信息
      memberCount: 0,
    );
    _groupCache[groupId] = group;
    _log.d('群组信息已从消息中缓存: groupId=$groupId, name=${groupInfo.groupName}');
  }

  @override
  Group? getFromCache(int groupId) {
    return _groupCache[groupId];
  }

  void clearCache() {
    _groupCache.clear();
  }

  void dispose() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _pendingResponse?.completeError(StateError('服务已释放'));
    _pendingResponse = null;
    clearCache();
  }
}
