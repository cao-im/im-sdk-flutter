import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/logger.dart';
import 'connection_status.dart';
import 'heartbeat.dart';

class ConnectionManager {
  static const int _defaultPort = 8080;
  static const String _buildSignature = 'CAOIM-2024-OPEN-SOURCE';

  WebSocketChannel? _channel;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _serverUrl = '';
  String _token = '';
  int? _customPort;

  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  int _heartbeatInterval = 30;
  late HeartbeatManager _heartbeatManager;

  Map<String, dynamic>? _serverPortInfo;

  final Logger _log = AppLogger.instance;

  Stream<ConnectionStatus> get onStatusChanged => _statusController.stream;
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  ConnectionStatus get status => _status;
  bool get isConnected => _status == ConnectionStatus.connected;

  String _enforcePort(String serverUrl) {
    final uri = Uri.parse(serverUrl);
    final port = _customPort ?? (uri.hasPort ? uri.port : _defaultPort);

    if (uri.hasPort && _customPort == null) {
      _log.i('使用指定端口: ${uri.port}');
    } else if (!uri.hasPort && _customPort == null) {
      _log.i('未指定端口，使用默认端口: $_defaultPort');
    }

    return uri.replace(port: port).toString();
  }

  void setCustomPort(int port) {
    _customPort = port;
  }

  Future<void> _validateServerPort(String baseUrl) async {
    try {
      final uri = Uri.parse(baseUrl);
      final portInfoUrl = uri.replace(
        scheme: uri.scheme == 'wss' ? 'https' : 'http',
        path: '/api/health/port-info',
      ).toString();

      _log.d('正在验证服务端端口配置: $portInfoUrl');

      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 5);

      final request = await httpClient.getUrl(Uri.parse(portInfoUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseData =
            jsonDecode(await response.transform(utf8.decoder).join());
        final data = responseData['data'] as Map<String, dynamic>;

        _serverPortInfo = data;

        final serverPort = data['port'] as int;
        final configuredPort = data['configuredPort'] as int;
        final isMatched = data['isPortMatched'] as bool;
        final buildSignature = data['buildSignature'] as String?;
        final portConfigurable = data['portConfigurable'] as bool? ?? false;
        final note = data['note'] as String?;

        _log.i('服务端端口信息获取成功');
        _log.i('- 服务端口: $serverPort');
        _log.i('- 配置端口: $configuredPort');
        _log.i('- 端口匹配: ${isMatched ? "是" : "否"}');
        _log.i('- 端口可配置: ${portConfigurable ? "是" : "否"}');

        if (buildSignature != null && buildSignature != _buildSignature) {
          _log.w('构建签名不匹配!');
          _log.w('SDK期望: $_buildSignature');
          _log.w('服务端实际: $buildSignature');
        }

        if (note != null) {
          _log.i('服务端提示: $note');
        }

        if (!isMatched) {
          _log.w('服务端端口与请求端口不完全匹配');
          _log.w('- 请求端口可能与服务端配置端口不同');
          _log.w('- 这通常不影响连接（端口可自由配置）');
        }

        _log.i('服务端端口验证通过，可以安全连接');
      } else {
        throw Exception(
            '无法获取服务端端口信息 (HTTP ${response.statusCode})');
      }

      httpClient.close();
    } on SocketException catch (e) {
      _log.w('无法连接到服务端进行端口验证: $e');
      _log.w('将尝试直接连接（可能不安全）');
    } catch (e) {
      rethrow;
    }
  }

  static const int _connectTimeoutSeconds = 10;

