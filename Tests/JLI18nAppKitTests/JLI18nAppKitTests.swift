import XCTest

#if canImport(AppKit)
import AppKit
import JLI18n
import JLI18nAppKit
import JLI18nTesting

final class JLI18nAppKitTests: XCTestCase {
    func testAppKitBinderCanBeConstructed() async {
        let configuration = LocalizationConfiguration(defaultLocale: "en", supportedLocales: ["en"], fallbackLocale: "en")
        let manager = LocalizationManager(configuration: configuration, providers: [])
        let binder = await MainActor.run { AppKitLocalizationBinder(manager: manager) }
        XCTAssertNotNil(binder)
    }

    @MainActor
    func testAppKitBinderRefreshesBoundControlsAfterLocaleChange() async {
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
        let binder = AppKitLocalizationBinder(manager: manager)
        let label = NSTextField(labelWithString: "")
        binder.bind(textField: label, key: "home.title")
        await waitForText(label.stringValue, equals: "Home")

        await manager.setLocale("ja")
        binder.refresh()
        await waitForText(label.stringValue, equals: "ホーム")
    }

    @MainActor
    private func waitForText(_ value: @autoclosure @escaping () -> String, equals expected: String) async {
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
