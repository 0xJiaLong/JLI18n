#if canImport(UIKit)
import JLI18n
import UIKit

@MainActor
public final class UIKitLocalizationBinder {
    private let manager: LocalizationManager
    private var updates: [() -> Void] = []

    public init(manager: LocalizationManager) {
        self.manager = manager
    }

    public func bind(label: UILabel, key: LocalizationKey, arguments: [any CVarArg] = []) {
        let arguments = LocalizationArguments(arguments)
        updates.append { [weak label, manager] in
            guard let label else { return }
            let task = Task.detached { await manager.string(for: key, arguments: arguments) }
            Task { @MainActor in
                label.text = await task.value
            }
        }
        refresh()
    }

    public func bind(button: UIButton, key: LocalizationKey, state: UIControl.State = .normal, arguments: [any CVarArg] = []) {
        let arguments = LocalizationArguments(arguments)
        updates.append { [weak button, manager] in
            guard let button else { return }
            let task = Task.detached { await manager.string(for: key, arguments: arguments) }
            Task { @MainActor in
                button.setTitle(await task.value, for: state)
            }
        }
        refresh()
    }

    public func bind(textField: UITextField, key: LocalizationKey, arguments: [any CVarArg] = []) {
        let arguments = LocalizationArguments(arguments)
        updates.append { [weak textField, manager] in
            guard let textField else { return }
            let task = Task.detached { await manager.string(for: key, arguments: arguments) }
            Task { @MainActor in
                textField.placeholder = await task.value
            }
        }
        refresh()
    }

    public func bind(barItem: UIBarItem, key: LocalizationKey, arguments: [any CVarArg] = []) {
        let arguments = LocalizationArguments(arguments)
        updates.append { [weak barItem, manager] in
            guard let barItem else { return }
            let task = Task.detached { await manager.string(for: key, arguments: arguments) }
            Task { @MainActor in
                barItem.title = await task.value
            }
        }
        refresh()
    }

    public func refresh() {
        updates.forEach { $0() }
    }
}
#endif
