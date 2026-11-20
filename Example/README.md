# IMAIKit Example

可运行 Demo，依赖公开仓 tag `0.1.2` 的 IMAIKit 静态库。

```bash
cd Example
pod install
open IMAIKit.xcworkspace
```

选择 scheme **IMAIKit_Example**。首页检查 Opus 编码器（随包 libopus）是否可用，可以写入今天的一条对话并看到会话 / 消息计数变化，点按切换 AI 模型偏好。不连接服务端。

本地未推送 tag 时，把 Podfile 里的 `:git` 行换成注释中的 `:path`。
