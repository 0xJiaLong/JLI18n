import Foundation

public protocol LocalizationProvider: Sendable {
    func localizedString(for key: LocalizationKey, locale: LocaleIdentifier) -> String?
}

public struct BundleLocalizationProvider: LocalizationProvider {
    public let bundle: Bundle
    public let tableName: String?

    public init(bundle: Bundle, tableName: String? = "Localizable") {
        self.bundle = bundle
        self.tableName = tableName
    }

    public func localizedString(for key: LocalizationKey, locale: LocaleIdentifier) -> String? {
        let localizedBundle = bundleForLocale(locale) ?? bundle
        let value = localizedBundle.localizedString(forKey: key.rawValue, value: nil, table: tableName)
        return value == key.rawValue ? nil : value
    }

    private func bundleForLocale(_ locale: LocaleIdentifier) -> Bundle? {
        let candidates = [
            locale.rawValue,
            locale.rawValue.replacingOccurrences(of: "-", with: "_"),
            locale.rawValue.lowercased(),
            locale.languageCode
        ].compactMap { $0 }

        for candidate in candidates {
            guard let path = bundle.path(forResource: candidate, ofType: "lproj"),
                  let localized = Bundle(path: path) else { continue }
            return localized
        }
        return nil
    }
}

public struct CompositeLocalizationProvider: LocalizationProvider {
    public let providers: [any LocalizationProvider]

    public init(providers: [any LocalizationProvider]) {
        self.providers = providers
    }

    public func localizedString(for key: LocalizationKey, locale: LocaleIdentifier) -> String? {
        for provider in providers {
            if let value = provider.localizedString(for: key, locale: locale) {
                return value
            }
        }
        return nil
    }
}
