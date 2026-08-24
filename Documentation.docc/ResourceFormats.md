# Resource formats

Bundle Provider 支持传统 `.strings`、`.stringsdict`，以及 Xcode 编译后的 `.xcstrings`。JLI18n 不在运行时解析 `.xcstrings` JSON；资源由平台构建工具编译后，统一走 Bundle 的本地化接口。

Package 默认资源放在 `Sources/JLI18n/Resources`，应用自己的资源应显式传入应用 Bundle。

同一 Target 不要同时放置同名表的 `.xcstrings` 与已编译的 `.strings` / `.stringsdict`：Xcode 会将它们生成到相同的 `Localizable.strings` 输出并报重复资源。三种格式的回归 fixture 分别保存在测试 Bundle 中，宿主 App 可按资源格式选择其一。
