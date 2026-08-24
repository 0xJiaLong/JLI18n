# Migration guide

1. 保留现有 `.strings` / `.stringsdict`，先注入 `BundleLocalizationProvider`。
2. 将散落的 `NSLocalizedString` 替换为 `LocalizationKey`。
3. 为高频参数文案补格式校验和测试。
4. 新增文案优先使用 `.xcstrings`。
5. 稳定后再引入代码生成或 CI lint 工具。
