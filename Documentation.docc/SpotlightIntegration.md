# Spotlight integration

JLI18n Package 本身不产生可索引的业务实体，因此 Spotlight 由宿主 App 配置。宿主应在首次启动完成后创建 `CSSearchableItem` 或 `NSUserActivity`，覆盖以下关键词：

- `JLI18n`、`JL 国际化`
- `国际化`、`多语言`、`语言切换`、`本地化`
- `internationalization`、`localization`、`language switching`

验收：首次启动完成索引后，在 iOS/iPadOS/macOS Spotlight 搜索上述关键词，确认结果名称正确，并点击结果确认能打开宿主 App 或对应内容。
