import 'dart:async';

import '../utils/logger.dart';

class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final Map<Type, List<Function>> _listeners = {};
  final Map<Type, StreamController> _controllers = {};
  final Map<Type, DateTime> _lastActivityTime = {};

  static const Duration _cleanupThreshold = Duration(minutes: 30);

  final Logger _log = AppLogger.instance;

  T fire<T>(T event) {
    _updateActivityTime<T>();

    final listeners = _listeners[T];
    if (listeners != null) {
      for (var listener in listeners) {
        try {
          (listener as Function(T))(event);
        } catch (e) {
          _log.e('事件处理错误', error: e);
        }
      }
    }

    final controller = _controllers[T];
    if (controller != null && !controller.isClosed) {
      controller.add(event);
    }
    return event;
  }

  Stream<T> on<T>() {
    _updateActivityTime<T>();
    _controllers.putIfAbsent(T, () => StreamController<T>.broadcast());
    return (_controllers[T] as StreamController<T>).stream;
  }

  void subscribe<T>(Function(T) listener) {
    _updateActivityTime<T>();
    _listeners.putIfAbsent(T, () => []);
    if (!_listeners[T]!.contains(listener)) {
      _listeners[T]!.add(listener);
    }
  }

  void unsubscribe<T>(Function(T) listener) {
    _listeners[T]?.remove(listener);
  }

  void unsubscribeAll<T>() {
    _listeners.remove(T);
  }

  void clearListeners<T>() {
    _listeners.remove(T);
    final controller = _controllers[T];
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
    _controllers.remove(T);
    _lastActivityTime.remove(T);
  }

  void _updateActivityTime<T>() {
    _lastActivityTime[T] = DateTime.now();
  }

  void cleanupInactiveControllers() {
    final now = DateTime.now();
    final inactiveTypes = <Type>[];

    for (final entry in _lastActivityTime.entries) {
      if (now.difference(entry.value) > _cleanupThreshold) {
        inactiveTypes.add(entry.key);
      }
    }

    for (final type in inactiveTypes) {
      final listenerCount = _listeners[type]?.length ?? 0;
      if (listenerCount == 0) {
        _log.d('清理不活跃的事件控制器: $type');
        final controller = _controllers[type];
        if (controller != null && !controller.isClosed) {
          controller.close();
        }
        _controllers.remove(type);
        _lastActivityTime.remove(type);
      }
    }
  }

  int get listenerCount =>
      _listeners.values.fold(0, (sum, list) => sum + list.length);
  int get controllerCount => _controllers.length;

  void dispose() {
    for (var controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _listeners.clear();
    _lastActivityTime.clear();
  }
}
