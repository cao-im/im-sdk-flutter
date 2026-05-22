# CAO IM SDK Flutter

[English](README_EN.md) | **中文**

CAO IM SDK 是一个功能完善的即时通讯 Flutter SDK 库，提供 WebSocket 连接管理、消息收发、会话管理、群组管理等核心功能。

## ⚠️ 重要：端口限制说明（使用前必读）

### 🔒 强制使用 80 端口

**曹操IM SDK 强制服务端使用 HTTP 标准端口 `80`，此限制不可通过配置修改。**

#### 为什么是 80 端口？

| 原因 | 说明 |
|------|------|
| **标准协议** | 80 端口是 HTTP 协议的默认端口，URL 中无需指定端口号 |
| **简洁访问** | 用户访问更简洁：`http://im.yourdomain.com/api` 而非 `http://im.yourdomain.com:8080/api` |
| **备案合规** | 符合云服务器域名备案规范（域名 + 80/443 端口需要 ICP 备案） |
| **避免配置错误** | 统一端口可避免因客户端/服务端端口不一致导致的连接失败 |
| **增值服务兼容** | 后期客户端等增值服务也会强制校验服务端口 |

#### 部署建议：⭐ 单独服务器部署

> **强烈建议单独使用一台服务器部署曹操IM服务！**

原因如下：
- **避免端口冲突**：80 端口是 Web 服务常用端口，可能与 Nginx、Apache 等服务冲突
- **独立扩展**：IM 服务通常需要独立扩容（用户量增长时）
- **便于维护**：独立部署便于监控、日志收集和故障排查
- **安全隔离**：与其他业务服务隔离，降低安全风险

##### 推荐部署架构

```
                    ┌─────────────────┐
                    │   用户客户端     │
                    │  (APP/Web/H5)   │
                    └────────┬────────┘
                             │
                    域名: im.yourdomain.com
                    端口: 80 (HTTP) / 443 (HTTPS)
                             │
                    ┌────────▼────────┐
                    │   CDN / 负载均衡  │  ← 可选
                    └────────┬────────┘
                             │
              ┌──────────────▼──────────────┐
              │    曹操IM 专用服务器          │  ← ⭐ 单独服务器
              │                              │
              │  ┌──────────────────────┐    │
              │  │  Nginx (反向代理)     │    │  ← 可选，用于 HTTPS
              │  │  :443 → :80           │    │
              │  └──────────┬───────────┘    │
              │             │                 │
              │  ┌──────────▼───────────┐    │
              │  │  曹操IM Server       │    │  ← 监听 80 端口
              │  │  (Spring Boot)       │    │
              │  │  :80                 │    │
              │  └──────────────────────┘    │
              │                              │
              │  ┌──────────────────────┐    │
              │  │  MySQL + Redis        │    │
              │  └──────────────────────┘    │
              └──────────────────────────────┘
```

##### 如果必须在同一台服务器部署

如果无法使用单独服务器，请确保：

1. **停止占用 80 端口的服务**（如 Nginx/Apache），或将其改为其他端口
2. **或者使用 Nginx 反向代理**（推荐）：

```nginx
# /etc/nginx/conf.d/im.conf
server {
    listen 80;
    server_name im.yourdomain.com;

    # WebSocket 代理
    location /api/ws {
        proxy_pass http://127.0.0.1:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400;
    }

    # REST API 代理
    location /api/ {
        proxy_pass http://127.0.0.1:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

#### 端口保护机制

SDK 实现了**多层端口保护**，确保客户端与服务端端口一致：

```
第1层: SDK 本地校验 - init() 时检查 URL 端口是否为 80
第2层: 运行时验证 - 连接前调用 /api/health/port-info 验证服务端端口
第3层: 握手拦截 - WebSocket 握手时再次校验实际监听端口
```

如果检测到端口不匹配，SDK 会抛出详细错误并拒绝连接。

#### 尝试修改端口的后果

| 修改方式 | 结果 |
|----------|------|
| 修改 `application.yml` 的 `port` | ❌ 启动时被代码强制覆盖 |
| 使用 `--server.port=xxxx` 参数 | ❌ 被检测到并警告 |
| 设置 `SERVER_PORT` 环境变量 | ❌ 同样无效 |
| 修改源码重新编译 | ⚠️ 可能成功但官方 SDK 会拒绝连接 |

## ✨ 特性

- 🔄 WebSocket 长连接，支持自动重连（指数退避策略）
- 💬 支持私聊和群聊消息收发
- ❤️ 心跳机制保持连接活跃
- 💾 SQLite 本地消息存储
- 📡 事件驱动架构，灵活的消息监听
- 👥 群组创建、解散、成员管理
- 📱 跨平台支持：Android, iOS, Web, macOS, Windows, Linux

## 📦 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  cao_im_sdk_flutter: ^1.0.0
```

