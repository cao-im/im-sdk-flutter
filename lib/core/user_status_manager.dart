import 'dart:async';

import '../model/user.dart';
import '../event/event_bus.dart';
import '../event/im_event.dart';
import '../utils/logger.dart';
import 'connection_manager.dart';

enum PresenceStatus { online, away, busy, offline, invisible }

class UserStatusManager {
  final ConnectionManager _connectionManager;
  final EventBus _eventBus;
  final int _currentUserId;

  final Map<int, UserStatus> _userStatusMap = {};
  static const int _maxCacheSize = 1000;

  PresenceStatus _myPresence = PresenceStatus.online;
  Timer? _presenceBroadcastTimer;

  final Function(User user, UserStatus status)? onUserStatusChanged;

  static const int _broadcastIntervalSec = 60;

  final Logger _log = AppLogger.instance;

  UserStatusManager({
    required ConnectionManager connectionManager,
    required EventBus eventBus,
    required int currentUserId,
    this.onUserStatusChanged,
  }) : _connectionManager = connectionManager,
       _eventBus = eventBus,
       _currentUserId = currentUserId;

  void init() {
    _startPresenceBroadcast();
    _eventBus.subscribe<UserPresenceEvent>(_handleUserPresenceChange);
  }

  Future<void> setPresence(PresenceStatus status) async {
    _myPresence = status;
    await _broadcastMyPresence();

    if (status == PresenceStatus.offline) {
      _stopPresenceBroadcast();
    } else {
      _restartPresenceBroadcast();
    }
  }

  Future<void> _broadcastMyPresence() async {
    try {
      _connectionManager.sendMessage({
        'type': 'presence_update',
        'userId': _currentUserId,
        'status': _myPresence.index,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      _log.e('[UserStatusManager] 广播状态失败', error: e);
    }
  }

  void _startPresenceBroadcast() {
    _stopPresenceBroadcast();
    _presenceBroadcastTimer = Timer.periodic(
      const Duration(seconds: _broadcastIntervalSec),
      (_) => _broadcastMyPresence(),
    );
  }

  void _stopPresenceBroadcast() {
    _presenceBroadcastTimer?.cancel();
    _presenceBroadcastTimer = null;
  }

  void _restartPresenceBroadcast() {
    _stopPresenceBroadcast();
    _startPresenceBroadcast();
  }

  UserStatus? getUserStatus(int userId) {
    return _userStatusMap[userId];
  }

  Map<int, UserStatus> getUsersStatus(List<int> userIds) {
    return Map.fromEntries(
      userIds
          .where((id) => _userStatusMap.containsKey(id))
          .map((id) => MapEntry(id, _userStatusMap[id]!)),
    );
  }

  bool isUserOnline(int userId) {
    final status = _userStatusMap[userId];
    return status != null && status == UserStatus.online;
  }

  List<int> getOnlineFriends() {
    return _userStatusMap.entries
        .where((entry) => entry.value == UserStatus.online)
        .map((entry) => entry.key)
        .toList();
  }

  int get cachedUserCount => _userStatusMap.length;

  void _handleUserPresenceChange(UserPresenceEvent event) {
    final oldStatus = _userStatusMap[event.user.id];
    _userStatusMap[event.user.id] = event.user.status;

    _enforceCacheLimit();

    onUserStatusChanged?.call(event.user, event.user.status);

    if (oldStatus != event.user.status) {
      if (event.user.status == UserStatus.online) {
        _eventBus.fire(UserOnlineEvent(user: event.user));
      } else {
        _eventBus.fire(UserOfflineEvent(user: event.user));
      }
    }
  }

  void _enforceCacheLimit() {
    if (_userStatusMap.length <= _maxCacheSize) return;
    final keysToRemove = _userStatusMap.keys
        .take(_userStatusMap.length - _maxCacheSize)
        .toList();
    for (final key in keysToRemove) {
      _userStatusMap.remove(key);
    }
  }

  void clearAll() {
    _userStatusMap.clear();
  }

  void removeUser(int userId) {
    _userStatusMap.remove(userId);
  }

  PresenceStatus get myPresence => _myPresence;

  void resumeAfterReconnect() {
    _broadcastMyPresence();
    _restartPresenceBroadcast();
  }

  void dispose() {
    _stopPresenceBroadcast();
    _eventBus.unsubscribe<UserPresenceEvent>(_handleUserPresenceChange);
    _userStatusMap.clear();
  }
}
