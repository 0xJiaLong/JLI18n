# AppKit integration

`AppKitLocalizationBinder` 支持文本框、按钮、菜单项和窗口标题。语言切换后由窗口或控制器生命周期调用 `refresh()`；无法安全热更新的系统对象应由宿主重建。
