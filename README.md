# IMAIKit

INMO 无 UI 的 AI 能力 SDK 的 **静态 XCFramework**：实时语音对话（WSS）、Opus 编解码与 TTS 播放、会话记录本地管理（WCDB，按用户隔离）。

WCDB.swift **不打进包**，由宿主链接同一份。libopus 1.6.1 以单独的静态 `libopus.xcframework` 随包提供。

---

## 环境要求

- iOS 15.0+
- Swift 5
- Xcode 15+
- CocoaPods，并开启 `use_frameworks!`

## 安装

```ruby
platform :ios, '15.0'
use_frameworks! :linkage => :static

target 'YourApp' do
  pod 'IMAIKit', :git => 'https://github.com/INMO-X/IMAIKit.git', :tag => '0.1.2'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 15.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      end
    end
  end
end
```

依赖版本与打这个包时一致：WCDB.swift 2.1.16。宿主不要再引入另一份 libopus，否则 `opus_*` 符号会重复。

建连地址与鉴权 Header 由宿主通过 `IMAIKit.shared.realtimeConnectInfoProvider` 注入，SDK 不依赖账号或网络层。

## 宿主 Info.plist

走手机麦克风时需要 `NSMicrophoneUsageDescription`，并在开始录音前自行申请权限。后台播放 TTS 需要 `audio` 后台模式。详见 [docs/PRIVACY.md](docs/PRIVACY.md)。

## 示例

[Example/](Example/) 用 tag `0.1.2` 绑定用户、写入并读取一条会话记录、切换 AI 偏好，并检查 Opus 编码器可用。

```bash
cd Example
pod install
open IMAIKit.xcworkspace
```

## 文档

| 文档 | 说明 |
|------|------|
| [docs/USAGE.md](docs/USAGE.md) | 场景用法 |
| [docs/PRIVACY.md](docs/PRIVACY.md) | 隐私清单与宿主配置 |
| [ThirdPartyNotices/libopus-COPYING](ThirdPartyNotices/libopus-COPYING) | libopus 许可（BSD） |
