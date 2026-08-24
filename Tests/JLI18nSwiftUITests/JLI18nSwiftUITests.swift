import XCTest
import JLI18n
import JLI18nSwiftUI
import JLI18nTesting

final class JLI18nSwiftUITests: XCTestCase {
    @MainActor
    func testLocalizedTextCanBeCreated() {
        let view = LocalizedText(key: "home.title")
        _ = view
    }

    @MainActor
    func testEnvironmentResolvesAndPublishesLocaleChanges() async {
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
        let environment = JLI18nEnvironment(manager: manager, initialLocale: "en")

        let initialValue = await environment.resolve("home.title")
        XCTAssertEqual(initialValue, "Home")
        await manager.setLocale("ja")
        for _ in 0 ..< 20 where environment.locale != "ja" {
            await Task.yield()
        }

        XCTAssertEqual(environment.locale, "ja")
        let updatedValue = await environment.resolve("home.title")
        XCTAssertEqual(updatedValue, "ホーム")

        environment.setLocale("en")
        environment.setLocale("ja")
        for _ in 0 ..< 20 where environment.locale != "ja" {
            await Task.yield()
        }
        XCTAssertEqual(environment.locale, "ja")
    }
}

private struct InMemoryLocalePersistence: LocalePersistence {
    func load() -> LocaleIdentifier? { nil }
    func save(_: LocaleIdentifier) {}
}