  Future<void> connect(String serverUrl, String token) async {
    print('');
    print('📍[ConnMgr] ====== connect() 开始 ======');
    print('📍[ConnMgr] 当前状态: $_status');

    if (_status == ConnectionStatus.connected ||
        _status == ConnectionStatus.connecting) {
      print('⚠️[ConnMgr] 已连接或正在连接，跳过');
      return;
    }

    _serverUrl = _enforcePort(serverUrl);
    _token = token;
    print('📍[ConnMgr] 强制端口后 serverUrl: $_serverUrl');

    _updateStatus(ConnectionStatus.connecting);
    print('📍[ConnMgr] 状态已设为 connecting');

    try {
      print('📍[ConnMgr] [步骤1/4] 开始验证服务器端口...');
      await _validateServerPort(_serverUrl);
      print('✅[ConnMgr] [步骤1/4] 端口验证通过');
    } catch (e) {
      print('⚠️[ConnMgr] [步骤1/4] 端口验证失败(非致命): $e');
      _log.w('端口验证跳过，将直接尝试连接: $e');
    }

    try {
      final uri = Uri.parse('$_serverUrl?token=$token');
      print('📍[ConnMgr] [步骤2/4] 构建WebSocket URI: $uri');
      print('📍[ConnMgr] [步骤3/4] 调用 WebSocketChannel.connect()...');

      final startTime = DateTime.now();
      _channel = WebSocketChannel.connect(uri);

      print('📍[ConnMgr] WebSocketChannel 已创建, 等待 ready (超时: ${_connectTimeoutSeconds}秒)...');

      await _channel!.ready.timeout(
        Duration(seconds: _connectTimeoutSeconds),
        onTimeout: () {
          final elapsed = DateTime.now().difference(startTime).inMilliseconds;
          print('❌[ConnMgr] [步骤3/4] 连接超时! 耗时: ${elapsed}ms (限制: ${_connectTimeoutSeconds * 1000}ms)');
          throw TimeoutException(
            'WebSocket 连接超时 (${_connectTimeoutSeconds}秒)，请检查 IM Server 是否启动',
          );
        },
      );

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      print('✅[ConnMgr] [步骤3/4] WebSocket ready 成功! 耗时: ${elapsed}ms');

      print('📍[ConnMgr] [步骤4/4] 设置连接状态为 connected...');

      final connectedTime = DateTime.now();
      _log.i('📊 连接建立时间: ${connectedTime.millisecondsSinceEpoch}');

      _listenMessages();
      _heartbeatManager = HeartbeatManager(
        intervalSeconds: _heartbeatInterval,
        onPing: _sendPing,
        onTimeout: () {
          final duration = DateTime.now().difference(connectedTime).inMilliseconds;
          _log.w('心跳超时，连接可能已断开 (连接持续: ${duration}ms)');
          _handleDisconnection();
        },
      );
      _heartbeatManager.start();

      _updateStatus(ConnectionStatus.connected);
      _log.i('WebSocket 连接成功');
      print('✅[ConnMgr] ====== connect() 完全成功 ======');
    } on TimeoutException catch (e) {
      print('❌[ConnMgr] 捕获到 TimeoutException: $e');
      _log.e('连接超时: $e');
      _cleanupChannel();
      _updateStatus(ConnectionStatus.disconnected);
      rethrow;
    } catch (e, stack) {
      print('❌[ConnMgr] 捕获到异常: $e');
      print('❌[ConnMgr] stackTrace: $stack');
      _log.e('WebSocket 连接失败: $e');
      _cleanupChannel();
      _updateStatus(ConnectionStatus.disconnected);
      rethrow;
    }
  }

  void _cleanupChannel() {
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    print('🧹[ConnMgr] Channel 已清理');
  }

  void disconnect() {
    _heartbeatManager.stop();
    _channel?.sink.close();
    _channel = null;
    _updateStatus(ConnectionStatus.disconnected);
  }

  void sendMessage(Map<String, dynamic> data) {
    if (!isConnected || _channel == null) {
      throw StateError('WebSocket未连接');
    }
    _channel!.sink.add(jsonEncode(data));
  }

  DateTime? _connectedTime;

  void _listenMessages() {
    _connectedTime = DateTime.now();
    _channel?.stream.listen(
      (message) {
        if (message is String) {
          try {
            final data = jsonDecode(message) as Map<String, dynamic>;

            if (data['type'] == 'port_handshake_result') {
              _handlePortHandshake(data);
              return;
            }

            if (data['type'] == 'pong') {
              _heartbeatManager.onResponseReceived();
              return;
            }

            _messageController.add(data);
          } catch (e) {
            _log.e('消息解析错误', error: e);
          }
        }
      },
      onDone: () {
        final duration = _connectedTime != null
            ? DateTime.now().difference(_connectedTime!).inMilliseconds
            : 0;
        _log.w('🔌 WebSocket 连接已关闭 (onDone 触发)');
        _log.w('⏱️ 连接持续时间: ${duration}ms');
        _log.w('🔍 可能原因:');
        _log.w('   1. 服务端主动关闭连接');
        _log.w('   2. Token 认证失败或过期');
        _log.w('   3. 服务端配置问题（最大连接数、IP白名单等）');
        _log.w('   4. 网络中断');
        _log.w('📎 建议: 检查服务端日志获取详细关闭原因');
        _handleDisconnection();
      },
      onError: (error) {
        final duration = _connectedTime != null
            ? DateTime.now().difference(_connectedTime!).inMilliseconds
            : 0;
        _log.e('❌ WebSocket 连接错误 (onError 触发)', error: error);
        _log.e('⏱️ 连接持续时间: ${duration}ms');
        _log.e('❌ 错误详情: ${error.toString()}');
        _log.e('🔍 错误类型: ${error.runtimeType}');
        _handleDisconnection();
      },
    );
  }

  void _handlePortHandshake(Map<String, dynamic> data) {
    final success = data['success'] as bool? ?? false;
    final message = data['message'] as String? ?? '';

    if (!success) {
      _log.e('服务端端口握手失败: $message');
      disconnect();
      throw StateError('端口握手失败: $message');
    }

    _log.i('服务端端口握手成功');
  }

  void _sendPing() {
    if (isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode({'type': 'ping'}));
      } catch (e) {
        _log.e('心跳发送失败', error: e);
      }
    }
  }

  void _handleDisconnection() {
    if (_status == ConnectionStatus.connected) {
      _heartbeatManager.stop();
      _updateStatus(ConnectionStatus.disconnected);
    }
  }

  void _updateStatus(ConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(_status);
    }
  }

  Map<String, dynamic>? get serverPortInfo => _serverPortInfo;

  void dispose() {
    disconnect();
    _heartbeatManager.dispose();
    _statusController.close();
    _messageController.close();
  }
}
