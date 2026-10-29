# im-sdk-flutter

CaoIM 的 Flutter SDK。封装 WebSocket、心跳、断线重连、本地 SQLite、消息和群操作，以及一对一通话信令。界面、摄像头和 WebRTC 媒体在 `flutter-demo`，不在本包里。

包名 `cao_im_sdk_flutter`。本仓库通过 path 依赖被客户端使用，不要求发布到 pub.dev 才能运行。

## 仓库一览

| 仓库 | 作用 | GitHub | Gitee |
|------|------|--------|-------|
| im-server | 消息与长连接。好友、群、历史、已读、离线同步和一对一通话信令。端口 8080，库 `cao_im_db` | [im-server](https://github.com/cao-im/im-server) | [im-server](https://gitee.com/cao-im/im-server) |
| app-server | 客户端注册、登录、个人资料和文件上传。端口 8081，库 `cao_im_app_server` | [app-server](https://github.com/cao-im/app-server) | [app-server](https://gitee.com/cao-im/app-server) |
| im-admin | 运营后台：用户启停、群、消息检索、敏感词、系统配置、角色和审计。API 端口 8082，页面开发端口 5173，管理员表在 `cao_im_db` | [im-admin](https://github.com/cao-im/im-admin) | [im-admin](https://gitee.com/cao-im/im-admin) |
| im-sdk-flutter | 本仓库。Flutter SDK，负责 WebSocket、本地消息库、会话、群和通话信令，不包含界面 | [im-sdk-flutter](https://github.com/cao-im/im-sdk-flutter) | [im-sdk-flutter](https://gitee.com/cao-im/im-sdk-flutter) |
| flutter-demo | 客户端。同一套代码运行在 Windows、macOS、Android、iOS 和 Web | [flutter-demo](https://github.com/cao-im/flutter-demo) | [flutter-demo](https://gitee.com/cao-im/flutter-demo) |

## 消息收发流程

文本和表情由 SDK 通过 WebSocket 发给 im-server。图片、语音、文件和短视频先上传到 app-server，消息里只保存文件地址。服务端写入 MySQL 后，对方在线就立即推送，不在线就等对方上线再拉取。接收方展示后，再回送达回执和已读回执。

```mermaid
flowchart LR
  subgraph sendSide [发送方]
    ui1[Windows / App / Web]
    sdk1[im-sdk-flutter]
  end
  subgraph serviceSide [服务端]
    app[app-server]
    im[im-server]
    db[(MySQL)]
  end
  subgraph recvSide [接收方]
    sdk2[im-sdk-flutter]
    ui2[Windows / App / Web]
  end
  ui1 -->|文本、表情| sdk1
  ui1 -->|图片、语音、文件、视频| app
  app -->|文件地址| ui1
  sdk1 -->|WebSocket| im
  im -->|保存消息| db
  im -->|发送成功回执| sdk1
  im -->|在线立即推送| sdk2
  db -->|离线后拉取| sdk2
  sdk2 --> ui2
  ui2 -->|送达回执、已读回执| im
```

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

## 功能特性

连接

- 连接 `ws://{host}:8080/api/ws?token={imToken}`
- 断线后指数退避重连
- 心跳默认 30 秒，长时间无响应视为断开

消息

- 私聊、群聊发送
- 历史
- 撤回
- 已读
- 送达回执
- 离线消息同步
- Drift / SQLite 本地库
- 本地搜索
- 服务端搜索

会话与群

- 会话列表
- 置顶
- 消息免打扰
- 未读数
- 建群、改资料、解散
- 拉人、踢人、转让群主
- 好友申请事件

通话信令

- 一对一语音
- 一对一视频。`inviteCall` 传入 `video: true`
- 只收发信令，不采集麦克风和摄像头

事件

- 消息
- 连接
- 会话
- 群
- 好友
- 离线同步
- `CallSignalEvent`

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

## 常见问题

### 语音消息能转文字吗？

当前版本没有语音转文字。语音文件已经上传到 app-server，消息里只保存地址。要自己做的话，识别放在 app-server 项目中，模型不要打进客户端安装包。

在 `app-server/speech` 放置本机识别程序和模型，随应用服务一起部署。可以用 whisper.cpp 或 faster-whisper，加载开源 Whisper 模型，在自己的机器上识别。中文可用 `small`（约 500MB）或 `base`（约 150MB）。模型文件不要提交进 Git。

Spring Boot 增加一个需要登录的转写接口。客户端提交语音地址，服务端找到已经保存的文件，再调用这个目录里的识别程序，把文字返回。Java 通过本机命令或本机端口调用识别程序。单条语音最长 60 秒，普通 CPU 上通常要几秒到十几秒。网页、桌面和手机共用这个接口。

客户端在语音消息菜单里增加「转文字」，把结果展示在该条语音下面，并记在本机，同一条不必重复识别。Windows 和 Linux 的录音一般是 16kHz 单声道 wav，手机多是 aac，识别程序需要能读这些已保存的文件。

## 使用协议

源码公开，供学习和非商用免费使用。商用免费，但要先授权。完整条款见 [LICENSE](LICENSE)。

| 场景 | 是否收费 | 是否需要联系 |
|------|----------|----------------|
| 学习、研究、个人使用、教学 | 免费 | 不需要 |
| 非营利组织内部使用 | 免费 | 不需要 |
| 公司产品、向客户交付、收费服务等商用 | 免费 | 需要，先取得授权 |

MIT、Apache、GPL 都允许商用且不必通知作者，所以没有采用。未取得授权，请不要用于商用。

## 已授权项目

确认商用授权后，项目会写进 [已授权项目](docs/authorized-projects.md)。目录里展示项目名称、简介和公开链接，方便别人了解哪些产品在使用 CaoIM，也给这些项目一个公开展示的位置。

| 项目 | 说明 | 链接 |
|------|------|------|
| 友你 | 免费同城征婚交友。友你是一款同城相亲、征婚交友应用。填写真实资料，查看今日推荐，或用捞捞随机遇见正在寻觅的人。本人找对象、父母帮子女登记、红娘入驻，都可以从这里开始。 | [小米应用商店](https://r.app.xiaomi.com/details?id=com.youni.mobile&ref=search) |
| 友圈 | 友圈是一款以兴趣为核心的社交应用，覆盖游戏、二次元、艺术创作、树洞等兴趣圈子。在这里找到志同道合的伙伴，用图文、短视频记录生活，也看你关注的人最新发布的动态。 | [小米应用商店](https://r.app.xiaomi.com/details?id=com.youquan.mobile&ref=search) |
| 一木林 | 一木林是一款轻量好用的手机实用工具箱，把日常高频工具收进一个应用：证件照、时光沙漏、密码保险箱、水印相机、图库、文件管理、计算器、指南针、水平仪、尺子、单位换算、图片压缩、手持弹幕、提词器等即点即用，少装一堆小 App，手机更干净。支持 Android 与鸿蒙。 | [小米应用商店](https://r.app.xiaomi.com/details?id=com.yimulin.mobile&ref=search) |

申请时请说明项目名称、使用场景，以及可以公开的介绍或链接。

## 联系与支持

商用授权、新功能、定制开发或合作，都欢迎扫码加微信。商用授权不收费。

独立开发不易。如果这个项目对你有帮助，也可以通过微信或支付宝支持一下，你的认可是我继续更新的动力。

<table>
  <tr>
    <td align="center"><img src="docs/contact/wechat.jpg" alt="微信" width="220" /><br/><b>微信</b><br/>授权、定制与合作</td>
    <td align="center"><img src="docs/contact/wechat-pay.jpg" alt="微信支付" width="220" /><br/><b>微信支付</b></td>
    <td align="center"><img src="docs/contact/alipay.jpg" alt="支付宝" width="220" /><br/><b>支付宝</b></td>
  </tr>
</table>
