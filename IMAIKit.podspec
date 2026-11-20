#
# Binary pod for the static XCFramework produced by Scripts/build_xcframeworks.sh.
# WCDB.swift stays a dependency of the host. libopus (static) is vendored next
# to IMAIKit and linked once by the host; it is not merged into IMAIKit.
#
Pod::Spec.new do |s|
  s.name             = 'IMAIKit'
  s.version          = '0.1.2'
  s.summary          = 'INMO X AI realtime voice and conversation store SDK (static XCFramework)'
  s.description      = <<-DESC
  INMO X 无 UI 的 AI 能力 SDK 静态二进制：实时语音对话（WSS）、Opus 编解码与 TTS 播放、
  按用户隔离的会话记录本地管理。WCDB.swift 由宿主工程链接同一份，不打进本 XCFramework；
  libopus 1.6.1 以单独的静态 xcframework 随包提供。
                       DESC

  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'jiangqi' => 'jiangqi@inmolens.com' }
  s.homepage         = 'https://github.com/INMO-X/IMAIKit'
  s.source           = { :git => 'https://github.com/INMO-X/IMAIKit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.swift_version    = '5.0'
  s.static_framework = true

  s.vendored_frameworks = [
    'XCFrameworks/IMAIKit.xcframework',
    'XCFrameworks/Frameworks/libopus.xcframework'
  ]

  s.frameworks = 'Foundation', 'UIKit', 'AVFoundation', 'QuartzCore'

  # 静态链接时随 App 拷贝的隐私清单。
  s.resource_bundles = {
    'IMAIKit' => ['IMAIKit/Resources/PrivacyInfo.xcprivacy']
  }

  s.dependency 'WCDB.swift', '2.1.16'
end
