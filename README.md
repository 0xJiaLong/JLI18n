# JLI18n

跨 Apple 平台的本地化 Swift Package，统一资源读取、语言切换、Locale 回退、参数格式化、复数文案和缺失 Key 诊断。

## 快速开始

```swift
import JLI18n

let configuration = LocalizationConfiguration(
    defaultLocale: "en",
    supportedLocales: ["en", "zh-Hans"],
    fallbackLocale: "en"
)
let i18n = LocalizationManager(
    configuration: configuration,
    providers: [BundleLocalizationProvider(bundle: JLI18nResources.bundle)]
)

let title = await i18n.string(for: "home.title")
```

产品代码依赖稳定的 `LocalizationKey`，不直接散落 `NSLocalizedString`。UIKit、AppKit 和 SwiftUI 集成分别从对应产品导入。

AlarmKit 等要求 `LocalizedStringResource` 的 Apple API 使用同一个 manager 入口：

```swift
let resource = await i18n.resource(for: "alarm.button.stop")
```

该接口保留 Key 与当前 Locale 供系统延迟解析；语言切换后需要重新创建并更新系统配置。

## 支持范围

- iOS / iPadOS 16+
- macOS 13+
- `.strings`、`.stringsdict`、Xcode 编译后的 `.xcstrings`

远程翻译、CLI、代码生成和第三方状态管理不属于当前 MVP。
