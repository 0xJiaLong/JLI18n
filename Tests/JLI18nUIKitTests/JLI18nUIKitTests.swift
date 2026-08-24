import XCTest

#if canImport(UIKit)
import JLI18nUIKit

final class JLI18nUIKitTests: XCTestCase {
    @MainActor
    func testUIKitBinderCanBeConstructed() {
        let configuration = LocalizationConfiguration(defaultLocale: "en", supportedLocales: ["en"], fallbackLocale: "en")
        let manager = LocalizationManager(configuration: configuration, providers: [])
        let binder = UIKitLocalizationBinder(manager: manager)
        let label = UILabel()
        binder.bind(label: label, key: "home.title")
        XCTAssertNotNil(label)
    }
}
#endif
