#if canImport(AppKit)
import AppKit
import JLI18n

@MainActor
public final class AppKitLocalizationBinder {
    private let manager: LocalizationManager
    private var updates: [() -> Void] = []
    private var tasks: [Task<Void, Never>] = []

    public init(manager: LocalizationManager) {
        self.manager = manager
    }

    public func bind(textField: NSTextField, key: LocalizationKey, arguments: [any CVarArg] = []) {
        let arguments = LocalizationArguments(arguments)
        updates.append { [weak self, weak textField, manager] in
            guard let self, textField != nil else { return }
            let request = Task.detached { await manager.string(for: key, arguments: arguments) }
            let task = Task { @MainActor [weak textField] in
                defer { request.cancel() }
                guard let textField else { return }
                let value = await request.value
                guard !Task.isCancelled else { return }
                textField.stringValue = value
            }
            self.tasks.append(task)
        }
        refresh()
    }

    public func bind(button: NSButton, key: LocalizationKey, arguments: [any CVarArg] = []) {
        let arguments = LocalizationArguments(arguments)
        updates.append { [weak self, weak button, manager] in
            guard let self, button != nil else { return }
            let request = Task.detached { await manager.string(for: key, arguments: arguments) }
            let task = Task { @MainActor [weak button] in
                defer { request.cancel() }
                guard let button else { return }
                let value = await request.value
                guard !Task.isCancelled else { return }
                button.title = value
            }
            self.tasks.append(task)
        }
        refresh()
    }

    public func bind(menuItem: NSMenuItem, key: LocalizationKey, arguments: [any CVarArg] = []) {
        let arguments = LocalizationArguments(arguments)
        updates.append { [weak self, weak menuItem, manager] in
            guard let self, menuItem != nil else { return }
            let request = Task.detached { await manager.string(for: key, arguments: arguments) }
            let task = Task { @MainActor [weak menuItem] in
                defer { request.cancel() }
                guard let menuItem else { return }
                let value = await request.value
                guard !Task.isCancelled else { return }
                menuItem.title = value
            }
            self.tasks.append(task)
        }
        refresh()
    }

    public func bind(window: NSWindow, key: LocalizationKey, arguments: [any CVarArg] = []) {
        let arguments = LocalizationArguments(arguments)
        updates.append { [weak self, weak window, manager] in
            guard let self, window != nil else { return }
            let request = Task.detached { await manager.string(for: key, arguments: arguments) }
            let task = Task { @MainActor [weak window] in
                defer { request.cancel() }
                guard let window else { return }
                let value = await request.value
                guard !Task.isCancelled else { return }
                window.title = value
            }
            self.tasks.append(task)
        }
        refresh()
    }

    public func refresh() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll(keepingCapacity: true)
        updates.forEach { $0() }
    }

    deinit {
        tasks.forEach { $0.cancel() }
    }
}
#endif