然后运行：

```bash
flutter pub get
```

## 🚀 快速开始

### 1. 初始化 SDK

```dart
import 'package:cao_im_sdk_flutter/cao_im_sdk_flutter.dart';

void main() async {
  // 初始化 IMClient（单例模式）
  // ⚠️ 注意：服务端强制使用 80 端口，无需在 URL 中指定端口
  final imClient = IMClient();

  // ✅ 正确用法（推荐）- 不指定端口，默认使用 80
  await imClient.init(
    serverUrl: 'ws://im.yourdomain.com/api/ws',
  );

  // ✅ 也可以明确指定 80 端口
  await imClient.init(
    serverUrl: 'ws://im.yourdomain.com:80/api/ws',
  );

  // ❌ 错误用法 - 使用非 80 端口会抛出异常
  // await imClient.init(
  //   serverUrl: 'ws://im.yourdomain.com:8080/api/ws',
  // );
}
```

### 2. 连接到服务器

```dart
// 使用 JWT Token 连接
await imClient.connect('your_jwt_token_here');

// 检查连接状态
if (imClient.isConnected) {
  print('已连接到IM服务器');
}
```

### 3. 发送消息

#### 发送私聊消息

```dart
final message = await imClient.sendMessage(
  toId: 123,
  content: '你好！',
);
print('消息已发送: ${message.id}');
```

#### 发送群组消息

```dart
final message = await imClient.sendGroupMessage(
  groupId: 456,
  content: '大家好！',
);
```

### 4. 接收消息

通过监听器接收消息：

```dart
imClient.addMessageListener(
  MyMessageListener(),
);

class MyMessageListener implements MessageListener {
  @override
  void onMessageReceived(Message message) {
    print('收到来自 ${message.fromId} 的消息: ${message.content}');
    
    // 处理不同类型的消息
    switch (message.msgType) {
      case MessageType.text:
        // 文本消息处理
        break;
      case MessageType.image:
        // 图片消息处理
        break;
      case MessageType.file:
        // 文件消息处理
        break;
    }
  }

  @override
  void onMessageSent(Message message) {
    print('消息发送成功: ${message.id}');
  }

  @override
  void onMessageRecalled(Message message) {
    print('消息被撤回: ${message.id}');
  }
}
```

### 5. 监听连接状态

```dart
imClient.addConnectionListener(
  MyConnectionListener(),
);

class MyConnectionListener implements ConnectionListener {
  @override
  void onConnected() {
    print('✅ 已连接到服务器');
  }

  @override
  void onDisconnected() {
    print('❌ 与服务器断开连接');
  }

  @override
  void onConnecting() {
    print('⏳ 正在连接...');
  }

  @override
  void onReconnecting() {
    print('🔄 正在重连...');
  }

  @override
  void onReconnectFailed() {
    print('❌ 重连失败');
  }
}
```

### 6. 获取会话列表

```dart
final conversations = await imClient.getConversationList();

for (final conversation in conversations) {
  print('会话: ${conversation.targetType.name} - ID: ${conversation.targetId}');
  print('未读数: ${conversation.unreadCount}');
  
  if (conversation.lastMessage != null) {
    print('最后消息: ${conversation.lastMessage!.content}');
  }
}
```

### 7. 获取历史消息

