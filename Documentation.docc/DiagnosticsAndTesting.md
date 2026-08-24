# Diagnostics and testing

诊断事件覆盖缺失 Key、参数不足、类型不匹配、非法格式、资源冲突和不支持 Locale。Release 默认返回可识别 fallback，不记录参数值或完整敏感文案。

测试通过 `JLI18nTesting` 的 `InMemoryLocalizationProvider` 和 `DiagnosticCollector` 构造确定性 fixture。
