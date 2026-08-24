import XCTest

#if canImport(UIKit)
import JLI18n
import JLI18nUIKit
import JLI18nTesting

final class JLI18nUIKitTests: XCTestCase {
    @MainActor
    func testUIKitBinderCanBeConstructed() {
        let configuration = LocalizationConfiguration(
            defaultLocale: "en",
            supportedLocales: ["en"],
            fallbackLocale: "en",
            diagnostics: .init(mode: .reportOnly)
        )
        let manager = LocalizationManager(configuration: configuration, providers: [])
        let binder = UIKitLocalizationBinder(manager: manager)
        let label = UILabel()
        binder.bind(label: label, key: "home.title")
        XCTAssertNotNil(label)
    }

    @MainActor
    func testUIKitBinderRefreshesBoundControlsAfterLocaleChange() async {
        let configuration = LocalizationConfiguration(
            defaultLocale: "en",
            supportedLocales: ["en", "ja"],
            fallbackLocale: "en",
            persistence: InMemoryLocalePersistence(),
            diagnostics: .init(mode: .reportOnly)
        )
        let manager = LocalizationManager(
            configuration: configuration,
            providers: [InMemoryLocalizationProvider(values: [
                "en": ["home.title": "Home"],
                "ja": ["home.title": "ホーム"]
            ])]
        )
        let binder = UIKitLocalizationBinder(manager: manager)
        let label = UILabel()
        binder.bind(label: label, key: "home.title")
        await waitForText(label.text, equals: "Home")

        await manager.setLocale("ja")
        binder.refresh()
        await waitForText(label.text, equals: "ホーム")
    }

    @MainActor
    private func waitForText(_ value: @autoclosure @escaping () -> String?, equals expected: String) async {
        for _ in 0 ..< 50 {
            if value() == expected { return }
            await Task.yield()
        }
        XCTAssertEqual(value(), expected)
    }
}

private struct InMemoryLocalePersistence: LocalePersistence {
    func load() -> LocaleIdentifier? { nil }
    func save(_: LocaleIdentifier) {}
}
#endif
