#if canImport(AppKit)
import AppKit
import JLI18n

@MainActor
public final class AppKitLocalizationBinder {
    private let manager: LocalizationManager
    private var updates: [() -> Void] = []

    public init(manager: LocalizationManager) {
        self.manager = manager
    }

    public func bind(textField: NSTextField, key: LocalizationKey, arguments: [any CVarArg] = []) {
        let arguments = LocalizationArguments(arguments)
        updates.append { [weak textField, manager] in
            guard let textField else { return }
            let task = Task.detached { await manager.string(for: key, arguments: arguments) }
            Task { @MainActor in
                textField.stringValue = await task.value
            }
        }
        refresh()
    }

    public func bind(button: NSButton, key: LocalizationKey, arguments: [any CVarArg] = []) {
        let arguments = LocalizationArguments(arguments)
        updates.append { [weak button, manager] in
            guard let button else { return }
            let task = Task.detached { await manager.string(for: key, arguments: arguments) }
            Task { @MainActor in
                button.title = await task.value
            }
        }
        refresh()
    }

    public func bind(menuItem: NSMenuItem, key: LocalizationKey, arguments: [any CVarArg] = []) {
        let arguments = LocalizationArguments(arguments)
        updates.append { [weak menuItem, manager] in
            guard let menuItem else { return }
            let task = Task.detached { await manager.string(for: key, arguments: arguments) }
            Task { @MainActor in
                menuItem.title = await task.value
            }
        }
        refresh()
    }

    public func bind(window: NSWindow, key: LocalizationKey, arguments: [any CVarArg] = []) {
        let arguments = LocalizationArguments(arguments)
        updates.append { [weak window, manager] in
            guard let window else { return }
            let task = Task.detached { await manager.string(for: key, arguments: arguments) }
            Task { @MainActor in
                window.title = await task.value
            }
        }
        refresh()
    }

    public func refresh() {
        updates.forEach { $0() }
    }
}
#endif