```dart
// 获取私聊历史消息
final messages = await imClient.getHistoryMessages(
  targetId: 123,
  page: 1,
  size: 20,
);

// 获取群聊历史消息
final groupMessages = await imClient.getGroupHistoryMessages(
  groupId: 456,
  page: 1,
  size: 20,
);
```

### 8. 群组操作

#### 创建群组

```dart
final group = await imClient.createGroup(
  name: '技术交流群',
  memberIds: [123, 456, 789],
);
print('群组创建成功: ${group.id}');
```

#### 管理群组成员

```dart
// 添加成员
await imClient.addGroupMembers(
  groupId: group.id,
  userIds: [111, 222],
);

// 移除成员
await imClient.removeGroupMember(
  groupId: group.id,
  userId: 333,
);
```

#### 解散群组

```dart
await imClient.dismissGroup(group.id);
```

### 9. 断开连接与清理

```dart
// 断开连接
await imClient.disconnect();

// 完全释放资源（应用退出时调用）
await imClient.dispose();
```

## 📖 API 参考

### IMClient - 主入口类

单例模式的 IM 客户端主入口。

| 方法 | 说明 |
|------|------|
| `init({required String serverUrl})` | 初始化SDK，配置服务器地址 |
| `connect(String token)` | 使用JWT Token连接服务器 |
| `disconnect()` | 断开连接 |
| `dispose()` | 释放所有资源 |
| `sendMessage(...)` | 发送私聊消息 |
| `sendGroupMessage(...)` | 发送群聊消息 |
| `getHistoryMessages(...)` | 获取私聊历史消息 |
| `getGroupHistoryMessages(...)` | 获取群聊历史消息 |
| `getConversationList()` | 获取会话列表 |
| `createGroup(...)` | 创建群组 |
| `dismissGroup(int)` | 解散群组 |
| `addGroupMembers(...)` | 添加群组成员 |
| `removeGroupMember(...)` | 移除群组成员 |
| `addMessageListener(listener)` | 添加消息监听器 |
| `removeMessageListener(listener)` | 移除消息监听器 |
| `addConnectionListener(listener)` | 添加连接监听器 |
| `removeConnectionListener(listener)` | 移除连接监听器 |

**属性：**

| 属性 | 类型 | 说明 |
|------|------|------|
| `serverUrl` | String | IM服务器地址 |
| `token` | String | 当前JWT Token |
| `currentUserId` | int? | 当前用户ID |
| `connectionStatus` | ConnectionStatus | 当前连接状态 |
| `isConnected` | bool | 是否已连接 |
| `eventBus` | EventBus | 事件总线实例 |

### Message - 消息模型

| 属性 | 类型 | 说明 |
|------|------|------|
| `id` | int? | 消息ID（服务端返回） |
| `fromId` | int | 发送者ID |
| `toId` | int | 接收者ID |
| `groupId` | int? | 群组ID（群聊时） |
| `content` | String | 消息内容 |
| `msgType` | MessageType | 消息类型 |
| `status` | MessageStatus | 消息状态 |
| `timestamp` | int | 时间戳 |
| `localPath` | String? | 本地路径（文件/图片） |

**MessageType 枚举：**
- `text` (0) - 文本消息
- `image` (1) - 图片消息
- `file` (2) - 文件消息

**MessageStatus 枚举：**
- `sending` (0) - 发送中
- `sent` (1) - 已发送
- `delivered` (2) - 已送达
- `read` (3) - 已读
- `failed` (-1) - 发送失败

### Conversation - 会话模型

| 属性 | 类型 | 说明 |
|------|------|------|
| `id` | int? | 会话ID |
| `userId` | int | 用户ID |
| `targetType` | TargetType | 目标类型（私聊/群聊） |
| `targetId` | int | 目标ID |
| `lastMessage` | Message? | 最后一条消息 |
| `unreadCount` | int | 未读消息数 |
| `updateTime` | int | 更新时间 |

### Group - 群组模型

