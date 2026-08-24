import XCTest

#if canImport(AppKit)
import AppKit
import JLI18n
import JLI18nAppKit

final class JLI18nAppKitTests: XCTestCase {
    func testAppKitBinderCanBeConstructed() async {
        let configuration = LocalizationConfiguration(defaultLocale: "en", supportedLocales: ["en"], fallbackLocale: "en")
        let manager = LocalizationManager(configuration: configuration, providers: [])
        let binder = await MainActor.run { AppKitLocalizationBinder(manager: manager) }
        XCTAssertNotNil(binder)
    }
}
#endif
