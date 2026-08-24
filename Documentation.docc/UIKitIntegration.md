# UIKit integration

`UIKitLocalizationBinder` 通过显式绑定控件和 Key 管理展示文本。ViewController 在收到语言变化后调用 `refresh()`，业务规则仍留在 feature 层。
