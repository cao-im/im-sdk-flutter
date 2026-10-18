# im-sdk-flutter

CaoIM 的 Flutter SDK。封装 WebSocket、心跳、断线重连、本地 SQLite、消息和群操作，以及一对一通话信令。界面、摄像头和 WebRTC 媒体在 `flutter-demo`，不在本包里。

包名 `cao_im_sdk_flutter`。本仓库通过 path 依赖被客户端使用，不要求发布到 pub.dev 才能运行。

## 仓库一览

| 仓库 | 作用 |
|------|------|
| im-server | 消息与长连接。好友、群、历史、已读、离线同步和一对一通话信令。端口 8080，库 `cao_im_db` |
| app-server | 客户端注册、登录、个人资料和文件上传。端口 8081，库 `cao_im_app_server` |
| im-admin | 运营后台：用户启停、群、消息检索、敏感词、系统配置、角色和审计。API 端口 8082，页面开发端口 5173，库 `cao_im_admin` |
| im-sdk-flutter | 本仓库。Flutter SDK，负责 WebSocket、本地消息库、会话、群和通话信令，不包含界面 |
| flutter-demo | 客户端。同一套代码运行在 Windows、macOS、Android、iOS 和 Web |

## 客户端界面

本 SDK 不画界面。下面是使用它的客户端在 Windows、手机和浏览器上的效果。

### Windows

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/windows/01-conversation-list.png" alt="会话列表" width="420" /><br/><b>会话列表</b></td>
    <td align="center"><img src="docs/screenshots/windows/02-private-chat.png" alt="私聊" width="420" /><br/><b>私聊</b></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/windows/03-group-info.png" alt="群资料" width="420" /><br/><b>群资料</b></td>
    <td align="center"><img src="docs/screenshots/windows/04-contacts.png" alt="通讯录" width="420" /><br/><b>通讯录</b></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/windows/05-contact-profile.png" alt="联系人资料" width="420" /><br/><b>联系人资料</b></td>
    <td align="center"><img src="docs/screenshots/windows/06-voice-call.png" alt="语音呼叫" width="420" /><br/><b>语音呼叫</b></td>
  </tr>
  <tr>
    <td align="center" colspan="2"><img src="docs/screenshots/windows/07-video-call.jpg" alt="视频通话" width="420" /><br/><b>视频通话</b></td>
  </tr>
</table>

### App

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/app/01-messages.png" alt="消息" width="180" /><br/><b>消息</b></td>
    <td align="center"><img src="docs/screenshots/app/02-chat.png" alt="私聊" width="180" /><br/><b>私聊</b></td>
    <td align="center"><img src="docs/screenshots/app/08-contacts.png" alt="通讯录" width="180" /><br/><b>通讯录</b></td>
    <td align="center"><img src="docs/screenshots/app/03-profile.png" alt="个人资料" width="180" /><br/><b>个人资料</b></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/app/06-emoji.png" alt="表情" width="180" /><br/><b>表情</b></td>
    <td align="center"><img src="docs/screenshots/app/07-attach.png" alt="图片视频文件" width="180" /><br/><b>图片、视频、文件</b></td>
    <td align="center"><img src="docs/screenshots/app/04-voice-call.png" alt="语音呼叫" width="180" /><br/><b>语音呼叫</b></td>
    <td align="center"><img src="docs/screenshots/app/05-video-call.jpg" alt="视频通话" width="180" /><br/><b>视频通话</b></td>
  </tr>
</table>

### Web

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/web/01-group-chat.png" alt="群聊" width="420" /><br/><b>群聊</b></td>
    <td align="center"><img src="docs/screenshots/web/02-group-info.png" alt="群资料" width="420" /><br/><b>群资料</b></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/web/03-contacts.png" alt="通讯录" width="420" /><br/><b>通讯录</b></td>
    <td align="center"><img src="docs/screenshots/web/04-voice-call.png" alt="语音呼叫" width="420" /><br/><b>语音呼叫</b></td>
  </tr>
  <tr>
    <td align="center" colspan="2"><img src="docs/screenshots/web/05-video-incoming.png" alt="视频来电" width="420" /><br/><b>视频来电</b></td>
  </tr>
</table>

## 能力

- 连接 `ws://{host}:8080/api/ws?token={imToken}`，断线后指数退避重连
- 心跳默认 30 秒，长时间无响应视为断开
- 私聊、群聊的发送、历史、撤回、已读和送达回执
- 离线消息同步，Drift / SQLite 本地库
- 本地和服务端消息搜索
- 会话列表、置顶、免打扰、未读数
- 建群、改资料、解散、拉人、踢人、转让群主
- 好友申请事件
- 一对一通话信令：`inviteCall` 的 `video: true` 表示视频。SDK 只收发信令，不采集麦克风和摄像头
- 事件总线：消息、连接、会话、群、好友、离线同步、`CallSignalEvent`

