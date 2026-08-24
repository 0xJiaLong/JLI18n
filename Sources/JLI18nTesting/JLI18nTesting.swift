import Foundation
import JLI18n

public struct InMemoryLocalizationProvider: LocalizationProvider {
    public let values: [LocaleIdentifier: [LocalizationKey: String]]

    public init(values: [LocaleIdentifier: [LocalizationKey: String]]) {
        self.values = values
    }

    public func localizedString(for key: LocalizationKey, locale: LocaleIdentifier) -> String? {
        values[locale]?[key]
    }
}

public final class DiagnosticCollector: LocalizationDiagnosticSink, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [LocalizationDiagnostic] = []

    public init() {}

    public func record(_ diagnostic: LocalizationDiagnostic) {
        lock.lock()
        values.append(diagnostic)
        lock.unlock()
    }

    public var diagnostics: [LocalizationDiagnostic] {
        lock.lock()
        defer { lock.unlock() }
        return values
    }

    public func removeAll() {
        lock.lock()
        values.removeAll()
        lock.unlock()
    }
}
