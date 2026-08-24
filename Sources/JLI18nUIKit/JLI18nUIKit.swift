#if canImport(UIKit)
import JLI18n
import UIKit

@MainActor
public final class UIKitLocalizationBinder {
    private let manager: LocalizationManager
    private var updates: [() -> Void] = []
    private var tasks: [Task<Void, Never>] = []

    public init(manager: LocalizationManager) {
        self.manager = manager
    }

    public func bind(label: UILabel, key: LocalizationKey, arguments: [any CVarArg] = []) {
        let arguments = LocalizationArguments(arguments)
        updates.append { [weak self, weak label, manager] in
            guard let self, label != nil else { return }
            let request = Task.detached { await manager.string(for: key, arguments: arguments) }
            let task = Task { @MainActor [weak label] in
                defer { request.cancel() }
                guard let label else { return }
                let value = await request.value
                guard !Task.isCancelled else { return }
                label.text = value
            }
            self.tasks.append(task)
        }
        refresh()
    }

    public func bind(button: UIButton, key: LocalizationKey, state: UIControl.State = .normal, arguments: [any CVarArg] = []) {
        let arguments = LocalizationArguments(arguments)
        updates.append { [weak self, weak button, manager] in
            guard let self, button != nil else { return }
            let request = Task.detached { await manager.string(for: key, arguments: arguments) }
            let task = Task { @MainActor [weak button] in
                defer { request.cancel() }
                guard let button else { return }
                let value = await request.value
                guard !Task.isCancelled else { return }
                button.setTitle(value, for: state)
            }
            self.tasks.append(task)
        }
        refresh()
    }

    public func bind(textField: UITextField, key: LocalizationKey, arguments: [any CVarArg] = []) {
        let arguments = LocalizationArguments(arguments)
        updates.append { [weak self, weak textField, manager] in
            guard let self, textField != nil else { return }
            let request = Task.detached { await manager.string(for: key, arguments: arguments) }
            let task = Task { @MainActor [weak textField] in
                defer { request.cancel() }
                guard let textField else { return }
                let value = await request.value
                guard !Task.isCancelled else { return }
                textField.placeholder = value
            }
            self.tasks.append(task)
        }
        refresh()
    }

    public func bind(barItem: UIBarItem, key: LocalizationKey, arguments: [any CVarArg] = []) {
        let arguments = LocalizationArguments(arguments)
        updates.append { [weak self, weak barItem, manager] in
            guard let self, barItem != nil else { return }
            let request = Task.detached { await manager.string(for: key, arguments: arguments) }
            let task = Task { @MainActor [weak barItem] in
                defer { request.cancel() }
                guard let barItem else { return }
                let value = await request.value
                guard !Task.isCancelled else { return }
                barItem.title = value
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