支持 Android、iOS、macOS、Windows、Web、Linux。Web 与移动端的本地存储实现不同，详见 `docs/`。

消息类型与服务端一致：文本、图片、文件、语音、视频、系统提示。

## 接入

在客户端 `pubspec.yaml`：

```yaml
dependencies:
  cao_im_sdk_flutter:
    path: ../im-sdk-flutter
```

```dart
import 'package:cao_im_sdk_flutter/cao_im_sdk_flutter.dart';

final client = IMClient();

await client.init(serverUrl: 'ws://192.168.0.10:8080/api/ws');
await client.connect(imToken, userId: userId, refreshToken: imRefreshToken);

await client.sendMessage(toId: 123, content: '你好');
await client.sendGroupMessage(groupId: 456, content: '大家好');

client.inviteCall(peerId, callId);                 // 语音
client.inviteCall(peerId, callId, video: true);    // 视频
client.acceptCall(callId);
client.sendCallSignal(callId, sdpOrIcePayload);
client.hangupCall(callId);
```

地址里带上端口。im-server 默认是 `8080`，路径是 `/api/ws`。`connect` 使用的是 im-server 签发的 `imToken`，不是 app-server 的登录 Token。

监听新消息：

```dart
client.eventBus.on<MessageReceivedEvent>().listen((event) {
  final message = event.message;
});

client.eventBus.on<CallSignalEvent>().listen((event) {
  // event.action: ringing / incoming / accepted / rejected / hangup / signal ...
  // event.video 为 true 时表示视频通话
});
```

也可以实现 `MessageListener`、`ConnectionListener`，用 `addMessageListener` 注册。

常用方法：

| 方法 | 说明 |
|------|------|
| `init` / `connect` / `disconnect` / `dispose` | 生命周期 |
| `sendMessage` / `sendGroupMessage` / `recallMessage` | 收发与撤回 |
| `getHistoryMessages` / `getGroupHistoryMessages` | 历史 |
| `searchLocalMessages` / `searchServerMessages` | 搜索 |
| `getConversationList` / `markTargetAsRead` | 会话与已读 |
| `createGroup` / `updateGroupInfo` / `dismissGroup` | 群 |
| `addGroupMembers` / `removeGroupMember` / `transferOwner` | 成员 |
| `inviteCall` / `acceptCall` / `rejectCall` / `cancelCall` / `hangupCall` / `sendCallSignal` | 通话信令 |
| `syncOfflineMessages` | 同步离线消息 |

## 本地库

移动端和桌面端用 Drift。Windows 10 及以上使用系统的 `winsqlite3`。Android 没有可直接加载的系统 `libsqlite3.so`，客户端需要把 `libsqlite3.so` 放进 `android/app/src/main/jniLibs`，并在自己的 `pubspec.yaml` 里声明：

```yaml
hooks:
  user_defines:
    sqlite3:
      source: system
      name_windows: winsqlite3
```

`source: system` 避免 native assets 再打一份同名库，否则 Android 合并 JNI 会失败。改了 so 或 hook 后需要完整重新编译，热重载不会换原生库。

## 协议

上行示例：

```json
{ "type": "private", "toId": 123, "content": "Hello", "msgType": 0 }
{ "type": "call_invite", "toId": 123, "callId": "abc", "video": true }
{ "type": "ping" }
```

下行消息包在 `type: message` 里。通话下行 `type: call`，字段有 `action`、`callId`、`peerId`、`video`、`payload`。

## 目录

```
lib/
├── cao_im_sdk_flutter.dart
├── client/im_client.dart
├── core/          # 连接、心跳、重连、Token
├── model/
├── service/
├── event/
└── storage/
docs/              # Web 与 Drift 存储说明
```

## 联系与支持

有新功能、定制开发或合作意向，欢迎扫码加微信私信。

独立开发不易。如果这个项目对你有帮助，也可以通过微信或支付宝支持一下，你的认可是我继续更新的动力。

<table>
  <tr>
    <td align="center"><img src="docs/contact/wechat.jpg" alt="微信" width="220" /><br/><b>微信</b><br/>定制与合作</td>
    <td align="center"><img src="docs/contact/wechat-pay.jpg" alt="微信支付" width="220" /><br/><b>微信支付</b></td>
    <td align="center"><img src="docs/contact/alipay.jpg" alt="支付宝" width="220" /><br/><b>支付宝</b></td>
  </tr>
</table>

## License

MIT License
