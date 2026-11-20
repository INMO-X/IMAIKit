# IMAIKit 使用说明

无 UI 的 AI 能力 SDK：实时语音对话（WSS）、Opus 编解码与 TTS 播放、会话记录本地管理。数据全部按 `userID` 隔离，建连地址与鉴权 Header 由接入方注入。

## 安装

```ruby
platform :ios, '15.0'
use_frameworks! :linkage => :static   # dynamic 也可以

target 'YourApp' do
  pod 'IMAIKit', :git => 'https://github.com/INMO-X/IMAIKit.git', :tag => '0.1.2'
end
```

CocoaPods 会一起拉取 `WCDB.swift 2.1.16`，并链接随包的 `libopus.xcframework`（静态库）。宿主工程里不要再引入另一份 libopus，否则 `opus_*` 符号会重复。

```swift
import IMAIKit
```

## 1. 绑定用户

登录成功或切换账号后调用一次。会话记录、偏好、音频与图片都落在 `Documents/IMAIKit/<userID>/`。

```swift
IMAIKit.shared.configure(userID: currentUserID)
```

不调用不会崩溃，但数据会落到 `_anonymous` 桶，所有账号共用。

## 2. 注入建连信息

启动期设置一次。闭包在每次建连（含断线重连）时重新求值，返回 `nil` 表示暂不可连。

```swift
IMAIKit.shared.realtimeConnectInfoProvider = {
    guard let url = URL(string: "wss://<your-host>/api/v1/ai/realtime"),
          let token = currentAccessToken else { return nil }
    return IMAIRealtimeConnectInfo(url: url, headers: ["Authorization": "Bearer \(token)"])
}
```

## 3. 实时会话

```swift
let session = IMAIKit.shared.makeRealtimeSession(scene: .chat,
                                                inputModes: [.audio],
                                                outputModes: [.text, .audio])
let player = IMAIAudioPlayer(sampleRate: 24000, sessionMode: .voiceChat)
var replyText = ""

// 必须持有 token：释放即退订。回调在主线程。
let token = session.subscribe { update in
    switch update {
    case .sessionState(let state):
        if state == .ready { /* 此时才允许开始语音轮 */ }
    case .event(.asrFinal(_, let text)):
        uplink.stopTalk()                      // 立即停采集，避免把外放的 TTS 录进去
        _ = text
    case .event(.responseTextDelta(_, _, let text)):
        replyText += text
    case .event(.responseTextFinal(_, let text)):
        let full = text.isEmpty ? replyText : text   // final 可能是空串
        replyText = ""
        _ = full
    case .event(.audioBinary(let pcm)):
        player.enqueue(IMAIPCMDeclick.apply(pcm, sampleRate: 24000))
    case .event(.responseAudioEnd):
        player.finishWhenDrained()
    default:
        break
    }
}
session.connect()
```

## 4. 发送音频

手机麦克风（宿主需配置 `NSMicrophoneUsageDescription`，并在开始前自行申请麦克风权限）：

```swift
let uplink = IMAIVoiceUplink(session: session)
guard uplink.isAvailable else { return }
uplink.startTalk()     // 开始说话
uplink.stopTalk()      // 松手：补静音后结束本轮
uplink.cancel()        // 打断本轮
```

外部已编码的 Opus 帧（16 kHz / 单声道 / 20 ms）直接透传：

```swift
let turnId = session.startAudioTurn(codec: "opus", sampleRate: 16000, channels: 1)
session.sendAudioFrame(opusFrame)
session.endAudioTurn(turnId: turnId)
```

文本与图片：`session.sendText(_:)`、`session.sendImageReference(assetId:prompt:)`。

## 5. 结束会话

```swift
session.stop { /* 连接已确认关闭 */ }
IMAIKit.shared.shutdownRealtimeSession()   // 退出登录 / token 失效时兜底
```

## 6. 会话记录

```swift
let store = IMAIKit.shared.conversationStore
let conversation = store.dailyConversation(model: .chat,
                                           fallbackTitle: IMAIDailyConversationTitle.today())
store.append(message: IMAIMessage(role: .user, text: question), to: conversation.id)

let all = store.conversations()            // 按 updatedAt 倒序
let hits = store.search(keyword: "天气")
store.delete(id: conversation.id)          // 关联音频 / 图片一并清理

NotificationCenter.default.addObserver(forName: .imaiConversationsDidChange,
                                       object: nil, queue: .main) { _ in reload() }
```

音频路径与图片路径只存相对文件名，用 `IMAIAudioFileStore.url(for:)` / `IMAIImageFileStore` 解析。音频文件保留 7 天，进入 AI 页或启动时调用 `purgeExpired()`。

## 7. AI 偏好

```swift
IMAIKit.shared.preferences.model = .pet               // .chat / .pet / .translate
IMAIKit.shared.preferences.petKind = .cat
// 变更通知：.imaiPreferencesDidChange
```

## 注意事项

- 同一时刻只保留一条实时会话，统一通过 `IMAIKit.shared.makeRealtimeSession` 创建；绕过工厂会收到 `SCENE_BUSY`。
- `IMAIVoiceUplink.onPCMFrame`、`IMAIAudioRecorder.onFrame` 在音频采集线程回调，不要在其中更新 UI。
- App 退到后台仍要播放 TTS 时，需要开启 `audio` 后台模式。
- `IMAIKit.shared.service`（`IMAIChatService`）是占位实现，对话请走 `IMAIRealtimeSession`。
- 二进制是 Release 构建，日志前缀 `[IMAIRealtime]`。
