# Language switching

`LocalizationManager` 是 actor。切换语言后，新的 Locale 会被归一化、持久化并通过 `localeChanges()` 发布。

```swift
await i18n.setLocale("zh-Hans")
let title = await i18n.string(for: "home.title")
```

不支持的 Locale 会优先匹配相同语言，再回到 `fallbackLocale`，不会产生半有效状态。
