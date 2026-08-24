import Foundation

public actor LocalizationManager {
    public static let shared = LocalizationManager(
        configuration: LocalizationConfiguration(
            defaultLocale: LocaleIdentifier("en"),
            supportedLocales: [LocaleIdentifier("en")],
            fallbackLocale: LocaleIdentifier("en")
        ),
        providers: [BundleLocalizationProvider(bundle: JLI18nResources.bundle)]
    )

    public nonisolated let configuration: LocalizationConfiguration
    private let providers: [any LocalizationProvider]
    private let diagnosticSink: any LocalizationDiagnosticSink
    private var locale: LocaleIdentifier
    private var localeContinuations: [UUID: AsyncStream<LocaleIdentifier>.Continuation] = [:]

    public init(
        configuration: LocalizationConfiguration,
        providers: [any LocalizationProvider],
        diagnosticSink: any LocalizationDiagnosticSink = NoopLocalizationDiagnosticSink()
    ) {
        self.configuration = configuration
        self.providers = providers
        self.diagnosticSink = diagnosticSink
        let persisted = configuration.persistence.load()
        self.locale = Self.normalize(
            persisted ?? configuration.defaultLocale,
            supported: configuration.supportedLocales,
            fallback: configuration.fallbackLocale
        )
    }

    public var currentLocale: LocaleIdentifier { locale }

    public func setLocale(_ requested: LocaleIdentifier) async {
        let normalized = Self.normalize(
            requested,
            supported: configuration.supportedLocales,
            fallback: configuration.fallbackLocale
        )
        if normalized != requested {
            diagnosticSink.record(LocalizationDiagnostic(
                kind: .unsupportedLocale,
                key: LocalizationKey("<locale>"),
                locale: requested,
                message: "Requested locale was normalized to \(normalized.rawValue)"
            ))
        }
        guard normalized != locale else { return }
        locale = normalized
        configuration.persistence.save(normalized)
        localeContinuations.values.forEach { $0.yield(normalized) }
    }

    public func localeChanges() -> AsyncStream<LocaleIdentifier> {
        let id = UUID()
        return AsyncStream { continuation in
            localeContinuations[id] = continuation
            continuation.yield(locale)
            continuation.onTermination = { _ in
                Task { await self.removeContinuation(id) }
            }
        }
    }

    public func string(for key: LocalizationKey, arguments: CVarArg...) async -> String {
        resolve(key: key, arguments: arguments)
    }

    public func string(for key: LocalizationKey, arguments: LocalizationArguments) async -> String {
        resolve(key: key, arguments: arguments.values)
    }

    private func resolve(key: LocalizationKey, arguments: [any CVarArg]) -> String {
        let requestedLocale = locale
        var value: String?
        for candidate in fallbackChain(for: requestedLocale) {
            var candidateValues: [String] = []
            for provider in providers {
                if let resolved = provider.localizedString(for: key, locale: candidate) {
                    candidateValues.append(resolved)
                }
            }
            if let first = candidateValues.first {
                value = first
                if Set(candidateValues).count > 1 {
                    report(.resourceConflict, key: key, locale: candidate, message: "Multiple providers returned different values")
                }
            }
            if value != nil { break }
        }

        guard let format = value else {
            report(.missingKey, key: key, locale: requestedLocale, message: "No localized value was found")
            return fallback(for: key)
        }

        if format.contains("%#@") {
            guard !arguments.isEmpty else {
                report(.missingArgument, key: key, locale: requestedLocale, message: "Pluralized text requires a quantity argument")
                return fallback(for: key)
            }
            return localizedPluralString(format, arguments: arguments)
        }

        switch FormatValidator.validate(format, arguments: arguments) {
        case .valid:
            return String(format: format, locale: requestedLocale.foundationLocale, arguments: arguments)
        case .missingArgument(let expected, let actual):
            report(.missingArgument, key: key, locale: requestedLocale, message: "Expected \(expected) arguments, received \(actual)")
        case .typeMismatch(let index, let specifier):
            report(.argumentTypeMismatch, key: key, locale: requestedLocale, message: "Argument \(index) is incompatible with %\(specifier)")
        case .invalidFormat(let message):
            report(.invalidFormat, key: key, locale: requestedLocale, message: message)
        }
        return fallback(for: key)
    }

    private func localizedPluralString(_ format: String, arguments: [any CVarArg]) -> String {
        switch arguments.count {
        case 1: return String.localizedStringWithFormat(format, arguments[0])
        case 2: return String.localizedStringWithFormat(format, arguments[0], arguments[1])
        case 3: return String.localizedStringWithFormat(format, arguments[0], arguments[1], arguments[2])
        default: return String(format: format, arguments: arguments)
        }
    }

    private func fallbackChain(for locale: LocaleIdentifier) -> [LocaleIdentifier] {
        var result: [LocaleIdentifier] = [locale]
        if let language = locale.languageCode, let script = locale.scriptCode {
            result.append(LocaleIdentifier("\(language)-\(script)"))
        }
        if let language = locale.languageCode { result.append(LocaleIdentifier(language)) }
        result.append(configuration.fallbackLocale)
        var unique: [LocaleIdentifier] = []
        for candidate in result where !unique.contains(candidate) {
            unique.append(candidate)
        }
        return unique
    }

    private func fallback(for key: LocalizationKey) -> String {
        switch configuration.diagnostics.fallback {
        case .key: return key.rawValue
        case .missingMarker: return "[missing: \(key.rawValue)]"
        case .custom(let value): return value
        }
    }

    private func report(_ kind: LocalizationDiagnostic.Kind, key: LocalizationKey, locale: LocaleIdentifier, message: String) {
        let diagnostic = LocalizationDiagnostic(kind: kind, key: key, locale: locale, message: message)
        diagnosticSink.record(diagnostic)
        #if DEBUG
        if case .assertInDebug = configuration.diagnostics.mode {
            assertionFailure("JLI18n \(kind.rawValue): \(message)")
        }
        #endif
    }

    private func removeContinuation(_ id: UUID) {
        localeContinuations[id] = nil
    }

    private static func normalize(_ requested: LocaleIdentifier, supported: [LocaleIdentifier], fallback: LocaleIdentifier) -> LocaleIdentifier {
        if let exact = supported.first(where: { $0.rawValue.caseInsensitiveCompare(requested.rawValue) == .orderedSame }) {
            return exact
        }
        if let language = requested.languageCode,
           let match = supported.first(where: { $0.languageCode == language }) {
            return match
        }
        return supported.first(where: { $0.rawValue == fallback.rawValue }) ?? fallback
    }
}
