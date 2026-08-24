import Foundation

public struct LocalizationKey: Hashable, Codable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }
}

/// Format arguments are captured before crossing the actor boundary and are never mutated by JLI18n.
public struct LocalizationArguments: @unchecked Sendable {
    public let values: [any CVarArg]

    public init(_ values: [any CVarArg] = []) {
        self.values = values
    }
}

public struct LocaleIdentifier: Hashable, Codable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = Self.canonicalize(rawValue)
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    public var foundationLocale: Locale {
        Locale(identifier: rawValue)
    }

    public var languageCode: String? {
        foundationLocale.language.languageCode?.identifier
    }

    public var scriptCode: String? {
        foundationLocale.language.script?.identifier
    }

    public var regionCode: String? {
        foundationLocale.language.region?.identifier
    }

    private static func canonicalize(_ value: String) -> String {
        let parts = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "-")
            .split(separator: "-")
            .map(String.init)
            .filter { !$0.isEmpty }
        guard !parts.isEmpty else { return "" }

        return parts.enumerated().map { index, part in
            if index == 0 { return part.lowercased() }
            if part.count == 4 { return part.prefix(1).uppercased() + part.dropFirst().lowercased() }
            if part.count == 2 || (part.count == 3 && part.allSatisfy(\.isNumber)) { return part.uppercased() }
            return part
        }.joined(separator: "-")
    }
}

public protocol LocalePersistence: Sendable {
    func load() -> LocaleIdentifier?
    func save(_ locale: LocaleIdentifier)
}

public struct UserDefaultsLocalePersistence: LocalePersistence, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "JLI18n.locale") {
        self.defaults = defaults
        self.key = key
    }

    public func load() -> LocaleIdentifier? {
        guard let value = defaults.string(forKey: key) else { return nil }
        return LocaleIdentifier(value)
    }

    public func save(_ locale: LocaleIdentifier) {
        defaults.set(locale.rawValue, forKey: key)
    }
}

public struct LocalizationDiagnosticsOptions: Sendable {
    public enum Mode: Sendable {
        case reportOnly
        case assertInDebug
    }

    public enum Fallback: Sendable {
        case key
        case missingMarker
        case custom(String)
    }

    public let mode: Mode
    public let fallback: Fallback

    public init(mode: Mode = .assertInDebug, fallback: Fallback = .missingMarker) {
        self.mode = mode
        self.fallback = fallback
    }
}

public struct LocalizationDiagnostic: Sendable, Equatable {
    public enum Kind: String, Sendable {
        case missingKey
        case missingArgument
        case argumentTypeMismatch
        case invalidFormat
        case resourceConflict
        case unsupportedLocale
    }

    public let kind: Kind
    public let key: LocalizationKey
    public let locale: LocaleIdentifier
    public let message: String

    public init(kind: Kind, key: LocalizationKey, locale: LocaleIdentifier, message: String) {
        self.kind = kind
        self.key = key
        self.locale = locale
        self.message = message
    }
}

public protocol LocalizationDiagnosticSink: Sendable {
    func record(_ diagnostic: LocalizationDiagnostic)
}

public struct NoopLocalizationDiagnosticSink: LocalizationDiagnosticSink {
    public init() {}
    public func record(_ diagnostic: LocalizationDiagnostic) {}
}

public struct LocalizationConfiguration: Sendable {
    public let defaultLocale: LocaleIdentifier
    public let supportedLocales: [LocaleIdentifier]
    public let fallbackLocale: LocaleIdentifier
    public let persistence: any LocalePersistence
    public let diagnostics: LocalizationDiagnosticsOptions

    public init(
        defaultLocale: LocaleIdentifier,
        supportedLocales: [LocaleIdentifier],
        fallbackLocale: LocaleIdentifier,
        persistence: any LocalePersistence = UserDefaultsLocalePersistence(),
        diagnostics: LocalizationDiagnosticsOptions = LocalizationDiagnosticsOptions()
    ) {
        self.defaultLocale = defaultLocale
        self.supportedLocales = supportedLocales
        self.fallbackLocale = fallbackLocale
        self.persistence = persistence
        self.diagnostics = diagnostics
    }
}

public enum LocalizationSource: @unchecked Sendable {
    case bundle(Bundle)
    case inMemory([LocaleIdentifier: [LocalizationKey: String]])
    case composite([any LocalizationProvider])
}

public enum JLI18nResources {
    public static var bundle: Bundle { .module }
}
