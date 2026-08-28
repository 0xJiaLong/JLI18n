# JLI18n 已并入 JLKit

源码与后续开发在：

https://github.com/0xJiaLong/JLKit.git

产品依赖改为：

```swift
.package(url: "https://github.com/0xJiaLong/JLKit.git", revision: "ab054bc")
```

```swift
.product(name: "JLI18n", package: "JLKit")
.product(name: "JLI18nSwiftUI", package: "JLKit")
```

公开类型名不变。本仓库冻结于 `67b007d`，不再接受功能提交。
