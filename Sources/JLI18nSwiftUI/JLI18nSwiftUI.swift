import Foundation
import JLI18n
import SwiftUI

@MainActor
public final class JLI18nEnvironment: ObservableObject {
    @Published public private(set) var locale: LocaleIdentifier
    public let manager: LocalizationManager
    private var observationTask: Task<Void, Never>?
    private var localeTask: Task<Void, Never>?

    public init(manager: LocalizationManager, initialLocale: LocaleIdentifier) {
        self.manager = manager
        self.locale = initialLocale
        observationTask = Task { [weak self, manager] in
            let changes = await manager.localeChanges()
            for await locale in changes {
                guard !Task.isCancelled else { return }
                self?.locale = locale
            }
        }
    }

    deinit {
        observationTask?.cancel()
        localeTask?.cancel()
    }

    public func setLocale(_ locale: LocaleIdentifier) {
        localeTask?.cancel()
        localeTask = Task { [weak self] in
            guard let self else { return }
            await manager.setLocale(locale)
            guard !Task.isCancelled else { return }
            let current = await manager.currentLocale
            guard !Task.isCancelled else { return }
            self.locale = current
        }
    }

    public func resolve(_ key: LocalizationKey, arguments: LocalizationArguments = .init()) async -> String {
        await manager.string(for: key, arguments: arguments)
    }
}

public struct LocalizedText: View {
    private let key: LocalizationKey
    private let arguments: LocalizationArguments
    @EnvironmentObject private var environment: JLI18nEnvironment
    @State private var resolvedValue: String?

    public init(key: LocalizationKey, arguments: [any CVarArg] = []) {
        self.key = key
        self.arguments = LocalizationArguments(arguments)
    }

    public var body: some View {
        Text(resolvedValue ?? key.rawValue)
            .task(id: environment.locale) {
                resolvedValue = await environment.resolve(key, arguments: arguments)
            }
    }
}

public extension View {
    func jli18n(_ environment: JLI18nEnvironment) -> some View {
        environmentObject(environment)
    }
}
