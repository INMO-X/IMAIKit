# Privacy（IMAIKit）

框架自带的隐私清单，以及宿主 App 仍需自己配置的部分。

## 隐私清单（`PrivacyInfo.xcprivacy`）

源码路径：`IMAIKit/Resources/PrivacyInfo.xcprivacy`。

| Key | 取值 |
|-----|------|
| `NSPrivacyTracking` | `false`。框架不做跨 App / 网站追踪。 |
| `NSPrivacyTrackingDomains` | 空。 |
| `NSPrivacyCollectedDataTypes` | 见下表。 |
| `NSPrivacyAccessedAPITypes` | 见下表。 |

| 收集的数据 | 关联用户 | 追踪 | 目的 | 说明 |
|------------|----------|------|------|------|
| `NSPrivacyCollectedDataTypeAudioData` | 是 | 否 | App 功能 | 语音轮把麦克风采集或外部传入的 Opus 音频发给宿主配置的 AI 实时网关，用于识别与回复。 |
| `NSPrivacyCollectedDataTypeOtherUserContent` | 是 | 否 | App 功能 | 文本提问与对话内容发给 AI 网关，并在本机按用户存入 WCDB。 |
| `NSPrivacyCollectedDataTypePhotosorVideos` | 是 | 否 | App 功能 | `sendImageReference` 发送用户图片的引用用于识图；附图文件存在本机。 |

建连地址与鉴权 Header 由宿主注入，数据发往宿主自己的服务端。如果宿主的服务端还把数据交给其他方，需要在 App 的隐私报告里另行声明。

| API | 原因码 | 代码里的用途 |
|-----|--------|----------------|
| UserDefaults | `CA92.1` | `IMAIUserDefaultsPreferencesStore` 按用户保存对话方式 / 模型偏好；`IMAIWCDBConversationStore` 记录一次性数据迁移标记。只在本 App 内读写。 |
| File timestamp | `C617.1` | `IMAIAudioFileStore` / `IMAIImageFileStore` 读取 App 容器内文件的创建时间与大小，用于 7 天保留期清理和占用统计。 |

## 二进制消费者拿到清单的两个位置

1. **每个 XCFramework 切片内**：`IMAIKit.framework/PrivacyInfo.xcprivacy`。
2. **CocoaPods resource bundle** `IMAIKit.bundle`：静态链接不会把 framework 目录嵌进 App，清单还放在资源包根目录，随 `[CP] Copy Pods Resources` 进包。

## 宿主仍需自己声明的部分

- 使用 `IMAIVoiceUplink` / `IMAIAudioRecorder` 时，Info.plist 配置 `NSMicrophoneUsageDescription`，并在开始录音前自行申请麦克风权限（SDK 不弹权限框）。
- 后台播放 TTS 需要 `UIBackgroundModes` 包含 `audio`。

WCDB.swift（WCDBOptimizedSQLCipher）的隐私清单随它自己的 pod 进包。libopus 是纯编解码库，不访问 Required Reason API。
