import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'logger.dart';

class NetworkLogInterceptor extends Interceptor {
  final Logger _log = AppLogger.instance;
  
  final bool _isEnabled;
  final bool _requestHeader;
  final bool _requestBody;
  final bool _responseHeader;
  final bool _responseBody;
  final bool _error;

  NetworkLogInterceptor({
    bool isEnabled = true,
    bool requestHeader = true,
    bool requestBody = true,
    bool responseHeader = true,
    bool responseBody = true,
    bool error = true,
  })  : _isEnabled = isEnabled && kDebugMode,
        _requestHeader = requestHeader,
        _requestBody = requestBody,
        _responseHeader = responseHeader,
        _responseBody = responseBody,
        _error = error;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_isEnabled) {
      return handler.next(options);
    }

    final StringBuffer sb = StringBuffer();
    sb.writeln('════════════════════════════════════════════════════');
    sb.writeln('🌐 🔵 [网络请求] ${options.method.toUpperCase()} ${options.uri.toString()}');
    
    if (_requestHeader) {
      sb.writeln('┌─────────────── 请求头 (Request Headers) ───────────────');
      options.headers.forEach((key, value) {
        if (key.toLowerCase() != 'authorization' || value.toString().length <= 50) {
          sb.writeln('│ $key: $value');
        } else {
          final maskedValue = '${value.toString().substring(0, 20)}...***';
          sb.writeln('│ $key: $maskedValue (已脱敏)');
        }
      });
      sb.writeln('└────────────────────────────────────────────────────');
    }

    if (_requestBody && options.data != null) {
      sb.writeln('┌─────────────── 请求参数 (Request Body) ──────────────');
      try {
        const encoder = JsonEncoder.withIndent('  ');
        final prettyData = encoder.convert(options.data);
        sb.writeln(prettyData);
      } catch (_) {
        sb.writeln(options.data.toString());
      }
      sb.writeln('└────────────────────────────────────────────────────');
    }

    if (options.queryParameters.isNotEmpty) {
      sb.writeln('┌─────────────── 查询参数 (Query Parameters) ──────────');
      options.queryParameters.forEach((key, value) {
        sb.writeln('│ $key: $value');
      });
      sb.writeln('└────────────────────────────────────────────────────');
    }

    sb.writeln('⏱️ 请求时间: ${DateTime.now().toString().split('.').first}');
    sb.writeln('════════════════════════════════════════════════════');

    _log.d(sb.toString());

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!_isEnabled) {
      return handler.next(response);
    }

    final StringBuffer sb = StringBuffer();
    
    sb.writeln('════════════════════════════════════════════════════');
    sb.writeln('🟢 [响应成功] ${response.statusCode} ${response.requestOptions.method.toUpperCase()} ${response.requestOptions.uri.toString()}');
    
    if (_responseHeader) {
      sb.writeln('┌─────────────── 响应头 (Response Headers) ─────────────');
      response.headers.forEach((key, values) {
        sb.writeln('│ $key: ${values.join(", ")}');
      });
      sb.writeln('└────────────────────────────────────────────────────');
    }

    sb.writeln('📊 状态码: ${response.statusCode} (${_getStatusText(response.statusCode)})');
    
    if (response.data != null && _responseBody) {
      sb.writeln('┌─────────────── 响应数据 (Response Body) ─────────────');
      try {
        const encoder = JsonEncoder.withIndent('  ');
        String prettyData;
        
        if (response.data is String) {
          try {
            final jsonData = jsonDecode(response.data as String);
            prettyData = encoder.convert(jsonData);
          } catch (_) {
            prettyData = response.data as String;
          }
        } else {
          prettyData = encoder.convert(response.data);
        }
        
        final dataLength = prettyData.length;
        if (dataLength > 2000) {
          sb.writeln('${prettyData.substring(0, 2000)}\n... (数据过长, 已截取前2000字符, 总长度: $dataLength)');
        } else {
          sb.writeln(prettyData);
        }
      } catch (_) {
        final dataStr = response.data.toString();
        if (dataStr.length > 1000) {
          sb.writeln('${dataStr.substring(0, 1000)}... (数据过长)');
        } else {
          sb.writeln(dataStr);
        }
      }
      sb.writeln('└────────────────────────────────────────────────────');
    }

    sb.writeln('⏱️ 响应时间: ${DateTime.now().toString().split('.').first}');
    sb.writeln('════════════════════════════════════════════════════');

    _log.i(sb.toString());

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!_isEnabled) {
      return handler.next(err);
    }

    final StringBuffer sb = StringBuffer();
    
    sb.writeln('════════════════════════════════════════════════════');
    sb.writeln('🔴 [请求失败] ${err.type.name} ${err.requestOptions.method.toUpperCase()} ${err.requestOptions.uri.toString()}');
    
    sb.writeln('❌ 错误类型: ${err.type.name}');
    sb.writeln('❌ 错误信息: ${err.message}');
    
    if (err.response != null) {
      sb.writeln('📊 状态码: ${err.response!.statusCode}');
      
      if (_error && err.response?.data != null) {
        sb.writeln('┌─────────────── 错误响应数据 ──────────────────────');
        try {
          const encoder = JsonEncoder.withIndent('  ');
          sb.writeln(encoder.convert(err.response?.data));
        } catch (_) {
          sb.writeln(err.response?.data.toString());
        }
        sb.writeln('└────────────────────────────────────────────────────');
      }
    } else if (err.type == DioExceptionType.connectionTimeout) {
      sb.writeln('⏰ 连接超时，请检查网络连接或服务器状态');
    } else if (err.type == DioExceptionType.sendTimeout) {
      sb.writeln('⏰ 发送超时，请检查网络状况');
    } else if (err.type == DioExceptionType.receiveTimeout) {
      sb.writeln('⏰ 接收超时，服务器响应过慢');
    } else if (err.type == DioExceptionType.connectionError) {
      sb.writeln('🔌 连接错误，无法连接到服务器');
    }

    if (err.stackTrace != null) {
      sb.writeln('┌─────────────── 错误堆栈 ───────────────────────────');
      sb.writeln(err.stackTrace.toString());
      sb.writeln('└────────────────────────────────────────────────────');
    }

    sb.writeln('⏱️ 错误时间: ${DateTime.now().toString().split('.').first}');
    sb.writeln('════════════════════════════════════════════════════');

    _log.e(sb.toString(), error: err);

    return handler.next(err);
  }

  String _getStatusText(int? statusCode) {
    switch (statusCode) {
      case 200:
        return 'OK - 请求成功';
      case 201:
        return 'Created - 创建成功';
      case 204:
        return 'No Content - 无内容';
      case 400:
        return 'Bad Request - 请求参数错误';
      case 401:
        return 'Unauthorized - 未授权';
      case 403:
        return 'Forbidden - 禁止访问';
      case 404:
        return 'Not Found - 资源不存在';
      case 500:
        return 'Internal Server Error - 服务器内部错误';
      default:
        return statusCode != null ? 'Unknown' : 'No Status Code';
    }
  }
}
