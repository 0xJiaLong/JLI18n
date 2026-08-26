# Apple system resources

普通 UI 使用 ``LocalizationManager/string(for:arguments:)`` 立即解析文案。AlarmKit 等 Apple API 要求 `LocalizedStringResource` 时，使用同一个 ``LocalizationKey`` 从 manager 创建延迟解析资源：

```swift
let text = await manager.resource(for: "alarm.button.stop")
let button = AlarmButton(
    text: text,
    textColor: .white,
    systemImageName: "stop.fill"
)
```

``LocalizationManager/resource(for:table:bundle:)`` 会保留 Key、资源表、Bundle 描述和 manager 当前 Locale，供系统组件稍后解析。它不会把 JLI18n Provider 已解析的 `String` 包装成新的资源 Key。

资源 Key 必须存在于宿主 App 可供系统读取的 String Catalog 或 strings 表中。App 内语言切换后，应使用新的 manager Locale 重新创建资源，并更新或重新注册相应系统配置；已提交给系统的 `AlarmButton` 不会自动观察语言变化。
