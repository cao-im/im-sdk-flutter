# Web 端 API 存储方案 - 架构说明

## 📋 方案概述

**核心思想**: 其他平台（Windows、iOS、Android）保持 Drift + SQLite 本地存储不变，
**仅 Web 端** 使用 HTTP API + WebSocket 实现会话和聊天记录的持久化。

## 🏗️ 架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                      IMClient (统一入口)                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │ ConnectionManager│    │       StorageFactory            │ │
│  │ (WebSocket 实时)  │    │  ┌──────────┐ ┌────────────┐  │ │
│  │                  │    │  │ kIsWeb?  │ │   else     │  │ │
│  │ • 发送/接收消息   │───▶│  │ ApiStorage│ │DriftStorage│  │ │
│  │ • 心跳检测        │    │  │(HTTP API) │ │(SQLite)    │  │ │
│  │ • 断线重连        │    │  └──────────┘ └────────────┘  │ │
│  └─────────────────┘    └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │         服务端 (Server)        │
              ├───────────────────────────────┤
              │  WebSocket Server (实时通信)    │
              │  RESTful API Server (持久化)   │
              │  Database (MySQL/PostgreSQL)   │
              └───────────────────────────────┘
```

## 🔄 数据流说明

### 1. **发送消息流程** (Web 端)
```dart
// 用户发送消息
IMClient.instance.sendMessage(toId: 123, content: "你好")
  ↓
// ① 通过 WebSocket 实时发送给对方
_connectionManager.send(message)
  ↓
// ② 同时通过 HTTP API 持久化到服务端
_storage.insertMessage(message)  // → POST /api/v1/messages
```

### 2. **接收消息流程** (Web 端)
```dart
// ① 通过 WebSocket 实时接收消息
_connectionManager.onMessage.listen((data) {
  final message = Message.fromJson(data);
  
  // ② 通过 HTTP API 保存到服务端（冗余备份）
  _storage.insertMessage(message);  // → POST /api/v1/messages
  
  // ③ 通知 UI 层更新
  listener.onMessageReceived(message);
})
```

### 3. **获取历史记录** (Web 端)
```dart
// 直接从服务端 HTTP API 获取
final messages = await _storage.getMessages(
  targetId: 123,
  page: 1,
  size: 20,
);
// → GET /api/v1/messages?targetId=123&page=1&size=20
```

## 📡 双通道优势

| 特性 | WebSocket | HTTP API |
|------|-----------|----------|
| **用途** | 实时通信 | 数据持久化 |
| **延迟** | 毫秒级 | 10-100ms |
| **可靠性** | 需要重连机制 | 天然可靠（HTTP） |
| **离线支持** | ❌ 不支持 | ✅ 支持缓存 |
| **历史记录** | ❌ 仅实时流 | ✅ 分页查询 |

## 🎯 核心代码文件

### 1. [storage_factory.dart](../lib/storage/storage_factory.dart)
**平台自动选择逻辑**:
```dart
if (kIsWeb) {
  _instance = ApiStorage();      // Web → HTTP API
} else {
  _instance = DriftStorage();    // 原生平台 → SQLite
}
```

### 2. [api_storage.dart](../lib/storage/api_storage.dart)
**HTTP API 存储实现**:
- 使用 Dio 进行网络请求
- 所有 CRUD 操作映射为 RESTful API
- 自动从 IMClient 获取 serverUrl 和 token

### 3. [im_client.dart](../lib/client/im_client.dart)
**Token 自动传递**:
```dart
if (_storage is ApiStorage) {
  (_storage as ApiStorage).updateToken(token);  // Web端自动传递
}
```

## 🔌 需要实现的服务端 API

### Messages API (消息相关)

#### `POST /api/v1/messages`
**创建消息**
```json
// Request Body
{
  "fromId": 1001,
  "toId": 1002,
  "content": "你好",
  "msgType": 0,
  "status": 0,
  "timestamp": 1700000000000
}

