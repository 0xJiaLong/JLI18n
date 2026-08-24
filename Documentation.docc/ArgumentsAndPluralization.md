# Arguments and pluralization

资源保留 Foundation 格式说明符，调用侧只传参数：

```swift
let text = await i18n.string(for: "welcome.user", arguments: "Jack")
let count = await i18n.string(for: "cart.item_count", arguments: Int64(3))
```

支持 `%@`、`%ld`、`%lld`、`%f`、位置参数和 `%%`。数量文案使用 `.stringsdict` 或 `.xcstrings` plural 规则，业务层不手动判断 `count == 1`。