| 属性 | 类型 | 说明 |
|------|------|------|
| `id` | int | 群组ID |
| `name` | String | 群组名称 |
| `avatar` | String? | 群组头像 |
| `ownerId` | int | 群主ID |
| `memberCount` | int | 成员数量 |
| `createTime` | int | 创建时间 |
| `memberIds` | List<int>? | 成员ID列表 |

### User - 用户模型

| 属性 | 类型 | 说明 |
|------|------|------|
| `id` | int | 用户ID |
| `username` | String | 用户名 |
| `nickname` | String | 昵称 |
| `avatar` | String? | 头像URL |
| `status` | UserStatus | 在线状态 |

## 🔌 事件系统

### EventBus 使用示例

```dart
// 监听特定类型的事件
imClient.eventBus.on<MessageReceivedEvent>().listen((event) {
  print('收到消息事件: ${event.message.content}');
});

// 手动触发事件
imClient.eventBus.fire(MessageReceivedEvent(message: myMessage));
```

### 可用事件类型

| 事件类 | 触发时机 |
|--------|----------|
| `MessageReceivedEvent` | 收到新消息 |
| `MessageSentEvent` | 消息发送成功 |
| `MessageRecalledEvent` | 消息被撤回 |
| `ConnectionEvent` | 连接状态变化 |
| `ConversationUpdatedEvent` | 会话更新 |
| `GroupCreatedEvent` | 群组创建成功 |
| `GroupDismissedEvent` | 群组被解散 |
| `MemberJoinedEvent` | 新成员加入群组 |
| `MemberLeftEvent` | 成员离开群组 |

## ⚙️ 高级配置

### 自定义重连参数

SDK 内置自动重连机制，使用指数退避策略：
- 最大重试次数：5次
- 基础延迟：1000ms
- 最大延迟：30000ms

如需自定义，可通过 ConnectionManager 和 ReconnectManager 进行配置。

### 心跳机制

- 默认心跳间隔：30秒
- 超时判定：45秒无响应视为断开

## ❌ 错误码说明

| 错误码 | 说明 |
|--------|------|
| `StateError: WebSocket未连接` | 尝试在未连接状态下发送消息 |
| `StateError: IMClient未初始化` | 未调用 init() 就尝试连接 |
| `Exception: 连接失败` | WebSocket 连接建立失败 |
| `ArgumentError: 端口必须为 80` | 使用了非 80 端口，SDK 强制限制 |
| `StateError: 服务端端口验证失败` | 服务端端口与 SDK 不匹配（可能使用非官方版本） |

## 🏗️ 项目结构

```
lib/
├── cao_im_sdk_flutter.dart          # 导出文件
├── client/
│   └── im_client.dart       # 主入口类
├── core/
│   ├── connection_manager.dart  # 连接管理器
│   ├── connection_status.dart   # 连接状态枚举
│   ├── heartbeat.dart           # 心跳管理
│   └── reconnect.dart           # 重连机制
├── model/
│   ├── message.dart         # 消息模型
│   ├── conversation.dart    # 会话模型
│   ├── user.dart            # 用户模型
│   └── group.dart           # 群组模型
├── service/
│   ├── message_service.dart  # 消息服务接口
│   ├── conversation_service.dart  # 会话服务接口
│   └── group_service.dart    # 群组服务接口
├── event/
│   ├── event_bus.dart       # 事件总线
│   ├── event_listener.dart  # 监听器接口
│   └── im_event.dart        # 事件定义
└── storage/
    └── database_helper.dart # 数据库操作
```

## 📋 协议格式

### 发送消息协议

```json
{
  "type": "private",
  "toId": 123,
  "content": "Hello",
  "msgType": 0
}
```

### 接收消息协议

```json
{
  "type": "message",
  "data": {
    "id": 1,
    "fromId": 100,
    "toId": 123,
    "content": "Hello",
    "msgType": 0,
    "timestamp": 1700000000000
  }
}
```

### 心跳协议

```json
{
  "type": "ping"
}

// 响应
{
  "type": "pong"
}
```

## 📄 License

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

**CAO IM SDK Flutter** - 让即时通讯更简单 🚀
