import XCTest
import Foundation
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

    func testLocaleIdentifierCanonicalizesSeparatorsScriptRegionAndWhitespace() {
        XCTAssertEqual(LocaleIdentifier("  ZH_hans_cn  ").rawValue, "zh-Hans-CN")
        XCTAssertEqual(LocaleIdentifier("en-us").rawValue, "en-US")
        XCTAssertEqual(LocaleIdentifier("---").rawValue, "")
    }

    func testLocaleNormalizationPrefersMatchingScriptBeforeLanguage() async {
        let (manager, _) = makeManager(
            values: [
                "zh-Hans": [key: "简体"],
                "zh-Hant": [key: "繁體"]
            ],
            supported: ["en", "zh-Hant", "zh-Hans"]
        )

        await manager.setLocale("zh-Hans-CN")

        let currentLocale = await manager.currentLocale
        let value = await manager.string(for: key)
        XCTAssertEqual(currentLocale, "zh-Hans")
        XCTAssertEqual(value, "简体")
    }

    func testFallbackChainUsesScriptThenLanguageThenConfiguredFallback() async {
        let (manager, _) = makeManager(
            values: ["zh-Hans": [key: "脚本文案"], "en": [key: "English"]],
            supported: ["en", "zh-Hans-CN"]
        )

        await manager.setLocale("zh-Hans-CN")
        let scriptValue = await manager.string(for: key)
        XCTAssertEqual(scriptValue, "脚本文案")

        let (languageManager, _) = makeManager(
            values: ["zh": [key: "语言文案"], "en": [key: "English"]],
            supported: ["en", "zh"]
        )
        await languageManager.setLocale("zh-Hant-TW")
        let languageLocale = await languageManager.currentLocale
        let languageValue = await languageManager.string(for: key)
        XCTAssertEqual(languageLocale, "zh")
        XCTAssertEqual(languageValue, "语言文案")

        let (fallbackManager, _) = makeManager(
            values: ["en": [key: "English"]],
            supported: ["en", "fr-FR"]
        )
        await fallbackManager.setLocale("fr-FR")
        let fallbackValue = await fallbackManager.string(for: key)
        XCTAssertEqual(fallbackValue, "English")
    }

    func testUnsupportedLocaleReportsSafeDiagnosticWithoutArgumentValues() async {
        let collector = DiagnosticCollector()
        let (manager, _) = makeManager(
            values: ["en": [key: "Welcome, %@"]],
            supported: ["en"],
            collector: collector
        )

        await manager.setLocale("de-DE")
        let value = await manager.string(for: key, arguments: "sensitive-user-input")
        let diagnostics = collector.diagnostics

        XCTAssertEqual(value, "Welcome, sensitive-user-input")
        XCTAssertEqual(diagnostics.count, 1)
        XCTAssertEqual(diagnostics.first?.kind, .unsupportedLocale)
        XCTAssertFalse(diagnostics[0].message.contains("sensitive-user-input"))
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

    func testRepeatedLocaleChangePersistsAndPublishesOnlyOnce() async {
        let persistence = CountingLocalePersistence()
        let (manager, _) = makeManager(
            values: ["en": [key: "Hello"], "ja": [key: "こんにちは"]],
            supported: ["en", "ja"],
            persistence: persistence
        )
        let stream = await manager.localeChanges()
        let valuesTask = Task { () -> [LocaleIdentifier] in
            var values: [LocaleIdentifier] = []
            for await value in stream {
                values.append(value)
                if values.count == 2 { return values }
            }
            return values
        }

        await manager.setLocale("ja")
        await manager.setLocale("ja")

        let publishedValues = await valuesTask.value
        XCTAssertEqual(publishedValues, ["en", "ja"])
        XCTAssertEqual(persistence.savedLocales, ["ja"])
    }

    func testConcurrentLocaleSwitchesRemainOnSupportedLocale() async {
        let (manager, _) = makeManager(
            values: ["en": [key: "English"], "ja": [key: "日本語"], "zh-Hans": [key: "中文"]]
        )

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await manager.setLocale("ja") }
            group.addTask { await manager.setLocale("zh-Hans") }
            group.addTask { await manager.setLocale("en") }
            await group.waitForAll()
        }

        let currentLocale = await manager.currentLocale
        XCTAssertTrue(["en", "ja", "zh-Hans"].contains(currentLocale))
    }

    func testLocaleChangesConsumerCanBeCancelled() async {
        let (manager, _) = makeManager(values: ["en": [key: "English"]])
        let stream = await manager.localeChanges()
        let consumer = Task { () -> [LocaleIdentifier] in
            var values: [LocaleIdentifier] = []
            for await value in stream {
                values.append(value)
            }
            return values
        }

        await Task.yield()
        consumer.cancel()
        let values = await consumer.value

        XCTAssertEqual(values, ["en"])
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

    func testEscapedPercentRequiresNoArgument() async {
        let (manager, _) = makeManager(values: ["en": ["percent": "100%% complete"]])
        let value = await manager.string(for: "percent")
        XCTAssertEqual(value, "100% complete")
    }

    func testLongIntegerAndFloatingPointSpecifiers() async {
        let (manager, _) = makeManager(values: ["en": [
            "long": "%lld",
            "float": "%.2f",
            "string": "%@"
        ]])

        let longValue = await manager.string(for: "long", arguments: Int64(42))
        let floatValue = await manager.string(for: "float", arguments: Float(1.25))
        let stringValue = await manager.string(for: "string", arguments: NSString(string: "value"))
        XCTAssertEqual(longValue, "42")
        XCTAssertEqual(floatValue, "1.25")
        XCTAssertEqual(stringValue, "value")
    }

    func testInvalidFormatsNeverCrashAndProduceFallback() async {
        let collector = DiagnosticCollector()
        let (manager, _) = makeManager(
            values: ["en": [
                "unsupported": "Bad %q",
                "unsafeString": "%s",
                "trailing": "Bad %",
                "star": "%*s",
                "zeroPosition": "%0$@",
                "mixedPositions": "%2$@ %@"
            ]],
            collector: collector
        )

        let unsupported = await manager.string(for: "unsupported", arguments: "x")
        let unsafeString = await manager.string(for: "unsafeString", arguments: "x")
        let trailing = await manager.string(for: "trailing", arguments: "x")
        let star = await manager.string(for: "star", arguments: 4, "x")
        let zeroPosition = await manager.string(for: "zeroPosition", arguments: "x")
        let mixedPositions = await manager.string(for: "mixedPositions", arguments: "first", "second")
        let values = [unsupported, unsafeString, trailing, star, zeroPosition, mixedPositions]

        XCTAssertEqual(values, [
            "[missing: unsupported]",
            "[missing: unsafeString]",
            "[missing: trailing]",
            "[missing: star]",
            "[missing: zeroPosition]",
            "[missing: mixedPositions]"
        ])
        XCTAssertEqual(collector.diagnostics.map(\.kind), Array(repeating: .invalidFormat, count: 6))
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

    func testExtraArgumentsProduceSafeFallbackAndDiagnostic() async {
        let collector = DiagnosticCollector()
        let (manager, _) = makeManager(
            values: ["en": [key: "Welcome, %@"]],
            collector: collector
        )
        let value = await manager.string(for: key, arguments: "Jack", "unexpected")

        XCTAssertEqual(value, "[missing: greeting]")
        XCTAssertEqual(collector.diagnostics.map(\.kind), [.missingArgument])
    }

    func testCompositeProviderUsesFirstValueAndManagerReportsConflicts() async {
        let first = InMemoryLocalizationProvider(values: ["en": [key: "first"]])
        let second = InMemoryLocalizationProvider(values: ["en": [key: "second"]])
        let composite = CompositeLocalizationProvider(providers: [first, second])
        XCTAssertEqual(composite.localizedString(for: key, locale: "en"), "first")

        let collector = DiagnosticCollector()
        let configuration = LocalizationConfiguration(
            defaultLocale: "en",
            supportedLocales: ["en"],
            fallbackLocale: "en",
            persistence: CountingLocalePersistence(),
            diagnostics: .init(mode: .reportOnly)
        )
        let manager = LocalizationManager(
            configuration: configuration,
            providers: [first, second],
            diagnosticSink: collector
        )

        let firstValue = await manager.string(for: key)
        XCTAssertEqual(firstValue, "first")
        XCTAssertEqual(collector.diagnostics.map(\.kind), [.resourceConflict])
    }

    func testPluralRulesSelectExactOneAndOtherForRequestedLocale() async {
        let configuration = LocalizationConfiguration(
            defaultLocale: "en",
            supportedLocales: ["en", "zh-Hans"],
            fallbackLocale: "en",
            persistence: CountingLocalePersistence(),
            diagnostics: .init(mode: .reportOnly, fallback: .missingMarker)
        )
        let manager = LocalizationManager(
            configuration: configuration,
            providers: [BundleLocalizationProvider(bundle: Bundle.module)]
        )

        await manager.setLocale("en")
        let englishOne = await manager.string(for: "cart.item_count", arguments: Int64(1))
        let englishZero = await manager.string(for: "cart.item_count", arguments: Int64(0))
        let englishOther = await manager.string(for: "cart.item_count", arguments: Int64(2))
        XCTAssertEqual(englishOne, "1 item")
        XCTAssertEqual(englishZero, "0 items")
        XCTAssertEqual(englishOther, "2 items")

        await manager.setLocale("zh-Hans")
        let chineseOne = await manager.string(for: "cart.item_count", arguments: Int64(1))
        let chineseOther = await manager.string(for: "cart.item_count", arguments: Int64(2))
        XCTAssertEqual(chineseOne, "1 件商品")
        XCTAssertEqual(chineseOther, "2 件商品")
    }

    func testPluralRequiresOneIntegerQuantity() async {
        let collector = DiagnosticCollector()
        let configuration = LocalizationConfiguration(
            defaultLocale: "en",
            supportedLocales: ["en"],
            fallbackLocale: "en",
            persistence: CountingLocalePersistence(),
            diagnostics: .init(mode: .reportOnly, fallback: .missingMarker)
        )
        let manager = LocalizationManager(
            configuration: configuration,
            providers: [BundleLocalizationProvider(bundle: Bundle.module)],
            diagnosticSink: collector
        )

        let noArgument = await manager.string(for: "cart.item_count")
        let wrongType = await manager.string(for: "cart.item_count", arguments: "2")
        let extraArgument = await manager.string(for: "cart.item_count", arguments: Int64(2), Int64(3))

        XCTAssertEqual(noArgument, "[missing: cart.item_count]")
        XCTAssertEqual(wrongType, "[missing: cart.item_count]")
        XCTAssertEqual(extraArgument, "[missing: cart.item_count]")
        XCTAssertEqual(collector.diagnostics.map(\.kind), [.missingArgument, .argumentTypeMismatch, .missingArgument])
    }

    func testBundleProviderReadsXCStringsAndStringsResources() async {
        let catalogProvider = BundleLocalizationProvider(bundle: JLI18nResources.bundle)
        XCTAssertEqual(catalogProvider.localizedString(for: "home.title", locale: "en"), "Home")
        XCTAssertEqual(catalogProvider.localizedString(for: "home.title", locale: "zh-Hans"), "首页")

        let stringsProvider = BundleLocalizationProvider(bundle: Bundle.module)
        XCTAssertEqual(stringsProvider.localizedString(for: "welcome.user", locale: "zh-Hans"), "欢迎，%@")

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
            providers: [BundleLocalizationProvider(bundle: Bundle.module)]
        )
        let value = await manager.string(for: "cart.item_count", arguments: Int64(2))
        XCTAssertFalse(value.hasPrefix("[missing:"))
    }
}

private final class CountingLocalePersistence: LocalePersistence, @unchecked Sendable {
    private let lock = NSLock()
    private var value: LocaleIdentifier?
    private var saves: [LocaleIdentifier] = []

    func load() -> LocaleIdentifier? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func save(_ locale: LocaleIdentifier) {
        lock.lock()
        value = locale
        saves.append(locale)
        lock.unlock()
    }

    var savedLocales: [LocaleIdentifier] {
        lock.lock()
        defer { lock.unlock() }
        return saves
    }
}
