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
    // 设置时立即打印两个Token的过期信息
    _logTokenExpiry('AccessToken', accessToken);
    if (refreshToken != null) {
      _logTokenExpiry('RefreshToken', refreshToken!);
    }
  }

  void clear() {
    _accessToken = null;
    _refreshToken = null;
    _log.i('[TokenManager] Token已清除');
  }

  bool get hasValidToken => _accessToken != null && _accessToken!.isNotEmpty;

  bool get hasRefreshToken => _refreshToken != null && _refreshToken!.isNotEmpty;

  /// 解析JWT的过期信息并返回描述字符串
  String _parseTokenExpiry(String tokenLabel, String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return '(无法解析: 非标准JWT格式)';

      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      final claims = jsonDecode(decoded);

      final exp = claims['exp'] as int?;
      final iat = claims['iat'] as int?;
      final type = claims['type'] as String?;
      final userId = claims['userId'];

      if (exp == null) return '(无exp字段)';

      final expDateTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      final diff = expDateTime.difference(now);

      final typeInfo = type != null ? ', type=$type' : '';
      final iatInfo = iat != null ? ', 签发=${DateTime.fromMillisecondsSinceEpoch(iat * 1000)}' : '';

      if (diff.isNegative) {
        return '已过期 ${-diff.inMinutes}分${diff.inSeconds % 60}秒$typeInfo$iatInfo, userId=$userId';
      } else {
        return '剩余 ${diff.inDays}天${diff.inHours % 24}小时${diff.inMinutes % 60}分钟$typeInfo$iatInfo, userId=$userId';
      }
    } catch (e) {
      return '(解析失败: $e)';
    }
  }

  /// 打印Token过期信息到日志
  void _logTokenExpiry(String label, String token) {
    final info = _parseTokenExpiry(label, token);
    _log.i('[TokenManager] 🔍 $label 过期状态: $info');
  }

  Future<bool> refresh() async {
    if (_isRefreshing) {
      _log.w('[TokenManager] 正在刷新中，跳过重复请求');
      return false;
    }

    if (_refreshToken == null || _refreshToken!.isEmpty) {
      _log.e('[TokenManager] ❌ 无法刷新: 无RefreshToken');
      return false;
    }

    // 🔑 打印RefreshToken的过期详情，方便排查
    _log.i('[TokenManager] 🔄 开始刷新Token...');
    _logTokenExpiry('RefreshToken(用于刷新)', _refreshToken!);

    _isRefreshing = true;

    try {
      final uri = Uri.parse(_serverUrl);
      // 🔑 将 ws/wss 协议转换为 http/https（_serverUrl 是 WebSocket 地址，HTTP 请求需要转换协议）
      final httpScheme = uri.scheme == 'wss' ? 'https' : 'http';
      final baseUrl = '$httpScheme://${uri.host}:${uri.port}';

      _log.d('[TokenManager] 请求地址: $baseUrl/api/user/refresh-token (原始协议: ${uri.scheme} → 转换为: $httpScheme)');

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

      // Dio 已自动将 JSON 响应解析为 Map，无需再 jsonDecode
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : jsonDecode(response.data is String ? response.data : response.data.toString());

      if (data['code'] == 200 && data['data'] != null) {
        final newAccessToken = data['data']['token'] as String?;
        final newRefreshToken = data['data']['refreshToken'] as String?;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          _accessToken = newAccessToken;

          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            _refreshToken = newRefreshToken;
          }

          _log.i('[TokenManager] ✅ Token刷新成功');
          _logTokenExpiry('新AccessToken', _accessToken!);
          if (newRefreshToken != null) {
            _logTokenExpiry('新RefreshToken', newRefreshToken);
          }
          return true;
        }
      }

      _log.e('[TokenManager] ❌ Token刷新失败: code=${data['code']}, message=${data['message']}');
      return false;
    } on DioException catch (e) {
      _log.e('[TokenManager] ❌ Token刷新网络异常: type=${e.type}, message=${e.message}, response=${e.response?.statusCode}');
      if (e.response?.data != null) {
        _log.e('[TokenManager] ❌ 服务端响应: ${e.response?.data}');
      }
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

      if (remaining.isNegative) {
        _log.w('[TokenManager] ⚠️ AccessToken 已过期: ${-remaining.inMinutes}分${remaining.inSeconds % 60}秒前过期');
      } else {
        _log.d('[TokenManager] AccessToken 剩余时间: ${remaining.inHours}小时${remaining.inMinutes % 60}分钟');
      }

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
      _log.e('[TokenManager] ❌ 无法连接: 无可用AccessToken');
      throw StateError('无法连接: 无可用Token');
    }

    // 打印当前AccessToken状态
    _logTokenExpiry('连接前检查 AccessToken', _accessToken!);
    if (_refreshToken != null) {
      _logTokenExpiry('连接前检查 RefreshToken', _refreshToken!);
    }

    if (isTokenExpiringSoon(thresholdHours: 1)) {
      _log.i('[TokenManager] 🔄 连接前检查: AccessToken即将过期或已过期，先刷新...');
      final success = await refresh();

      if (success) {
        _log.i('[TokenManager] ✅ 刷新成功，将使用新Token连接');
      } else {
        _log.w('[TokenManager] ❌ 刷新失败！将尝试使用(可能已过期的)旧Token连接，可能再次失败');
      }
    } else {
      _log.i('[TokenManager] ✅ AccessToken仍然有效，无需刷新');
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
      'accessTokenExpiry': _accessToken != null ? _parseTokenExpiry('AccessToken', _accessToken!) : 'null',
      'refreshTokenExpiry': _refreshToken != null ? _parseTokenExpiry('RefreshToken', _refreshToken!) : 'null',
    };
  }
}
