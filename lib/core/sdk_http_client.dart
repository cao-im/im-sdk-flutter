import 'dart:convert';
import 'package:dio/dio.dart';
import '../utils/logger.dart';

/// SDK 内部 HTTP API 客户端
///
/// 封装 SDK 与服务端之间的 HTTP 通信，包括：
/// - Token 刷新接口
/// - 离线消息拉取等（可扩展）
///
/// 此类为 SDK 内部使用，不对外暴露
class SdkHttpClient {
  static const int _connectTimeoutSeconds = 10;
  static const int _receiveTimeoutSeconds = 10;

  final Logger _log = AppLogger.instance;

  late final Dio _dio;
  String _baseUrl = '';

  /// 获取当前配置的基础 URL
  String get baseUrl => _baseUrl;

  SdkHttpClient();

  /// 初始化 HTTP 客户端
  ///
  /// [serverUrl] 服务端地址（通常来自 IMConfig 的 serverUrl）
  /// 注意：serverUrl 可能是 ws:// 或 wss:// 协议，会自动转换为 http/https
  void init({required String serverUrl}) {
    final uri = Uri.parse(serverUrl);
    // 将 WebSocket 协议转换为 HTTP 协议
    final httpScheme = uri.scheme == 'wss' ? 'https' : 'http';
    _baseUrl = '$httpScheme://${uri.host}:${uri.port}';

    _log.i('[SdkHttpClient] 初始化, baseUrl: $_baseUrl (原始协议: ${uri.scheme} → $httpScheme)');

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: _connectTimeoutSeconds),
      receiveTimeout: const Duration(seconds: _receiveTimeoutSeconds),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  // ==================== Token 相关接口 ====================

  /// 刷新 Token
  ///
  /// 使用 RefreshToken 换取新的 AccessToken 和 RefreshToken
  ///
  /// [refreshToken] 刷新令牌
  ///
  /// 返回刷新结果：
  /// - success: 是否成功
  /// - accessToken: 新的访问令牌（如果成功）
  /// - refreshToken: 新的刷新令牌（如果成功）
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    _log.i('[SdkHttpClient] 🔄 发起 Token 刷新请求...');

    try {
      final response = await _dio.post(
        '/api/user/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      // 解析响应数据
      final data = _parseResponse(response.data);

      if (data['code'] == 200 && data['data'] != null) {
        final newAccessToken = data['data']['token'] as String?;
        final newRefreshToken = data['data']['refreshToken'] as String?;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          _log.i('[SdkHttpClient] ✅ Token 刷新成功');
          return {
            'success': true,
            'accessToken': newAccessToken,
            'refreshToken': newRefreshToken,
          };
        }
      }

      _log.e(
        '[SdkHttpClient] ❌ Token 刷新失败: code=${data['code']}, message=${data['message']}',
      );
      return {'success': false};
    } on DioException catch (e) {
      _log.e(
        '[SdkHttpClient] ❌ Token 刷新网络异常: type=${e.type}, message=${e.message}',
      );
      if (e.response?.data != null) {
        _log.e('[SdkHttpClient] ❌ 服务端响应: ${e.response?.data}');
      }
      return {'success': false};
    } catch (e) {
      _log.e('[SdkHttpClient] ❌ Token 刷新异常: $e');
      return {'success': false};
    }
  }

  // ==================== 离线消息相关接口（预留扩展）====================

  /// 拉取离线消息
  ///
  /// [token] 用户认证 Token
  /// [userId] 用户 ID
  Future<Map<String, dynamic>> fetchOfflineMessages(String token, int userId) async {
    try {
      final response = await _dio.get(
        '/api/message/offline',
        queryParameters: {'userId': userId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = _parseResponse(response.data);
      return {'success': true, 'data': data};
    } catch (e) {
      _log.e('[SdkHttpClient] 拉取离线消息失败: $e');
      return {'success': false};
    }
  }

  // ==================== 内部工具方法 ====================

  /// 解析服务端响应
  ///
  /// Dio 在某些情况下返回的是已解析的 Map，某些情况下是字符串
  /// 此方法统一处理两种情况
  dynamic _parseResponse(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return responseData;
    }
    if (responseData is String) {
      try {
        return jsonDecode(responseData);
      } catch (e) {
        _log.w('[SdkHttpClient] JSON 解析失败: $e');
        return {};
      }
    }
    return responseData ?? {};
  }
}