// Response
{
  "code": 200,
  "data": {
    "id": 12345,
    ...messageFields
  }
}
```

#### `GET /api/v1/messages`
**分页获取消息**
```
Query Parameters:
- targetId: int (必填)
- groupId: int (可选, 群组消息)
- currentUserId: int (可选)
- page: int (默认 1)
- size: int (默认 20)

Response:
{
  "code": 200,
  "data": [
    { "id": 12345, "fromId": 1001, ... },
    { "id": 12346, "fromId": 1002, ... }
  ]
}
```

#### `GET /api/v1/messages/{messageId}`
**获取单条消息**

#### `GET /api/v1/messages/last`
**获取最新消息**
```
Query Parameters:
- targetId: int (必填)
- groupId: int (可选)
- limit: int (默认 1)
```

#### `PUT /api/v1/messages/{messageId}/status`
**更新消息状态**
```json
{ "status": 1 }  // 0=sending, 1=sent, 2=read, 3=recalled
```

#### `PUT /api/v1/messages/{messageId}`
**更新消息内容**
```json
{
  "content": "[消息已撤回]",
  "status": 3
}
```

### Conversations API (会话相关)

#### `POST /api/v1/conversations`
**创建会话**

#### `GET /api/v1/users/{userId}/conversations`
**获取用户会话列表**

#### `PUT /api/v1/conversations/{conversationId}`
**更新会话信息**

#### `PUT /api/v1/conversations/{conversationId}/unread-count`
**更新未读数**
```json
{ "unreadCount": 5 }
```

#### `DELETE /api/v1/conversations/{conversationId}`
**删除会话**

### Users API (用户相关)

#### `GET /api/v1/users/{userId}/unread-count`
**获取总未读数**

#### `POST /api/v1/messages/mark-read`
**标记已读**
```json
{
  "userId": 1001,
  "groupId": null  // 可选
}
```

## 🔐 认证方式

所有 API 请求都需要在 Header 中携带 Token:

```
Authorization: Bearer {userToken}
```

Token 在用户调用 `IMClient.connect(token)` 时自动设置。

## 🚀 快速开始

### Web 端使用示例
```dart
void main() async {
  // 1. 初始化 SDK（自动检测平台并选择存储方案）
  await IMClient.instance.init(
    serverUrl: 'ws://your-server.com/api/ws',
  );

  // 2. 连接服务器（Web端自动传递token给ApiStorage）
  await IMClient.instance.connect('your-user-token', userId: 1001);

  // 3. 发送消息（同时走 WebSocket + HTTP API）
  await IMClient.instance.sendMessage(
    toId: 1002,
    content: 'Hello from Web!',
  );

  // 4. 获取历史记录（从服务端API获取）
  final messages = await IMClient.instance.getHistoryMessages(
    targetId: 1002,
    page: 1,
    size: 20,
  );
}
```

## ⚠️ 注意事项

1. **网络依赖**: Web 端完全依赖网络，无离线模式
2. **延迟较高**: 相比本地 SQLite，HTTP API 有 10-50ms 额外延迟
3. **并发控制**: 建议服务端实现乐观锁或版本号机制
4. **数据一致性**: WebSocket 和 HTTP 可能存在短暂不一致（毫秒级）
5. **错误处理**: 需要完善的网络错误重试机制

## 📊 性能对比

| 操作 | SQLite (原生) | HTTP API (Web) |
|------|---------------|----------------|
| 插入消息 | < 1ms | 20-50ms |
| 查询 20 条 | < 5ms | 30-80ms |
| 更新状态 | < 1ms | 20-40ms |
| 会话列表 | < 10ms | 50-100ms |

## 🎉 总结

✅ **完全可行！** 这是生产级推荐方案
✅ **零 FFI 问题** - 彻底避免 Web 端兼容性问题
✅ **自动切换** - StorageFactory 根据 kIsWeb 自动选择
✅ **代码复用** - 所有业务层代码无需修改（统一使用 StorageInterface）
✅ **双保险** - WebSocket 实时性 + HTTP API 可靠性

---

**适用场景**: 
- Web 端需要完整聊天功能
- 服务端已有或可开发 RESTful API
- 可以接受轻微的网络延迟
- 需要多端数据同步
