import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../utils/logger.dart';

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  final Logger _log = AppLogger.instance;

  String? _accessToken;
  String? _refreshToken;
  String _serverUrl = '';

  bool _isRefreshing = false;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  void init({required String serverUrl}) {
    _serverUrl = serverUrl;
    _log.i('[TokenManager] 初始化, serverUrl: $serverUrl');
  }

  void setTokens({
    required String accessToken,
    String? refreshToken,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _log.i('[TokenManager] Token已设置');
    _log.d('[TokenManager] AccessToken长度: ${accessToken.length}');
    if (refreshToken != null) {
      _log.d('[TokenManager] RefreshToken长度: ${refreshToken!.length}');
    }
  }

  void clear() {
    _accessToken = null;
    _refreshToken = null;
    _log.i('[TokenManager] Token已清除');
  }

  bool get hasValidToken => _accessToken != null && _accessToken!.isNotEmpty;

  bool get hasRefreshToken => _refreshToken != null && _refreshToken!.isNotEmpty;

  Future<bool> refresh() async {
    if (_isRefreshing) {
      _log.w('[TokenManager] 正在刷新中，跳过重复请求');
      return false;
    }

    if (_refreshToken == null || _refreshToken!.isEmpty) {
      _log.e('[TokenManager] 无法刷新: 无RefreshToken');
      return false;
    }

    _isRefreshing = true;
    
    try {
      final uri = Uri.parse(_serverUrl);
      final baseUrl = '${uri.scheme}://${uri.host}:${uri.port}';
      
      _log.i('[TokenManager] 开始刷新Token...');
      _log.d('[TokenManager] 请求地址: $baseUrl/api/user/refresh-token');

      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ));

      final response = await dio.post(
        '/api/user/refresh-token',
        data: {'refreshToken': _refreshToken},
      );

      final data = jsonDecode(response.data.toString());
      
      if (data['code'] == 200 && data['data'] != null) {
        final newAccessToken = data['data']['token'] as String?;
        final newRefreshToken = data['data']['refreshToken'] as String?;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          _accessToken = newAccessToken;
          
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            _refreshToken = newRefreshToken;
          }

          _log.i('[TokenManager] ✅ Token刷新成功');
          _log.d('[TokenManager] 新AccessToken长度: ${_accessToken!.length}');
          return true;
        }
      }

      _log.e('[TokenManager] ❌ Token刷新失败: ${data['message']}');
      return false;
    } catch (e) {
      _log.e('[TokenManager] ❌ Token刷新异常: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  bool isTokenExpiringSoon({int thresholdHours = 24}) {
    if (_accessToken == null || _accessToken!.isEmpty) {
      return true;
    }

    try {
      final parts = _accessToken!.split('.');
      if (parts.length != 3) {
        return true;
      }

      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      final claims = jsonDecode(decoded);

      final exp = claims['exp'] as int?;
      if (exp == null) {
        return true;
      }

      final expDateTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      final remaining = expDateTime.difference(now);

      _log.d('[TokenManager] Token剩余时间: ${remaining.inHours}小时${remaining.inMinutes % 60}分钟');

      return remaining.inHours < thresholdHours;
    } catch (e) {
      _log.e('[TokenManager] 检查Token过期时间失败: $e');
      return true;
    }
  }

  Future<String> getValidToken() async {
    if (!hasValidToken) {
      throw StateError('无可用Token');
    }

    if (isTokenExpiringSoon()) {
      _log.i('[TokenManager] Token即将过期，自动刷新...');
      final success = await refresh();
      
      if (!success) {
        throw Exception('Token刷新失败');
      }
    }

    return _accessToken!;
  }

  Future<void> ensureValidTokenBeforeConnect() async {
    if (!hasValidToken) {
      throw StateError('无法连接: 无可用Token');
    }

    if (isTokenExpiringSoon(thresholdHours: 1)) {
      _log.i('[TokenManager] 连接前检查: Token即将过期，先刷新...');
      final success = await refresh();
      
      if (!success) {
        _log.w('[TokenManager] 刷新失败，尝试使用当前Token连接');
      }
    }
  }

  Map<String, dynamic> getDebugInfo() {
    return {
      'hasAccessToken': hasValidToken,
      'hasRefreshToken': hasRefreshToken,
      'accessTokenLength': _accessToken?.length ?? 0,
      'refreshTokenLength': _refreshToken?.length ?? 0,
      'isRefreshing': _isRefreshing,
      'serverUrl': _serverUrl,
      'isExpiringSoon': isTokenExpiringSoon(),
    };
  }
}
