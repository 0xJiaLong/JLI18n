import XCTest
import JLI18n
import JLI18nTesting

final class LocalizationManagerTests: XCTestCase {
    private let key: LocalizationKey = "greeting"

    private func makeManager(
        values: [LocaleIdentifier: [LocalizationKey: String]],
        supported: [LocaleIdentifier] = ["en", "zh-Hans", "ja"],
        collector: DiagnosticCollector = DiagnosticCollector(),
        persistence: any LocalePersistence = UserDefaultsLocalePersistence(defaults: UserDefaults(suiteName: "JLI18nTests")!, key: UUID().uuidString)
    ) -> (LocalizationManager, DiagnosticCollector) {
        let configuration = LocalizationConfiguration(
            defaultLocale: "en",
            supportedLocales: supported,
            fallbackLocale: "en",
            persistence: persistence,
            diagnostics: .init(mode: .reportOnly, fallback: .missingMarker)
        )
        let manager = LocalizationManager(
            configuration: configuration,
            providers: [InMemoryLocalizationProvider(values: values)],
            diagnosticSink: collector
        )
        return (manager, collector)
    }

    func testLocaleFallbackAndNormalization() async {
        let (manager, _) = makeManager(values: ["zh-Hans": [key: "你好"]])
        await manager.setLocale("zh-Hans-CN")
        let currentLocale = await manager.currentLocale
        let value = await manager.string(for: key)
        XCTAssertEqual(currentLocale, LocaleIdentifier("zh-Hans"))
        XCTAssertEqual(value, "你好")
    }

    func testPersistenceRestoresLocale() async {
        let defaults = UserDefaults(suiteName: "JLI18nPersistenceTests")!
        let persistence = UserDefaultsLocalePersistence(defaults: defaults, key: "locale")
        let (first, _) = makeManager(values: ["en": [key: "Hello"], "ja": [key: "こんにちは"]], persistence: persistence)
        await first.setLocale("ja")

        let configuration = LocalizationConfiguration(
            defaultLocale: "en",
            supportedLocales: ["en", "ja"],
            fallbackLocale: "en",
            persistence: persistence,
            diagnostics: .init(mode: .reportOnly)
        )
        let second = LocalizationManager(configuration: configuration, providers: [InMemoryLocalizationProvider(values: ["ja": [key: "こんにちは"]])])
        let currentLocale = await second.currentLocale
        XCTAssertEqual(currentLocale, "ja")
    }

    func testArgumentsAndEscapedPercent() async {
        let (manager, _) = makeManager(values: ["en": [
            key: "Welcome, %@",
            "count": "%ld files",
            "progress": "Progress %.1f%%",
            "reordered": "%2$@ then %1$@"
        ]])
        let greeting = await manager.string(for: key, arguments: "Jack")
        let count = await manager.string(for: "count", arguments: Int64(3))
        let progress = await manager.string(for: "progress", arguments: 12.5)
        let reordered = await manager.string(for: "reordered", arguments: "first", "second")
        XCTAssertEqual(greeting, "Welcome, Jack")
        XCTAssertEqual(count, "3 files")
        XCTAssertEqual(progress, "Progress 12.5%")
        XCTAssertEqual(reordered, "second then first")
    }

    func testMissingAndInvalidArgumentsProduceFallbackAndDiagnostics() async {
        let (manager, collector) = makeManager(values: ["en": [key: "Welcome, %@"]])
        let unknown = await manager.string(for: "unknown")
        let missingArgument = await manager.string(for: key)
        let typeMismatch = await manager.string(for: key, arguments: 1)
        XCTAssertEqual(unknown, "[missing: unknown]")
        XCTAssertEqual(missingArgument, "[missing: greeting]")
        XCTAssertEqual(typeMismatch, "[missing: greeting]")
        XCTAssertEqual(collector.diagnostics.map(\.kind), [.missingKey, .missingArgument, .argumentTypeMismatch])
    }

    func testBundlePluralResourceIsReadable() async {
        let configuration = LocalizationConfiguration(
            defaultLocale: "en",
            supportedLocales: ["en"],
            fallbackLocale: "en",
            persistence: UserDefaultsLocalePersistence(defaults: UserDefaults(suiteName: "JLI18nPluralTests")!, key: "locale"),
            diagnostics: .init(mode: .reportOnly)
        )
        let manager = LocalizationManager(
            configuration: configuration,
            providers: [BundleLocalizationProvider(bundle: JLI18nResources.bundle)]
        )
        let value = await manager.string(for: "cart.item_count", arguments: Int64(2))
        XCTAssertFalse(value.hasPrefix("[missing:"))
    }
}
