import 'package:dio/dio.dart';
import '../client/im_client.dart';
import '../model/conversation.dart' as model_conv;
import '../model/message.dart' as model;
import '../utils/network_log_interceptor.dart';
import 'storage_interface.dart';

class ApiStorage implements StorageInterface {
  static final ApiStorage _instance = ApiStorage._internal();
  factory ApiStorage() => _instance;
  ApiStorage._internal();

  late Dio _dio;
  late String _baseUrl;
  String? _token;

  @override
  Future<void> init({int? userId}) async {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(NetworkLogInterceptor());

    final client = IMClient.instance;
    _baseUrl = client.serverUrl.replaceFirst('ws://', 'http://').replaceFirst('wss://', 'https://');
    _token = client.token;
    
    print('[ApiStorage] ✓ 初始化完成 (API模式)');
  }

  void updateToken(String? token) {
    _token = token;
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    }
  }

  Future<Map<String, dynamic>> _request(String method, String endpoint, {Map<String, dynamic>? data}) async {
    try {
      Response response;
      final url = '$_baseUrl/api/v1$endpoint';

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _dio.get(url, queryParameters: data);
          break;
        case 'POST':
          response = await _dio.post(url, data: data);
          break;
        case 'PUT':
          response = await _dio.put(url, data: data);
          break;
        case 'DELETE':
          response = await _dio.delete(url, queryParameters: data);
          break;
        default:
          throw Exception('不支持的HTTP方法: $method');
      }

      return response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : {'data': response.data};
    } on DioException catch (e) {
      print('[ApiStorage] ✗ 请求失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> insertMessage(model.Message message) async {
    final result = await _request('POST', '/messages', data: message.toJson());
    return result['data']['id'] ?? result['id'] ?? 0;
  }

  @override
  Future<List<model.Message>> getMessages({
    required int targetId,
    int? groupId,
    int? currentUserId,
    int page = 1,
    int size = 20,
  }) async {
    final params = {
      'targetId': targetId,
      'page': page,
      'size': size,
      if (groupId != null) 'groupId': groupId,
      if (currentUserId != null) 'currentUserId': currentUserId,
    };

    final result = await _request('GET', '/messages', data: params);
    final List<dynamic> messagesJson = result['data'] ?? result['messages'] ?? [];
    
    print('📥 [ApiStorage.getMessages] 离线消息原始数据: $messagesJson');
    
    return messagesJson.map((json) => model.Message.fromJson(json)).toList();
  }

  @override
  Future<model.Message?> getLastMessage(int targetId, {int? groupId}) async {
    final params = {
      'targetId': targetId,
      if (groupId != null) 'groupId': groupId,
      'limit': 1,
    };

    final result = await _request('GET', '/messages/last', data: params);
    final Map<String, dynamic>? json = result['data'];
    
    if (json != null && json.isNotEmpty) {
      return model.Message.fromJson(json);
    }
    return null;
  }

  @override
  Future<model.Message?> getMessageById(int messageId) async {
    final result = await _request('GET', '/messages/$messageId');
    final Map<String, dynamic>? json = result['data'];
    
    if (json != null && json.isNotEmpty) {
      return model.Message.fromJson(json);
    }
    return null;
  }

  @override
  Future<void> updateMessageStatus(int messageId, model.MessageStatus status) async {
    await _request('PUT', '/messages/$messageId/status', data: {
      'status': status.value,
    });
  }

  @override
  Future<void> updateMessageContent(int messageId, String content, model.MessageStatus status) async {
    await _request('PUT', '/messages/$messageId', data: {
      'content': content,
      'status': status.value,
    });
  }

  @override
  Future<int> getUnreadCount(int userId) async {
    final result = await _request('GET', '/users/$userId/unread-count');
    return result['data']?['count'] ?? result['count'] ?? 0;
  }

  @override
  Future<void> markAsRead(int userId, {int? targetId, int? groupId}) async {
    final data = {'userId': userId};
    if (targetId != null) data['targetId'] = targetId;
    if (groupId != null) data['groupId'] = groupId!;
    
    await _request('POST', '/messages/mark-read', data: data);
  }

  @override
  Future<int> insertConversation(model_conv.Conversation conversation) async {
    // 会话由客户端本地维护，不再同步到服务端
    return conversation.id ?? 0;
  }

  @override
  Future<List<model_conv.Conversation>> getConversations(int userId) async {
    // 会话由客户端本地维护，不再从服务端获取
    return [];
  }

  @override
  Future<void> updateConversation(model_conv.Conversation conversation) async {
    // 会话由客户端本地维护，不再同步到服务端
  }

  @override
  Future<void> updateUnreadCount(int conversationId, int count) async {
    // 未读数由客户端本地维护，不再同步到服务端
  }

  @override
  Future<void> deleteConversation(int conversationId) async {
    // 会话删除仅在客户端本地执行，不再通知服务端
  }

  @override
  Future<void> close() async {
    _dio.close(force: true);
    print('[ApiStorage] ✓ 连接已关闭');
  }
}
