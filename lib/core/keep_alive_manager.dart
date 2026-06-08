import 'dart:io';

import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../utils/logger.dart';

/// IM进程保活管理器
/// 
/// 跨平台保活方案：
/// - Android：Foreground Service + Wakelock + 通知权限动态申请
/// - iOS：Audio Session + 静音音频 + Background Task + Wakelock
class KeepAliveManager {
  static const MethodChannel _channel =
      MethodChannel('com.clb.caoim/keep_alive');

  bool _isActive = false;
  bool _notificationPermissionGranted = false;
  final Logger _log = AppLogger.instance;

  bool get isActive => _isActive;
  
  /// Android通知权限是否已授予（仅Android有效）
  bool get isNotificationPermissionGranted => _notificationPermissionGranted;

  /// 启动保活机制
  /// 应在IM连接建立成功后调用
  Future<bool> start() async {
    if (_isActive) {
      _log.d('[KeepAlive] 保活已在运行中，跳过');
      return true;
    }

    _log.i('[KeepAlive] ====== 启动进程保活 ======');

    try {
      // 1. 启动Wakelock（防止CPU/屏幕休眠导致断连）
      await WakelockPlus.enable();
      _log.i('[KeepAlive] ✅ Wakelock 已启用');

      // 2. 根据平台启动原生保活服务
      if (Platform.isAndroid) {
        // 2a. 先请求通知权限（Android 13+ 必须动态申请）
        await _requestNotificationPermission();

        // 2b. 启动前台服务（即使权限未授权也启动，服务本身可运行但通知可能不显示）
        final hasPermission = await _channel.invokeMethod<bool>('startKeepAlive');
        if (hasPermission == true) {
          _notificationPermissionGranted = true;
          _log.i('[KeepAlive] ✅ Android Foreground Service 已启动（含通知权限）');
        } else {
          _notificationPermissionGranted = false;
          _log.w('[KeepAlive] ⚠️ Android Foreground Service 已启动（无通知权限，通知栏不显示）');
        }
      } else if (Platform.isIOS) {
        await _channel.invokeMethod('startKeepAlive');
        _log.i('[KeepAlive] ✅ iOS Audio Session + Background Task 已启动');
      }

      _isActive = true;
      _log.i('[KeepAlive] ====== 进程保活已全部启用 ======');
      return true;
    } on PlatformException catch (e) {
      _log.e('[KeepAlive] ❌ 启动保活失败: ${e.message}', error: e);
      return false;
    } catch (e) {
      _log.e('[KeepAlive] ❌ 启动保活异常: $e', error: e);
      return false;
    }
  }

  /// 停止保活机制
  /// 应在IM断开连接或用户退出登录时调用
  Future<bool> stop() async {
    if (!_isActive) {
      _log.d('[KeepAlive] 保活未运行，跳过停止');
      return true;
    }

    _log.i('[KeepAlive] ====== 停止进程保活 ======');

    try {
      // 1. 停止原生保活服务
      if (Platform.isAndroid || Platform.isIOS) {
        await _channel.invokeMethod('stopKeepAlive');
        _log.i('[KeepAlive] ✅ 平台保活服务已停止');
      }

      // 2. 释放Wakelock
      await WakelockPlus.disable();
      _log.i('[KeepAlive] ✅ Wakelock 已释放');

      _isActive = false;
      _log.i('[KeepAlive] ====== 进程保活已全部停止 ======');
      return true;
    } on PlatformException catch (e) {
      _log.e('[KeepAlive] ❌ 停止保活失败: ${e.message}', error: e);
      return false;
    } catch (e) {
      _log.e('[KeepAlive] ❌ 停止保活异常: $e', error: e);
      return false;
    }
  }

  /// 检查通知权限状态（仅Android有效）
  /// 返回：true=已授权, false=未授权, null=非Android平台
  Future<bool?> checkNotificationPermission() async {
    if (!Platform.isAndroid) return null;
    try {
      final granted = await _channel.invokeMethod<bool>('checkNotificationPermission');
      _notificationPermissionGranted = granted ?? false;
      return granted;
    } catch (e) {
      _log.w('[KeepAlive] 检查通知权限失败: $e');
      return null;
    }
  }

  /// 请求通知权限（仅Android 13+ 需要调用）
  /// 返回：true=已授权/无需请求, "pending"=等待用户选择, null=非Android平台
  Future<dynamic> requestNotificationPermission() async {
    return _requestNotificationPermission();
  }

  /// 内部方法：请求通知权限
  Future<dynamic> _requestNotificationPermission() async {
    if (!Platform.isAndroid) return null;

    try {
      // 先检查是否已有权限
      final alreadyGranted = await _channel.invokeMethod<bool>('checkNotificationPermission');
      if (alreadyGranted == true) {
        _notificationPermissionGranted = true;
        _log.i('[KeepAlive] ✅ 通知权限已拥有');
        return true;
      }

      // 无权限则弹出系统权限对话框
      _log.i('[KeepAlive] 📋 正在请求通知权限...');
      final result = await _channel.invokeMethod<dynamic>('requestNotificationPermission');

      if (result == true || result == 'granted') {
        _notificationPermissionGranted = true;
        _log.i('[KeepAlive] ✅ 用户已授予通知权限');
      } else if (result == 'pending') {
        _log.i('[KeepAlive] ⏳ 等待用户响应通知权限请求...');
        // 权限请求是异步的，短暂延迟后再次检查
        await Future.delayed(const Duration(milliseconds: 500));
        final recheck = await checkNotificationPermission();
        _notificationPermissionGranted = recheck ?? false;
      } else {
        _notificationPermissionGranted = false;
        _log.w('[KeepAlive] ⚠️ 用户拒绝通知权限，前台服务将不显示通知');
      }

      return result;
    } catch (e) {
      _log.e('[KeepAlive] 请求通知权限异常: $e', error: e);
      return null;
    }
  }

  /// 获取当前保活状态信息
  Map<String, dynamic> getDebugInfo() {
    return {
      'isActive': _isActive,
      'platform': Platform.operatingSystem,
      'notificationPermissionGranted': _notificationPermissionGranted,
    };
  }

  void dispose() {
    stop();
  }
}
