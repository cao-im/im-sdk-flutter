import 'dart:convert';
import 'sdk_http_client.dart';
import '../utils/logger.dart';

/// Token 管理器
///
/// 负责 SDK 的 Token 生命周期管理，包括：
/// - 存储 AccessToken 和 RefreshToken
/// - 自动检测 Token 过期状态
/// - 使用 RefreshToken 刷新 AccessToken
/// - JWT 过期时间解析和日志输出
///
/// 使用方式：
/// ```dart
/// // 初始化（在 IMClient.init 中调用）
/// TokenManager().init(serverUrl: serverUrl);
///
/// // 设置 Token（在 IMClient.connect 中调用）
/// TokenManager().setTokens(accessToken: 'xxx', refreshToken: 'yyy');
///
/// // 刷新 Token（SDK 内部自动调用）
/// await TokenManager().refresh();
/// ```
class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  final Logger _log = AppLogger.instance;

  /// HTTP 客户端，用于与服务端通信（Token 刷新等）
  final SdkHttpClient _httpClient = SdkHttpClient();

  String? _accessToken;
  String? _refreshToken;
  String _serverUrl = '';

  bool _isRefreshing = false;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  /// 初始化 TokenManager
  ///
  /// [serverUrl] 服务端地址，用于构建 HTTP 请求的 baseUrl
  void init({required String serverUrl}) {
    _serverUrl = serverUrl;
    _httpClient.init(serverUrl: serverUrl);
    _log.i('[TokenManager] 初始化, serverUrl: $serverUrl');
  }

  /// 设置 Token 对
  ///
  /// [accessToken] 访问令牌，用于 API 认证
  /// [refreshToken] 刷新令牌，用于获取新的 AccessToken
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

  /// 清除所有 Token
  void clear() {
    _accessToken = null;
    _refreshToken = null;
    _log.i('[TokenManager] Token已清除');
  }

  /// 是否有有效的 AccessToken
  bool get hasValidToken => _accessToken != null && _accessToken!.isNotEmpty;

  /// 是否有 RefreshToken
  bool get hasRefreshToken => _refreshToken != null && _refreshToken!.isNotEmpty;

  // ==================== Token 刷新 ====================

  /// 刷新 Token
  ///
  /// 使用 RefreshToken 向服务端请求新的 Token 对。
  /// 内部有防重复刷新机制（_isRefreshing 标志位）。
  ///
  /// 返回 true 表示刷新成功，false 表示失败
  Future<bool> refresh() async {
    if (_isRefreshing) {
      _log.w('[TokenManager] 正在刷新中，跳过重复请求');
      return false;
    }

    if (_refreshToken == null || _refreshToken!.isEmpty) {
      _log.e('[TokenManager] ❌ 无法刷新: 无RefreshToken');
      return false;
    }

    // 打印 RefreshToken 的过期详情，方便排查
    _log.i('[TokenManager] 🔄 开始刷新Token...');
    _logTokenExpiry('RefreshToken(用于刷新)', _refreshToken!);

    _isRefreshing = true;

    try {
      // 委托给 SdkHttpClient 执行 HTTP 请求
      final result = await _httpClient.refreshToken(_refreshToken!);

      if (result['success'] == true) {
        final newAccessToken = result['accessToken'] as String?;
        final newRefreshToken = result['refreshToken'] as String?;

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

      _log.e('[TokenManager] ❌ Token刷新失败');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  // ==================== Token 过期检查 ====================

  /// 解析 JWT 的过期信息并返回描述字符串
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

  /// 打印 Token 过期信息到日志
  void _logTokenExpiry(String label, String token) {
    final info = _parseTokenExpiry(label, token);
    _log.i('[TokenManager] 🔍 $label 过期状态: $info');
  }

  /// 检查 Token 是否即将过期
  ///
  /// [thresholdHours] 过期阈值（默认24小时内算即将过期）
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

  /// 获取有效的 Token（如果即将过期则自动刷新）
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

  /// 连接前确保 Token 有效
  ///
  /// 如果 AccessToken 即将过期（<1小时），自动刷新
  Future<void> ensureValidTokenBeforeConnect() async {
    if (!hasValidToken) {
      _log.e('[TokenManager] ❌ 无法连接: 无可用AccessToken');
      throw StateError('无法连接: 无可用Token');
    }

    // 打印当前 AccessToken 状态
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

  /// 获取调试信息（用于排查问题）
  Map<String, dynamic> getDebugInfo() {
    return {
      'hasAccessToken': hasValidToken,
      'hasRefreshToken': hasRefreshToken,
      'accessTokenLength': _accessToken?.length ?? 0,
      'refreshTokenLength': _refreshToken?.length ?? 0,
      'isRefreshing': _isRefreshing,
      'serverUrl': _serverUrl,
      'isExpiringSoon': isTokenExpiringSoon(),
      'accessTokenExpiry':
          _accessToken != null ? _parseTokenExpiry('AccessToken', _accessToken!) : 'null',
      'refreshTokenExpiry':
          _refreshToken != null ? _parseTokenExpiry('RefreshToken', _refreshToken!) : 'null',
    };
  }
}
