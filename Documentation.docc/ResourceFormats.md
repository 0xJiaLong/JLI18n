# Resource formats

Bundle Provider 支持传统 `.strings`、`.stringsdict`，以及 Xcode 编译后的 `.xcstrings`。JLI18n 不在运行时解析 `.xcstrings` JSON；资源由平台构建工具编译后，统一走 Bundle 的本地化接口。

Package 默认资源放在 `Sources/JLI18n/Resources`，应用自己的资源应显式传入应用 Bundle。
