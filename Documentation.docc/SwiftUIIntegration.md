# SwiftUI integration

使用 `JLI18nEnvironment` 注入运行时，用 `LocalizedText` 渲染异步本地化结果。语言变化会触发重新解析和重绘。

```swift
let environment = JLI18nEnvironment(manager: i18n, initialLocale: "en")
ContentView().jli18n(environment)

LocalizedText(key: "home.title")
```
